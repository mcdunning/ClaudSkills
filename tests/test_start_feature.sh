#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$REAL/skills/start-feature"
SCRIPT="$D/scripts/start-feature.sh"

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

run() { (cd "$1" && shift && bash "$SCRIPT" "$@"); }

test_creates_branch_from_develop() {
  local t; t=$(new_tmp); make_repo "$t/r"
  local tip; tip=$(git -C "$t/r" rev-parse develop)
  local out; out=$(run "$t/r" "login") ; local rc=$?
  assert_eq "0" "$rc" "exit 0"
  assert_eq "feature/login" "$(printf '%s\n' "$out" | tail -n1)" "last line is branch"
  assert_eq "feature/login" "$(git -C "$t/r" branch --show-current)" "checked out"
  assert_eq "$tip" "$(git -C "$t/r" rev-parse feature/login)" "branch starts at develop tip"
}

test_slugs_topic() {
  local t; t=$(new_tmp); make_repo "$t/r"
  local out; out=$(run "$t/r" "Add  Login Page!")
  assert_eq "feature/add-login-page" "$(printf '%s\n' "$out" | tail -n1)" "slugged"
  git -C "$t/r" checkout -q develop
  out=$(run "$t/r" "--Weird__Topic/v2.0--")
  assert_eq "feature/weird-topic-v2-0" "$(printf '%s\n' "$out" | tail -n1)" "punctuation slugged"
}

test_refuses_empty_slug() {
  local t; t=$(new_tmp); make_repo "$t/r"
  run "$t/r" "!!! ???" >/dev/null 2>&1; local rc=$?
  assert_eq "1" "$([ $rc -ne 0 ] && echo 1 || echo 0)" "empty slug refused"
  run "$t/r" "" >/dev/null 2>&1; rc=$?
  assert_eq "1" "$([ $rc -ne 0 ] && echo 1 || echo 0)" "empty arg refused"
  run "$t/r" >/dev/null 2>&1; rc=$?
  assert_eq "1" "$([ $rc -ne 0 ] && echo 1 || echo 0)" "no arg refused"
  assert_eq "develop" "$(git -C "$t/r" branch --show-current)" "still on develop"
}

test_refuses_dirty_tree() {
  local t; t=$(new_tmp); make_repo "$t/r"
  git -C "$t/r" checkout -q main
  echo x > "$t/r/f.txt"
  run "$t/r" "thing" >/dev/null 2>&1; local rc=$?
  assert_eq "1" "$([ $rc -ne 0 ] && echo 1 || echo 0)" "dirty refused"
  assert_eq "main" "$(git -C "$t/r" branch --show-current)" "still on original branch"
  assert_eq "" "$(git -C "$t/r" branch --list 'feature/*')" "no branch created"
  assert_file "$t/r/f.txt"
}

test_refuses_existing_branch() {
  local t; t=$(new_tmp); make_repo "$t/r"
  git -C "$t/r" branch feature/dup
  run "$t/r" "dup" >/dev/null 2>&1; local rc=$?
  assert_eq "1" "$([ $rc -ne 0 ] && echo 1 || echo 0)" "local existing refused"
  # remote variant
  local u; u=$(new_tmp); make_repo "$u/r" origin
  git -C "$u/r" push -q origin develop:refs/heads/feature/rem
  run "$u/r" "rem" >/dev/null 2>&1; rc=$?
  assert_eq "1" "$([ $rc -ne 0 ] && echo 1 || echo 0)" "remote existing refused"
  assert_eq "" "$(git -C "$u/r" branch --list 'feature/rem')" "no local branch created"
}

test_works_without_origin() {
  local t; t=$(new_tmp); make_repo "$t/r"
  git -C "$t/r" checkout -q main
  local out; out=$(run "$t/r" "solo"); local rc=$?
  assert_eq "0" "$rc" "exit 0 without origin"
  assert_eq "feature/solo" "$(git -C "$t/r" branch --show-current)" "on branch"
}

