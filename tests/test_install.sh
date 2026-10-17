#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

setup() {
  ROOT=$(new_tmp)
  mkdir -p "$ROOT/skills/a" "$ROOT/skills/b"
  echo a > "$ROOT/skills/a/SKILL.md"
  echo b > "$ROOT/skills/b/SKILL.md"
  cp "$REAL/install.sh" "$ROOT/install.sh"
  TARGET="$ROOT/target"
}

test_links_every_skill_dir() {
  setup
  bash "$ROOT/install.sh" "$TARGET" >/dev/null
  assert_eq "$ROOT/skills/a" "$(readlink "$TARGET/a")" "a links to repo skill"
  assert_eq "$ROOT/skills/b" "$(readlink "$TARGET/b")" "b links to repo skill"
}

test_rerun_is_idempotent() {
  setup
  bash "$ROOT/install.sh" "$TARGET" >/dev/null
  bash "$ROOT/install.sh" "$TARGET" >/dev/null
  assert_eq "0" "$?" "second run exits 0"
  assert_eq "$ROOT/skills/a" "$(readlink "$TARGET/a")" "a link unchanged"
  assert_eq "$ROOT/skills/b" "$(readlink "$TARGET/b")" "b link unchanged"
}

test_refuses_real_directory() {
  setup
  mkdir -p "$TARGET/a"
  echo keep > "$TARGET/a/mine.txt"
  bash "$ROOT/install.sh" "$TARGET" >/dev/null 2>&1
  local rc=$?
  assert_eq "1" "$((rc != 0))" "run exits non-zero"
  assert_file "$TARGET/a/mine.txt"
  assert_contains "$TARGET/a/mine.txt" "keep"
  assert_eq "$ROOT/skills/b" "$(readlink "$TARGET/b")" "b still linked"
}

test_links_every_skill_dir
test_rerun_is_idempotent
test_refuses_real_directory
finish
