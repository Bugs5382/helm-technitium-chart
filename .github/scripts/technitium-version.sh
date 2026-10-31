#!/usr/bin/env bash
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

# Tracks Technitium DNS Server releases for this chart (issue #37).
#
# Subcommands:
#   is-stable <tag>          exit 0 when <tag> is a stable release (X.Y or X.Y.Z)
#   compare <a> <b>          print "newer", "equal" or "older" (a relative to b)
#   latest-stable            read tags on stdin, print the highest stable one
#   run                      the full bot: detect, then file or update the issue
#
# `run` reads DRY_RUN (true/false), REPO (owner/name) and CHART_FILE, and uses
# `gh` for GitHub calls. With DRY_RUN=true it only logs what it would do and
# never writes to GitHub.

set -euo pipefail

DOCKER_REPO="${DOCKER_REPO:-technitium/dns-server}"
UPSTREAM_REPO="${UPSTREAM_REPO:-TechnitiumSoftware/DnsServer}"
CHART_FILE="${CHART_FILE:-technitium/Chart.yaml}"
TITLE_PREFIX="chore(deps): bump Technitium DNS Server to "
CHANGELOG_URL="https://github.com/${UPSTREAM_REPO}/blob/master/CHANGELOG.md"

log() { printf '[%s] %s\n' "$1" "$2" >&2; }
info() { log info "$*"; }
debug() { log debug "$*"; }
warn() { log warn "$*"; }
die() { log error "$*"; exit 1; }