test_pulls_latest_develop_first() {
  local t; t=$(new_tmp); make_repo "$t/r" origin
  git clone -q -b develop "$t/r.origin.git" "$t/other"
  git -C "$t/other" commit -q --allow-empty -m upstream-change
  git -C "$t/other" push -q origin develop
  run "$t/r" "fresh" >/dev/null
  assert_eq "1" "$(git -C "$t/r" log --format=%s feature/fresh | grep -c upstream-change)" "upstream commit in branch"
}

test_pushes_upstream() {
  local t; t=$(new_tmp); make_repo "$t/r" origin
  run "$t/r" "pub" >/dev/null
  assert_eq "feature/pub" "$(git -C "$t/r.origin.git" branch --list 'feature/pub' | tr -d ' *')" "exists on origin"
  assert_eq "origin/feature/pub" "$(git -C "$t/r" rev-parse --abbrev-ref 'feature/pub@{upstream}')" "tracks origin"
}

test_path_with_spaces() {
  local t; t=$(new_tmp); mkdir "$t/my dir"; make_repo "$t/my dir/r"
  run "$t/my dir/r" "spacey" >/dev/null; local rc=$?
  assert_eq "0" "$rc" "works in path with spaces"
}

test_diverged_develop_restores_original_branch() {
  local t; t=$(new_tmp); make_repo "$t/r" origin
  git clone -q -b develop "$t/r.origin.git" "$t/other"
  git -C "$t/other" commit -q --allow-empty -m upstream-change
  git -C "$t/other" push -q origin develop
  git -C "$t/r" commit -q --allow-empty -m local-only
  git -C "$t/r" checkout -q main
  local dev; dev=$(git -C "$t/r" rev-parse develop)
  run "$t/r" "fresh" >/dev/null 2>&1; local rc=$?
  assert_eq "1" "$([ $rc -ne 0 ] && echo 1 || echo 0)" "diverged develop refused"
  assert_eq "main" "$(git -C "$t/r" branch --show-current)" "original branch restored"
  assert_eq "" "$(git -C "$t/r" branch --list 'feature/*')" "no branch created"
  assert_eq "$dev" "$(git -C "$t/r" rev-parse develop)" "develop untouched"
}

test_overlong_topic_refused_cleanly() {
  local t; t=$(new_tmp); make_repo "$t/r"
  git -C "$t/r" checkout -q main
  local long; long=$(printf 'word %.0s' $(seq 1 40))
  local err; err=$(run "$t/r" "$long" 2>&1 >/dev/null); local rc=$?
  assert_eq "1" "$([ $rc -ne 0 ] && echo 1 || echo 0)" "overlong refused"
  assert_eq "1" "$(printf '%s\n' "$err" | wc -l | tr -d ' ')" "one-line reason"
  assert_eq "main" "$(git -C "$t/r" branch --show-current)" "branch unchanged"
  assert_eq "" "$(git -C "$t/r" branch --list 'feature/*')" "no branch created"
  assert_eq "" "$(git -C "$t/r" status --porcelain)" "tree clean"
}

test_dirty_message_wording() {
  local t; t=$(new_tmp); make_repo "$t/r"
  echo x > "$t/r/f.txt"
  local err; err=$(run "$t/r" "thing" 2>&1 >/dev/null)
  printf '%s\n' "$err" > "$t/err.txt"
  assert_contains "$t/err.txt" "commit or remove them first"
}

test_skill_frontmatter_and_script_path() {
  local S="$D/SKILL.md"
  assert_file "$S"
  local fm; fm=$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$S" 2>/dev/null)
  if printf '%s\n' "$fm" | grep -qxF -- "name: start-feature"; then echo "ok: name"; else _fail "name missing from frontmatter"; fi
  if printf '%s\n' "$fm" | grep -q '^description: Use when starting implementation of a plan or spec and work needs a feature branch off develop'; then echo "ok: description"; else _fail "description missing"; fi
  assert_contains "$S" 'scripts/start-feature.sh'
  assert_file "$SCRIPT"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do "$t"; done
finish
