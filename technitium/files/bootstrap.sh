#!/bin/sh
# MIT License
#
# Copyright (c) 2026 Shane & Contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# Zone bootstrap (issue #43). Runs in the `bootstrap` sidecar on every pod
# start: waits for the local Technitium API, then creates every zone listed in
# /bootstrap/zones and /bootstrap/reverse-zones that does not exist yet.
# Existing zones are never changed, so it is safe with or without
# persistence. Any API error exits non-zero so the container restarts and the
# failure shows up in `kubectl logs` and the pod's restart count.
#
# Inputs (env): API_BASE, ADMIN_USER, ADMIN_PASSWORD (from the chart's admin
# Secret, which Technitium also applies on every blank start), CATALOG
# (optional cluster catalog zone), WAIT_FOR_CLUSTER ("true" on a cluster
# primary).
set -eu

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$1] bootstrap: $2" >&2; }
die() { log error "$*"; exit 1; }

API_BASE="${API_BASE:-http://127.0.0.1:5380}"
ZONES_FILE=/bootstrap/zones
REVERSE_FILE=/bootstrap/reverse-zones

# api <path> [curl args...]: GET a Technitium API path with the session token.
# Prints the body; fails on transport errors. Technitium returns HTTP 200 for
# API errors, so callers check the `status` field.
api() {
  p="$1"; shift
  curl -sS --max-time 30 -H "Authorization: Bearer ${TOKEN}" "$@" "${API_BASE}${p}"
}
status_of() { sed -n 's/.*"status":"\([a-z]*\)".*/\1/p' | head -n1; }
error_of() { sed -n 's/.*"errorMessage":"\([^"]*\)".*/\1/p' | head -n1; }

# CIDR -> reverse zone names, one per line. Prefixes that are not a multiple
# of 8 expand to every zone at the next octet boundary (10.110.0.0/19 gives
# 0-31.110.10.in-addr.arpa). Names that already look like zone names pass
# through unchanged. IPv6 CIDRs must be listed as explicit ip6.arpa names.
reverse_names() {
  in="$1"
  case "$in" in
    *.arpa|*.arpa.) printf '%s\n' "${in%.}"; return 0 ;;
    *:*) die "IPv6 CIDR '$in' is not expanded; list its ip6.arpa zone name instead" ;;
    */*) : ;;
    *) die "reverse zone '$in' is neither a CIDR nor an .arpa name" ;;
  esac
  ip="${in%/*}"; prefix="${in#*/}"
  case "$prefix" in ''|*[!0-9]*) die "bad prefix in '$in'" ;; esac
  [ "$prefix" -ge 8 ] && [ "$prefix" -le 32 ] || die "prefix /$prefix in '$in' must be between 8 and 32"
  # Split the address on dots on purpose; o4 is read through the eval below.
  old_ifs="$IFS"
  IFS=.
  # shellcheck disable=SC2086
  set -- $ip
  IFS="$old_ifs"
  [ $# -eq 4 ] || die "bad IPv4 address in '$in'"
  o1=$1
  o2=$2
  o3=$3
  # shellcheck disable=SC2034
  o4=$4
  octets=$(( (prefix + 7) / 8 ))
  count=$(( 1 << (octets * 8 - prefix) ))
  eval "base=\$o$octets"
  base=$(( base & (256 - count) ))
  i=0
  while [ $i -lt $count ]; do
    v=$(( base + i ))
    case $octets in
      1) printf '%s.in-addr.arpa\n' "$v" ;;
      2) printf '%s.%s.in-addr.arpa\n' "$v" "$o1" ;;
      3) printf '%s.%s.%s.in-addr.arpa\n' "$v" "$o2" "$o1" ;;
      4) printf '%s.%s.%s.%s.in-addr.arpa\n' "$v" "$o3" "$o2" "$o1" ;;
    esac
    i=$(( i + 1 ))
  done
}

