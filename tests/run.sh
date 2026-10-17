#!/usr/bin/env bash
# Runs every tests/test_*.sh; exits non-zero if any fail.
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rc=0
for t in "$dir"/test_*.sh; do
  [ -e "$t" ] || continue
  echo "== $(basename "$t")"
  bash "$t" || rc=1
done
exit "$rc"
