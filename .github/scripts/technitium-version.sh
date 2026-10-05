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
#   bump-patch <X.Y.Z>       print X.Y.(Z+1)
#   issue-token              print the token used for issue calls: ISSUE_GH_TOKEN
#                            (the maintainer's token) when set, else GH_TOKEN
#   run                      the full bot: detect, then file the issue and PR
#
# `run` reads DRY_RUN (true/false), REPO (owner/name), CHART_FILE, BASE_BRANCH,
# and uses `gh` for GitHub calls. With DRY_RUN=true it only logs what it would
# do and never writes to GitHub or git.

set -euo pipefail

DOCKER_REPO="${DOCKER_REPO:-technitium/dns-server}"
UPSTREAM_REPO="${UPSTREAM_REPO:-TechnitiumSoftware/DnsServer}"
CHART_FILE="${CHART_FILE:-technitium/Chart.yaml}"
BASE_BRANCH="${BASE_BRANCH:-main}"
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

bump_patch() {
  local v="$1" m n p
  is_stable "$v" || die "bump-patch: not a stable version: '$v'"
  IFS=. read -r m n p <<<"$v"
  printf '%s.%s.%s\n' "$m" "$n" "$((10#${p:-0} + 1))"
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

# Edit Chart.yaml in place: appVersion -> $1, version -> $2.
write_chart() {
  sed -i.bak \
    -e "s/^appVersion:.*/appVersion: \"$1\"/" \
    -e "s/^version:.*/version: $2/" "$CHART_FILE"
  rm -f "${CHART_FILE}.bak"
}

pr_body() {
  local issue="$1" current="$2" target="$3" chart_from="$4" chart_to="$5"
  cat <<EOF
## What and why

Technitium DNS Server ${target} is out on Docker Hub (\`${DOCKER_REPO}:${target}\`). This bumps the chart \`appVersion\` from ${current} to ${target} and the chart \`version\` from ${chart_from} to ${chart_to} (patch).

Release notes: https://github.com/${UPSTREAM_REPO}/releases/tag/v${target}
Changelog: ${CHANGELOG_URL}

Closes #${issue}

## Verification

- [ ] Read the upstream notes from ${current} to ${target} for breaking changes, new or renamed env vars, new ports, and cluster API changes the join Job relies on
- [ ] Bump the chart \`version\` to a minor instead if the notes need chart changes
- [ ] Test install and upgrade from ${current} in a throwaway namespace on the Pi
- [ ] CI green
- [ ] Publish the chart release by hand after merge

## How this was verified

Opened by the Technitium version tracker (\`.github/workflows/job-technitium-bump.yaml\`). It compared the latest stable Docker Hub tag with \`appVersion\` in \`${CHART_FILE}\`. Nothing here has been installed yet; see the checklist above.

---

**Before merging:** add a closing comment summarizing what was actually done in this PR
(not just the checked boxes).
EOF
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

**Automation.** This issue was filed automatically by \`.github/workflows/job-technitium-bump.yaml\` (the Technitium Version Tracker) under the maintainer's account. It runs daily and found that the upstream Technitium DNS Server release ${target} is newer than the chart's \`appVersion\` (${current}). The tracker opens a pull request that bumps \`appVersion\` and the chart \`version\`, and closes this issue when it merges. On later runs it updates this issue and that pull request instead of filing new ones. To stop it, close the pull request and this issue, or disable the workflow.
EOF
}

git_identity() {
  local actor="${GITHUB_ACTOR:?GITHUB_ACTOR is required}"
  local actor_id="${GITHUB_ACTOR_ID:?GITHUB_ACTOR_ID is required}"
  git config user.name "$actor"
  git config user.email "${actor_id}+${actor}@users.noreply.github.com"
  debug "git identity set to ${actor} (${actor_id})"
}

run() {
  local dry="${DRY_RUN:-false}"
  local repo="${REPO:-${GITHUB_REPOSITORY:-}}"
  [ -n "$repo" ] || die "REPO or GITHUB_REPOSITORY must be set"
  [ -f "$CHART_FILE" ] || die "chart file not found: $CHART_FILE"
  info "start: repo=$repo chart=$CHART_FILE base=$BASE_BRANCH dry_run=$dry"

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
  local base_chart_version target_chart_version
  base_chart_version="$chart_version"
  target_chart_version="$(bump_patch "$base_chart_version")"

  # An open bump PR from an earlier run, for this or an older version.
  local open_pr
  open_pr="$(gh pr list -R "$repo" --state open --limit 50 \
    --json number,title,headRefName \
    --jq "map(select(.title | startswith(\"${TITLE_PREFIX}\"))) | first // empty | \"\(.number) \(.headRefName) \(.title)\"")"

  if [ -n "$open_pr" ]; then
    local pr_num pr_branch _rest pr_version
    read -r pr_num pr_branch _rest <<<"$open_pr"
    pr_version="${open_pr##*"${TITLE_PREFIX}"}"
    info "found open bump PR #$pr_num ($pr_branch) for $pr_version"
    if [ "$pr_version" = "$latest" ]; then
      info "nothing to do: PR #$pr_num already targets $latest"
      return 0
    fi
    local pr_issue="${pr_branch#chore/}"; pr_issue="${pr_issue%%-*}"
    if [ "$dry" = true ]; then
      info "dry run: would update PR #$pr_num to $latest (appVersion $current -> $latest, version $base_chart_version -> $target_chart_version), retitle it and issue #$pr_issue to '$title'"
      return 0
    fi
    git_identity
    git fetch origin "$pr_branch"
    git checkout -B "$pr_branch" "origin/$pr_branch"
    write_chart "$latest" "$target_chart_version"
    git add "$CHART_FILE"
    git commit -m "$title"
    git push origin "$pr_branch"
    gh pr edit "$pr_num" -R "$repo" --title "$title" \
      --body "$(pr_body "$pr_issue" "$current" "$latest" "$base_chart_version" "$target_chart_version")"
    if [[ "$pr_issue" =~ ^[0-9]+$ ]]; then
      GH_TOKEN="$(issue_token)" gh issue edit "$pr_issue" -R "$repo" --title "$title" --body "$(issue_body "$current" "$latest")"
    fi
    info "updated PR #$pr_num to $latest"
    return 0
  fi

  # Reuse an open issue with the exact title, if a person or an earlier run filed one.
  local issue
  issue="$(GH_TOKEN="$(issue_token)" gh issue list -R "$repo" --state open --limit 50 --json number,title \
    --jq "map(select(.title == \"${title}\")) | first // empty | .number")"
  if [ -n "$issue" ]; then
    info "found open issue #$issue for $latest"
  elif [ "$dry" = true ]; then
    info "dry run: would file issue '$title' (dependencies, assigned to the repo owner)"
    issue="<new>"
  else
    local owner="${repo%%/*}" url
    url="$(GH_TOKEN="$(issue_token)" gh issue create -R "$repo" --title "$title" --label dependencies \
      --assignee "$owner" --body "$(issue_body "$current" "$latest")")"
    issue="${url##*/}"
    info "filed issue #$issue ($url)"
  fi

  local branch="chore/${issue}-technitium-${latest}"
  if [ "$dry" = true ]; then
    info "dry run: would create branch $branch from $BASE_BRANCH, set appVersion $current -> $latest and version $base_chart_version -> $target_chart_version, and open PR '$title' closing #$issue"
    return 0
  fi

  git_identity
  git checkout -B "$branch" "origin/$BASE_BRANCH"
  write_chart "$latest" "$target_chart_version"
  git add "$CHART_FILE"
  git commit -m "$title"
  git push origin "$branch"
  local pr_url
  pr_url="$(gh pr create -R "$repo" --base "$BASE_BRANCH" --head "$branch" --title "$title" \
    --body "$(pr_body "$issue" "$current" "$latest" "$base_chart_version" "$target_chart_version")")"
  info "opened $pr_url"
}

# Issues are filed as the maintainer, not the app, so they carry the owner's
# name like any hand-filed issue. The PR stays on the app token.
issue_token() {
  local t="${ISSUE_GH_TOKEN:-${GH_TOKEN:-}}"
  [ -n "$t" ] || die "no ISSUE_GH_TOKEN or GH_TOKEN for issue calls"
  printf '%s\n' "$t"
}

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    is-stable) is_stable "${1:-}" ;;
    compare) compare "$1" "$2" ;;
    latest-stable) latest_stable ;;
    bump-patch) bump_patch "$1" ;;
    issue-token) issue_token ;;
    run) run ;;
    *) die "usage: $0 {is-stable|compare|latest-stable|bump-patch|issue-token|run}" ;;
  esac
}

# Allow the test script to source the functions without running main.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