# Stable = digits only, two or three parts. Rejects "latest", "15.5.1-beta",
# "15.5.1-rc1", "v15.5.1" and anything else Docker Hub might carry.
is_stable() {
  [[ "${1:-}" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]
}

# Compare two stable versions. A missing patch counts as 0.
compare() {
  local a="$1" b="$2"
  is_stable "$a" || die "compare: not a stable version: '$a'"
  is_stable "$b" || die "compare: not a stable version: '$b'"
  local -a av bv
  IFS=. read -r -a av <<<"$a"
  IFS=. read -r -a bv <<<"$b"
  local i x y
  for i in 0 1 2; do
    x="${av[$i]:-0}"; y="${bv[$i]:-0}"
    if ((10#$x > 10#$y)); then echo newer; return 0; fi
    if ((10#$x < 10#$y)); then echo older; return 0; fi
  done
  echo equal
}

latest_stable() {
  local best="" tag
  while IFS= read -r tag; do
    tag="${tag//[$'\r\t ']/}"
    [ -n "$tag" ] || continue
    if ! is_stable "$tag"; then
      debug "skipping non-stable tag '$tag'"
      continue
    fi
    if [ -z "$best" ] || [ "$(compare "$tag" "$best")" = newer ]; then
      best="$tag"
    fi
  done
  [ -n "$best" ] || return 1
  printf '%s\n' "$best"
}

chart_field() {
  sed -n "s/^$1:[[:space:]]*\"\{0,1\}\([^\"]*\)\"\{0,1\}[[:space:]]*$/\1/p" "$CHART_FILE" | head -n1
}

docker_tags() {
  local url="https://hub.docker.com/v2/repositories/${DOCKER_REPO}/tags?page_size=100&ordering=last_updated"
  debug "GET $url"
  curl -fsS --max-time 30 "$url" | jq -r '.results[].name'
}

# Latest non-draft, non-prerelease GitHub release tag without the leading v.
upstream_release() {
  gh release view -R "$UPSTREAM_REPO" --json tagName,isPrerelease \
    --jq 'select(.isPrerelease == false) | .tagName' 2>/dev/null | sed 's/^v//'
}

issue_body() {
  local current="$1" target="$2"
  cat <<EOF
### Problem Statement

Technitium DNS Server ${target} is available (\`${DOCKER_REPO}:${target}\`). The chart \`appVersion\` is ${current}.

### Proposed Solution

Bump \`appVersion\` to ${target} and patch-bump the chart \`version\`. Check the upstream notes for anything the chart or its cluster-join Job depends on.

- Release notes: https://github.com/${UPSTREAM_REPO}/releases/tag/v${target}
- Changelog: ${CHANGELOG_URL}

### Additional Context

**Automation.** This issue was filed automatically by \`.github/workflows/job-technitium-bump.yaml\` (the Technitium Version Tracker) with the release GitHub App. It runs daily and found that the upstream Technitium DNS Server release ${target} is newer than the chart's \`appVersion\` (${current}). The tracker opens no pull request: the bump is done by hand, and this issue closes when that bump merges. On later runs it updates this issue instead of filing a new one. To stop it, disable the workflow.
EOF
}

run() {
  local dry="${DRY_RUN:-false}"
  local repo="${REPO:-${GITHUB_REPOSITORY:-}}"
  [ -n "$repo" ] || die "REPO or GITHUB_REPOSITORY must be set"
  [ -f "$CHART_FILE" ] || die "chart file not found: $CHART_FILE"
  info "start: repo=$repo chart=$CHART_FILE dry_run=$dry"

  local current chart_version
  current="$(chart_field appVersion)"
  chart_version="$(chart_field version)"
  is_stable "$current" || die "appVersion '$current' in $CHART_FILE is not a stable version"
  info "chart: appVersion=$current version=$chart_version"

  local tags latest
  tags="$(docker_tags)" || die "could not list tags for $DOCKER_REPO on Docker Hub"
  debug "docker hub returned $(printf '%s\n' "$tags" | grep -c . || true) tags"
  latest="$(printf '%s\n' "$tags" | latest_stable)" || die "no stable tag found for $DOCKER_REPO"
  info "docker hub: latest stable tag is $latest"

  local gh_release
  gh_release="$(upstream_release || true)"
  if [ -z "$gh_release" ]; then
    warn "no GitHub release found on $UPSTREAM_REPO; using the Docker Hub tag alone"
  elif [ "$gh_release" != "$latest" ]; then
    warn "GitHub release is $gh_release but Docker Hub has $latest; Docker Hub is the source of truth"
  else
    info "github: release v$gh_release matches Docker Hub"
  fi

  local cmp
  cmp="$(compare "$latest" "$current")"
  info "compare: upstream $latest vs appVersion $current: $cmp"
  if [ "$cmp" != newer ]; then
    info "nothing to do: chart is on $current"
    return 0
  fi

  local title="${TITLE_PREFIX}${latest}"

  # An open issue from an earlier run, for this or an older version.
  local open_issue
  open_issue="$(gh issue list -R "$repo" --state open --limit 50 --json number,title \
    --jq "map(select(.title | startswith(\"${TITLE_PREFIX}\"))) | first // empty | \"\(.number) \(.title)\"")"

  if [ -n "$open_issue" ]; then
    local issue="${open_issue%% *}" issue_version="${open_issue##*"${TITLE_PREFIX}"}"
    info "found open issue #$issue for $issue_version"
    if [ "$issue_version" = "$latest" ]; then
      info "nothing to do: issue #$issue already targets $latest"
    elif [ "$dry" = true ]; then
      info "dry run: would update issue #$issue to '$title'"
    else
      gh issue edit "$issue" -R "$repo" --title "$title" --body "$(issue_body "$current" "$latest")"
      info "updated issue #$issue to $latest"
    fi
    return 0
  fi

  if [ "$dry" = true ]; then
    info "dry run: would file issue '$title' (dependencies, assigned to the repo owner)"
    return 0
  fi

  local url
  url="$(gh issue create -R "$repo" --title "$title" --label dependencies \
    --assignee "${repo%%/*}" --body "$(issue_body "$current" "$latest")")"
  info "filed issue ${url##*/} ($url)"
}

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    is-stable) is_stable "${1:-}" ;;
    compare) compare "$1" "$2" ;;
    latest-stable) latest_stable ;;
    run) run ;;
    *) die "usage: $0 {is-stable|compare|latest-stable|run}" ;;
  esac
}

# Allow the test script to source the functions without running main.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
