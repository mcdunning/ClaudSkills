#!/usr/bin/env bash
# Minimal plain-bash test helpers.
FAILS=0
_TMPLIST=$(mktemp "${TMPDIR:-/tmp}/skilltest-list.XXXXXX")

_cleanup_tmps() {
  local d
  while IFS= read -r d; do [ -n "$d" ] && rm -rf "$d"; done < "$_TMPLIST"
  rm -f "$_TMPLIST"
}
trap _cleanup_tmps EXIT

_fail() { echo "FAIL: $1" >&2; FAILS=$((FAILS + 1)); }

assert_eq() {
  if [ "$1" == "$2" ]; then echo "ok: $3"; else _fail "$3 (expected '$1', got '$2')"; fi
}
assert_file() {
  if [ -e "$1" ]; then echo "ok: exists $1"; else _fail "missing file: $1"; fi
}
assert_no_file() {
  if [ ! -e "$1" ] && [ ! -L "$1" ]; then echo "ok: absent $1"; else _fail "unexpected file: $1"; fi
}
assert_contains() {
  if grep -qF -- "$2" "$1" 2>/dev/null; then echo "ok: $1 contains '$2'"; else _fail "$1 does not contain '$2'"; fi
}
# Prints a fresh temp dir; removed on exit (registered in a file so that
# d=$(new_tmp) in a subshell still gets cleaned up).
new_tmp() {
  local d
  d=$(mktemp -d "${TMPDIR:-/tmp}/skilltest.XXXXXX")
  printf '%s\n' "$d" >> "$_TMPLIST"
  printf '%s\n' "$d"
}
# make_repo <dir> [with_origin]: repo with main + develop, ends on develop.
# With origin, a bare repo at <dir>.origin.git is created and both branches pushed.
make_repo() {
  local dir="$1" origin="${2:-}"
  git init -q -b main "$dir"
  git -C "$dir" commit -q --allow-empty -m init
  git -C "$dir" checkout -q -b develop
  git -C "$dir" commit -q --allow-empty -m dev
  if [ -n "$origin" ]; then
    git init -q --bare -b main "$dir.origin.git"
    git -C "$dir" remote add origin "$dir.origin.git"
    git -C "$dir" push -q origin main develop
    git -C "$dir" fetch -q origin
  fi
}

finish() {
  if [ "$FAILS" -ne 0 ]; then echo "$FAILS assertion(s) failed" >&2; exit 1; fi
  echo "all assertions passed"
  exit 0
}
