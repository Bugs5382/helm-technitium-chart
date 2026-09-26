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

# Unit tests for technitium-version.sh. Run: bash .github/scripts/technitium-version_test.sh

set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
script="$here/technitium-version.sh"
pass=0
fail=0

check() {
  local name="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    pass=$((pass + 1)); echo "ok   $name"
  else
    fail=$((fail + 1)); echo "FAIL $name: want '$want', got '$got'"
  fi
}

stable() { if bash "$script" is-stable "$1" 2>/dev/null; then echo yes; else echo no; fi; }
cmp() { bash "$script" compare "$1" "$2" 2>/dev/null || echo error; }

# compare: newer, equal, older
check "newer patch" newer "$(cmp 15.5.1 15.5.0)"
check "newer minor" newer "$(cmp 15.5.0 15.2.0)"
check "newer major" newer "$(cmp 16.0.0 15.9.9)"
check "newer numeric not lexical" newer "$(cmp 15.10.0 15.9.0)"
check "equal" equal "$(cmp 15.2.0 15.2.0)"
check "equal with missing patch" equal "$(cmp 13.1 13.1.0)"
check "older patch" older "$(cmp 15.2.0 15.2.1)"
check "older major" older "$(cmp 14.3.0 15.0.0)"
check "compare rejects latest" error "$(cmp latest 15.2.0)"
check "compare rejects pre-release" error "$(cmp 15.6.0-beta 15.2.0)"

# is-stable
check "stable three-part" yes "$(stable 15.5.1)"
check "stable two-part" yes "$(stable 13.1)"
check "latest is not stable" no "$(stable latest)"
check "beta is not stable" no "$(stable 15.6.0-beta)"
check "rc is not stable" no "$(stable 15.6.0-rc1)"
check "v prefix is not stable" no "$(stable v15.5.1)"
check "empty is not stable" no "$(stable '')"

# latest-stable ignores latest and pre-release tags
got="$(printf '%s\n' latest 15.6.0-beta 15.5.1 15.10.0-rc1 15.5.0 13.1 15.4.0 | bash "$script" latest-stable 2>/dev/null)"
check "latest-stable picks highest stable" 15.5.1 "$got"
got="$(printf '%s\n' latest nightly | bash "$script" latest-stable 2>/dev/null || echo none)"
check "latest-stable with no stable tags" none "$got"

# bump-patch
check "bump-patch" 0.3.1 "$(bash "$script" bump-patch 0.3.0)"
check "bump-patch two-part" 13.1.1 "$(bash "$script" bump-patch 13.1)"

echo "passed: $pass, failed: $fail"
[ "$fail" -eq 0 ]
