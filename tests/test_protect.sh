#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
P="$REAL/skills/new-project/scripts/protect-branches.sh"

# Builds a stub gh in a fresh dir. Each call is logged to $GH_STUB_DIR/call.N:
# line 1 = args, remaining lines = stdin. If GH_STUB_FAIL is set, prints an
# error to stderr and exits 1. Prints the stub dir.
make_stub() {
  local d
  d=$(new_tmp)
  cat > "$d/gh" <<'STUB'
#!/usr/bin/env bash
n=$(find "$GH_STUB_DIR" -name 'call.*' | wc -l)
f="$GH_STUB_DIR/call.$((n + 1))"
printf '%s\n' "$*" > "$f"
cat >> "$f"
if [ -n "${GH_STUB_FAIL:-}" ]; then echo "HTTP 403: stub failure" >&2; exit 1; fi
exit 0
STUB
  chmod +x "$d/gh"
  printf '%s\n' "$d"
}

# Finds the call file whose args mention the given branch.
call_for() { grep -lF -- "branches/$2/protection" "$1"/call.* 2>/dev/null | head -n1; }

run_protect() { # stubdir [env...]; output in $OUT, rc in $RC
  local d="$1"
  RC=0
  OUT=$(GH_STUB_DIR="$d" PATH="$d:$PATH" bash "$P" "octo/demo" 2>&1) || RC=$?
}

test_protects_both_branches() {
  local d; d=$(make_stub)
  run_protect "$d"
  assert_eq "0" "$RC" "exit 0"
  assert_eq "2" "$(ls "$d"/call.* | wc -l)" "exactly two gh calls"
  assert_contains "$(call_for "$d" main)" "api -X PUT repos/octo/demo/branches/main/protection"
  assert_contains "$(call_for "$d" develop)" "api -X PUT repos/octo/demo/branches/develop/protection"
}

test_main_enforces_admins_develop_does_not() {
  local d; d=$(make_stub)
  run_protect "$d"
  assert_contains "$(call_for "$d" main)" '"enforce_admins": true'
  assert_contains "$(call_for "$d" develop)" '"enforce_admins": false'
}

test_requires_pull_request_without_approval_count() {
  local d b; d=$(make_stub)
  run_protect "$d"
  for b in main develop; do
    assert_contains "$(call_for "$d" "$b")" '"required_approving_review_count": 0'
    assert_contains "$(call_for "$d" "$b")" '"required_pull_request_reviews"'
    assert_contains "$(call_for "$d" "$b")" '"required_status_checks": null'
    assert_contains "$(call_for "$d" "$b")" '"restrictions": null'
  done
}

test_failure_is_reported_not_fatal() {
  local d; d=$(make_stub)
  GH_STUB_FAIL=1 run_protect "$d"
  assert_eq "0" "$RC" "exit 0 despite gh failure"
  case "$OUT" in *"could not protect main"*) echo "ok: reports main";; *) _fail "no 'could not protect main' in: $OUT";; esac
  case "$OUT" in *"could not protect develop"*) echo "ok: reports develop";; *) _fail "no 'could not protect develop' in: $OUT";; esac
  case "$OUT" in *"stub failure"*) echo "ok: includes gh error";; *) _fail "gh error missing in: $OUT";; esac
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
  echo "-- $t"; "$t"
done
finish
