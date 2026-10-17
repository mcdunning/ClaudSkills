#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$REAL/skills/new-project/scripts/scaffold.sh"

# Local identity so tests do not depend on global git config.
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com
export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

# Checksums of all non-.git files, with paths.
snapshot() { (cd "$1" && find . -path ./.git -prune -o -type f -print0 | sort -z | xargs -0 -r sha256sum); }

test_empty_dir_reports_empty_and_scaffolds() {
  local d out rc=0
  d=$(new_tmp)
  out=$(bash "$S" "$d") || rc=$?
  assert_eq "0" "$rc" "exit 0"
  assert_eq "empty" "$(printf '%s\n' "$out" | head -n1)" "first line is empty"
  assert_file "$d/docs/plans"
  assert_file "$d/docs/specs"
  assert_file "$d/docs/PROJECT_STATUS.md"
  assert_file "$d/CLAUDE.md"
  local br
  br=$(git -C "$d" branch --list --format='%(refname:short)' | sort | tr '\n' ' ')
  assert_eq "develop main " "$br" "branches main and develop"
  assert_eq "develop" "$(git -C "$d" branch --show-current)" "on develop"
}

test_readme_license_gitignore_count_as_empty() {
  local d out
  d=$(new_tmp)
  echo r > "$d/README.md"; echo l > "$d/LICENSE"; echo x > "$d/.gitignore"
  out=$(bash "$S" "$d")
  assert_eq "empty" "$(printf '%s\n' "$out" | head -n1)" "readme/license/gitignore are empty"
  assert_eq "r" "$(cat "$d/README.md")" "README untouched"
}

test_source_file_makes_non_empty() {
  local d out
  d=$(new_tmp)
  printf 'print(1)\n' > "$d/main.py"
  local before; before=$(sha256sum "$d/main.py")
  out=$(bash "$S" "$d")
  assert_eq "non-empty" "$(printf '%s\n' "$out" | head -n1)" "source file => non-empty"
  assert_eq "$before" "$(sha256sum "$d/main.py")" "source file byte-identical"
}

test_second_run_changes_nothing() {
  local d a b
  d=$(new_tmp)
  bash "$S" "$d" >/dev/null
  a=$(snapshot "$d")
  bash "$S" "$d" >/dev/null
  b=$(snapshot "$d")
  assert_eq "$a" "$b" "second run leaves files identical"
  assert_eq "develop" "$(git -C "$d" branch --show-current)" "still on develop"
}

test_existing_status_doc_untouched() {
  local d
  d=$(new_tmp)
  mkdir -p "$d/docs"
  printf 'mine\n' > "$d/docs/PROJECT_STATUS.md"
  bash "$S" "$d" >/dev/null
  assert_eq "mine" "$(cat "$d/docs/PROJECT_STATUS.md")" "status doc untouched"
}

test_existing_claude_md_gets_only_missing_sections() {
  local d
  d=$(new_tmp)
  printf '# Mine\n\nCustom text.\n\n## working agreements\n\nMy rules.' > "$d/CLAUDE.md"
  bash "$S" "$d" >/dev/null
  assert_contains "$d/CLAUDE.md" "Custom text."
  assert_contains "$d/CLAUDE.md" "My rules."
  assert_contains "$d/CLAUDE.md" "## Project status doc"
  assert_eq "1" "$(grep -ci '^## working agreements$' "$d/CLAUDE.md")" "no duplicate working agreements"
  assert_eq "1" "$(grep -c '^## Project status doc$' "$d/CLAUDE.md")" "status section once"
  local a b
  a=$(snapshot "$d"); bash "$S" "$d" >/dev/null; b=$(snapshot "$d")
  assert_eq "$a" "$b" "merge is idempotent"
}

test_path_with_spaces_works() {
  local base d rc=0
  base=$(new_tmp)
  d="$base/my project dir"
  mkdir -p "$d"
  bash "$S" "$d" >/dev/null || rc=$?
  assert_eq "0" "$rc" "exit 0 with spaces"
  assert_file "$d/docs/PROJECT_STATUS.md"
  assert_eq "develop" "$(git -C "$d" branch --show-current)" "on develop"
}

test_existing_repo_with_commits_and_develop() {
  local d rc=0 head
  d=$(new_tmp)
  git -C "$d" init -q -b main
  echo a > "$d/a.txt"
  git -C "$d" add a.txt
  git -C "$d" commit -q -m first
  git -C "$d" branch develop
  head=$(git -C "$d" rev-parse main)
  local out
  out=$(bash "$S" "$d") || rc=$?
  assert_eq "0" "$rc" "exit 0"
  assert_eq "non-empty" "$(printf '%s\n' "$out" | head -n1)" "non-empty"
  assert_eq "$head" "$(git -C "$d" rev-parse main)" "main history preserved"
  assert_eq "$head" "$(git -C "$d" rev-parse develop)" "develop preserved"
  assert_eq "1" "$(git -C "$d" rev-list --count main)" "no extra commits"
  assert_eq "develop" "$(git -C "$d" branch --show-current)" "on develop"
  assert_eq "a" "$(cat "$d/a.txt")" "a.txt untouched"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
  echo "-- $t"; "$t"
done
finish
