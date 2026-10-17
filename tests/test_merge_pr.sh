#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$REAL/skills/merge-pr"
SCRIPT="$D/scripts/merge-pr.sh"

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

# make_stub <dir>: stub gh first on PATH; logs one arg per line.
# `pr view` prints $GH_VIEW (the already jq-processed "<base> <head>" line);
# `pr merge` runs $GH_MERGE_HOOK (if set) to simulate GitHub's side effects.
make_stub() {
  mkdir -p "$1/bin"
  cat > "$1/bin/gh" <<'STUB'
#!/usr/bin/env bash
{
  echo "ARGS-BEGIN"
  for a in "$@"; do printf 'ARG:%s\n' "$a"; done
} >> "$GH_LOG"
if [ "$1" = "pr" ] && [ "$2" = "view" ]; then
  [ -n "${GH_VIEW:-}" ] || exit 1
  echo "$GH_VIEW"
elif [ "$1" = "pr" ] && [ "$2" = "merge" ]; then
  [ -z "${GH_MERGE_HOOK:-}" ] || eval "$GH_MERGE_HOOK"
fi
exit 0
STUB
  chmod +x "$1/bin/gh"
}

# setup: repo with origin, local feature/x with one commit, stub gh, currently on feature/x.
setup() {
  T=$(new_tmp); make_repo "$T/r" origin
  git -C "$T/r" checkout -q -b feature/x
  git -C "$T/r" commit -q --allow-empty -m work
  make_stub "$T"; export GH_LOG="$T/gh.log"; : > "$GH_LOG"
  export GH_VIEW="develop feature/x"
  # Simulate the squash merge landing on origin/develop from another clone.
  export GH_MERGE_HOOK="git clone -q '$T/r.origin.git' '$T/other' && git -C '$T/other' checkout -q develop && git -C '$T/other' commit -q --allow-empty -m 'squash x' && git -C '$T/other' push -q origin develop && rm -rf '$T/other'"
}

run() { (cd "$1" && shift && PATH="$T/bin:$PATH" bash "$SCRIPT" "$@"); }
# calls: one line per gh invocation, args space-joined (exact flag/value adjacency).
calls() { awk '/^ARGS-BEGIN$/{if(s!="")print s; s="";next} {sub(/^ARG:/,""); s=(s==""?$0:s" "$0)} END{if(s!="")print s}' "$GH_LOG"; }
has_call() { calls | grep -qxF -- "$1" && echo yes || echo no; }
merge_calls() { calls | grep -c '^pr merge' || true; }
failed() { [ "$1" -ne 0 ] && echo 1 || echo 0; }

test_squash_merges_and_deletes_branch() {
  setup
  run "$T/r" 12 >/dev/null; local rc=$?
  assert_eq "0" "$rc" "exit 0"
  assert_eq "yes" "$(has_call 'pr view 12 --json baseRefName,headRefName --jq .baseRefName + " " + .headRefName')" "pr view call"
  assert_eq "yes" "$(has_call 'pr merge 12 --squash --delete-branch')" "pr merge call"
}

test_cleans_up_local_branch_and_updates_develop() {
  setup
  run "$T/r" 12 >/dev/null; local rc=$?
  assert_eq "0" "$rc" "exit 0"
  assert_eq "develop" "$(git -C "$T/r" branch --show-current)" "on develop"
  assert_eq "" "$(git -C "$T/r" branch --list feature/x)" "local branch gone"
  assert_eq "squash x" "$(git -C "$T/r" log -1 --format=%s develop)" "develop fast-forwarded"
  assert_eq "$(git -C "$T/r.origin.git" rev-parse develop)" "$(git -C "$T/r" rev-parse develop)" "develop matches origin"
}

test_missing_local_branch_is_not_an_error() {
  setup
  git -C "$T/r" checkout -q develop
  git -C "$T/r" branch -D feature/x -q
  run "$T/r" 12 >/dev/null; local rc=$?
  assert_eq "0" "$rc" "exit 0"
  assert_eq "yes" "$(has_call 'pr merge 12 --squash --delete-branch')" "merged"
  assert_eq "develop" "$(git -C "$T/r" branch --show-current)" "on develop"
}

test_refuses_base_main() {
  setup; export GH_VIEW="main feature/x"
  local err; err=$(run "$T/r" 12 2>&1 >/dev/null); local rc=$?
  assert_eq "1" "$(failed $rc)" "refused"
  assert_eq "0" "$(merge_calls)" "no pr merge call"
  printf '%s\n' "$err" > "$T/err.txt"; assert_contains "$T/err.txt" "develop"
  assert_eq "feature/x" "$(git -C "$T/r" branch --show-current)" "branch untouched"
}

test_refuses_non_feature_head() {
  setup; export GH_VIEW="develop hotfix/x"
  run "$T/r" 12 >/dev/null 2>&1; local rc=$?
  assert_eq "1" "$(failed $rc)" "refused"
  assert_eq "0" "$(merge_calls)" "no pr merge call"
  export GH_VIEW="develop feature/"
  run "$T/r" 12 >/dev/null 2>&1; rc=$?
  assert_eq "1" "$(failed $rc)" "empty feature name refused"
  assert_eq "0" "$(merge_calls)" "still no pr merge call"
}

test_refuses_bad_pr_number() {
  setup
  local bad
  for bad in "" "abc" "12a" "-1" "1 2" "--admin"; do
    if [ -z "$bad" ]; then run "$T/r" >/dev/null 2>&1; else run "$T/r" "$bad" >/dev/null 2>&1; fi
    assert_eq "1" "$(failed $?)" "refused '$bad'"
  done
  run "$T/r" 1 2 >/dev/null 2>&1
  assert_eq "1" "$(failed $?)" "extra arg refused"
  assert_eq "0" "$(wc -c < "$GH_LOG" | tr -d ' ')" "gh never called"
}

test_refuses_dirty_tree_before_merge() {
  setup
  echo z > "$T/r/untracked.txt"
  run "$T/r" 12 >/dev/null 2>&1; local rc=$?
  assert_eq "1" "$(failed $rc)" "refused"
  assert_eq "0" "$(merge_calls)" "no pr merge call"
}

test_refuses_without_origin() {
  setup
  git -C "$T/r" remote remove origin
  local err; err=$(run "$T/r" 12 2>&1 >/dev/null); local rc=$?
  assert_eq "1" "$(failed $rc)" "refused"
  printf '%s\n' "$err" > "$T/err.txt"; assert_contains "$T/err.txt" "origin"
  assert_eq "0" "$(merge_calls)" "no pr merge call"
}

test_pr_view_failure_does_not_merge() {
  setup; export GH_VIEW=""
  run "$T/r" 12 >/dev/null 2>&1; local rc=$?
  assert_eq "1" "$(failed $rc)" "refused"
  assert_eq "0" "$(merge_calls)" "no pr merge call"
}

test_skill_frontmatter_and_script_path() {
  local S="$D/SKILL.md"
  assert_file "$S"
  local fm; fm=$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$S" 2>/dev/null)
  if printf '%s\n' "$fm" | grep -qxF -- "name: merge-pr"; then echo "ok: name"; else _fail "name missing from frontmatter"; fi
  if printf '%s\n' "$fm" | grep -q '^description: Use when the user has approved a feature PR and it should be merged'; then echo "ok: description"; else _fail "description missing"; fi
  assert_contains "$S" 'scripts/merge-pr.sh'
  assert_contains "$S" 'never'
  assert_file "$SCRIPT"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do "$t"; done
finish
