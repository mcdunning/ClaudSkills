#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$REAL/skills/open-pr"
SCRIPT="$D/scripts/open-pr.sh"

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

# make_stub <dir>: stub gh first on PATH; logs one arg per line plus the body file contents.
make_stub() {
  mkdir -p "$1/bin"
  cat > "$1/bin/gh" <<'STUB'
#!/usr/bin/env bash
{
  echo "ARGS-BEGIN"
  for a in "$@"; do printf 'ARG:%s\n' "$a"; done
  prev=""
  for a in "$@"; do
    [ "$prev" = "--body-file" ] && { echo "BODY-BEGIN"; cat "$a"; echo "BODY-END"; }
    prev="$a"
  done
} >> "$GH_LOG"
echo "https://github.com/o/r/pull/7"
STUB
  chmod +x "$1/bin/gh"
}

# setup: repo with origin on feature/x with one commit, stub gh, body file.
setup() {
  T=$(new_tmp); make_repo "$T/r" origin
  git -C "$T/r" checkout -q -b feature/x
  git -C "$T/r" commit -q --allow-empty -m work
  make_stub "$T"; export GH_LOG="$T/gh.log"; : > "$GH_LOG"
  printf 'Summary line\nVerified: tests\n' > "$T/body.md"
}

run() { (cd "$1" && shift && PATH="$T/bin:$PATH" bash "$SCRIPT" "$@"); }
failed() { [ "$1" -ne 0 ] && echo 1 || echo 0; }

test_creates_pr_into_develop() {
  setup
  local out; out=$(run "$T/r" "My title" "$T/body.md"); local rc=$?
  assert_eq "0" "$rc" "exit 0"
  assert_eq "https://github.com/o/r/pull/7" "$(printf '%s\n' "$out" | tail -n1)" "last line is URL"
  assert_contains "$GH_LOG" "ARG:pr"
  assert_contains "$GH_LOG" "ARG:create"
  assert_contains "$GH_LOG" "ARG:--base"
  assert_contains "$GH_LOG" "ARG:develop"
  assert_contains "$GH_LOG" "ARG:--head"
  assert_contains "$GH_LOG" "ARG:feature/x"
  assert_contains "$GH_LOG" "ARG:My title"
  assert_contains "$GH_LOG" "ARG:$T/body.md"
  assert_contains "$GH_LOG" "Verified: tests"
}

test_title_starting_with_dash() {
  setup
  run "$T/r" "--draft fix" "$T/body.md" >/dev/null; local rc=$?
  assert_eq "0" "$rc" "exit 0"
  assert_eq "ARG:--title
ARG:--draft fix" "$(grep -A1 -x 'ARG:--title' "$GH_LOG")" "title follows --title as one arg"
}

test_pushes_branch_first() {
  setup
  run "$T/r" "t" "$T/body.md" >/dev/null
  assert_eq "feature/x" "$(git -C "$T/r.origin.git" branch --list 'feature/x' | tr -d ' *')" "branch on origin"
  assert_eq "origin/feature/x" "$(git -C "$T/r" rev-parse --abbrev-ref 'feature/x@{upstream}')" "tracks origin"
}

test_refuses_on_develop_and_main() {
  setup
  local b rc
  for b in develop main; do
    git -C "$T/r" checkout -q "$b"
    run "$T/r" "t" "$T/body.md" >/dev/null 2>&1; rc=$?
    assert_eq "1" "$(failed $rc)" "refused on $b"
  done
  assert_eq "0" "$(wc -c < "$GH_LOG" | tr -d ' ')" "gh never called"
}

test_refuses_dirty_tree() {
  setup
  echo x > "$T/r/tracked.txt"; git -C "$T/r" add tracked.txt; git -C "$T/r" commit -q -m t
  echo y >> "$T/r/tracked.txt"
  run "$T/r" "t" "$T/body.md" >/dev/null 2>&1; local rc=$?
  assert_eq "1" "$(failed $rc)" "modified refused"
  git -C "$T/r" checkout -q -- tracked.txt
  echo z > "$T/r/untracked.txt"
  run "$T/r" "t" "$T/body.md" >/dev/null 2>&1; rc=$?
  assert_eq "1" "$(failed $rc)" "untracked refused"
  assert_eq "0" "$(wc -c < "$GH_LOG" | tr -d ' ')" "gh never called"
}

test_refuses_without_origin() {
  setup
  git -C "$T/r" remote remove origin
  local err; err=$(run "$T/r" "t" "$T/body.md" 2>&1 >/dev/null); local rc=$?
  assert_eq "1" "$(failed $rc)" "refused"
  printf '%s\n' "$err" > "$T/err.txt"
  assert_contains "$T/err.txt" "remote"
  assert_eq "0" "$(wc -c < "$GH_LOG" | tr -d ' ')" "gh never called"
}

test_refuses_bad_args() {
  setup
  run "$T/r" >/dev/null 2>&1; local rc=$?
  assert_eq "1" "$(failed $rc)" "no args refused"
  run "$T/r" "t" "$T/missing.md" >/dev/null 2>&1; rc=$?
  assert_eq "1" "$(failed $rc)" "missing body file refused"
  run "$T/r" "" "$T/body.md" >/dev/null 2>&1; rc=$?
  assert_eq "1" "$(failed $rc)" "empty title refused"
}

test_skill_frontmatter_and_script_path() {
  local S="$D/SKILL.md"
  assert_file "$S"
  local fm; fm=$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$S" 2>/dev/null)
  if printf '%s\n' "$fm" | grep -qxF -- "name: open-pr"; then echo "ok: name"; else _fail "name missing from frontmatter"; fi
  if printf '%s\n' "$fm" | grep -q '^description: Use when all steps of a plan on a feature branch are complete and the work should be reviewed'; then echo "ok: description"; else _fail "description missing"; fi
  assert_contains "$S" 'scripts/open-pr.sh'
  assert_file "$SCRIPT"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do "$t"; done
finish