# ensure_zone <name> <type>: create the zone unless it already exists.
ensure_zone() {
  name="$1"; type="${2:-Primary}"
  body="$(api "/api/zones/list?filterName=${name}")" || die "zones/list failed for ${name}"
  [ "$(printf '%s' "$body" | status_of)" = "ok" ] || die "zones/list for ${name}: $(printf '%s' "$body" | error_of)"
  if printf '%s' "$body" | grep -q "\"name\":\"${name}\""; then
    log info "zone ${name} already exists; leaving it alone"
    EXISTING=$((EXISTING + 1))
    return 0
  fi
  q="zone=${name}&type=${type}"
  [ -n "${CATALOG:-}" ] && q="${q}&catalog=${CATALOG}"
  log debug "creating zone ${name} (type=${type}${CATALOG:+, catalog=${CATALOG}})"
  body="$(api "/api/zones/create?${q}")" || die "zones/create transport error for ${name}"
  if [ "$(printf '%s' "$body" | status_of)" != "ok" ]; then
    die "zones/create for ${name} failed: $(printf '%s' "$body" | error_of)"
  fi
  log info "zone ${name} created (type=${type})"
  CREATED=$((CREATED + 1))
}

log info "start: api=${API_BASE} user=${ADMIN_USER:-admin}"

# Wait for the API. Probing the unauthenticated status endpoint avoids
# creating a session per retry.
tries=0
until curl -fsS -o /dev/null --max-time 3 "${API_BASE}/api/status" 2>/dev/null; do
  tries=$((tries + 1))
  [ $tries -le 100 ] || die "Technitium API at ${API_BASE} not reachable after ${tries} attempts"
  log debug "waiting for Technitium API (attempt ${tries})"
  sleep 3
done
log info "Technitium API is up after ${tries} retries"

# login: open a session with the admin password and verify it. Called again
# whenever a later call reports the session as invalid (for example after a
# config restore replaced the auth config).
login() {
  # Retry transport errors briefly: the web service restarts after a config
  # restore, and the old session goes invalid at the same moment.
  lt=0
  until resp="$(curl -sS --max-time 10 -X POST "${API_BASE}/api/user/login" \
    --data-urlencode "user=${ADMIN_USER:-admin}" \
    --data-urlencode "pass=${ADMIN_PASSWORD}" \
    --data-urlencode "includeInfo=false")"; do
    lt=$((lt + 1))
    [ $lt -le 20 ] || die "login transport error after ${lt} attempts"
    log warn "login request failed (attempt ${lt}); retrying"
    sleep 3
  done
  TOKEN="$(printf '%s' "$resp" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p' | head -n1)"
  [ -n "$TOKEN" ] || die "login as ${ADMIN_USER:-admin} failed: $(printf '%s' "$resp" | error_of). The password comes from the chart admin Secret; if it was changed in the web UI, change it back or update the Secret."
  check="$(api /api/user/session/get)" || die "session check transport error"
  [ "$(printf '%s' "$check" | status_of)" = "ok" ] || die "API rejected the bootstrap credentials: $(printf '%s' "$check" | error_of)"
  log info "authenticated"
}
login

if [ "${WAIT_FOR_CLUSTER:-false}" = "true" ]; then
  # Cluster primary: zones join the cluster catalog so they sync to the
  # secondaries, and the catalog exists only after the join Job ran init.
  tries=0
  while :; do
    state="$(api /api/admin/cluster/state)" || state=""
    printf '%s' "$state" | grep -q '"clusterInitialized":true' && break
    if printf '%s' "$state" | grep -q '"status":"invalid-token"\|Invalid token or session expired'; then
      log warn "session no longer valid; logging in again"
      login
    fi
    tries=$((tries + 1))
    [ $tries -le 200 ] || die "cluster not initialized after ${tries} checks; is cluster.autoJoin off?"
    log debug "waiting for cluster init before creating catalog member zones (check ${tries})"
    sleep 3
  done
  log info "cluster initialized; zones will join catalog ${CATALOG}"
fi

CREATED=0; EXISTING=0
if [ -s "$ZONES_FILE" ]; then
  while read -r zname ztype; do
    [ -n "$zname" ] || continue
    ensure_zone "$zname" "${ztype:-Primary}"
  done < "$ZONES_FILE"
fi
if [ -s "$REVERSE_FILE" ]; then
  while read -r rz; do
    [ -n "$rz" ] || continue
    names="$(reverse_names "$rz")"
    log debug "reverse entry ${rz} -> $(printf '%s' "$names" | tr '\n' ' ')"
    for n in $names; do ensure_zone "$n" Primary; done
  done < "$REVERSE_FILE"
fi
log info "done: created=${CREATED} existing=${EXISTING}"
