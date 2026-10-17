#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$REAL/skills/new-project/templates"

test_status_is_three_paragraphs() {
  assert_file "$T/PROJECT_STATUS.md"
  local n
  n=$(awk 'BEGIN{RS=""} END{print NR}' "$T/PROJECT_STATUS.md")
  assert_eq "3" "$n" "status has exactly 3 paragraphs"
  local bad
  bad=$(grep -cE '^([#*-]|[0-9]+\.)' "$T/PROJECT_STATUS.md")
  assert_eq "0" "$bad" "status has no headings or list lines"
}

test_status_states_new_project() {
  assert_contains "$T/PROJECT_STATUS.md" "new project"
}

test_claude_has_header_and_sections() {
  assert_file "$T/CLAUDE.md"
  assert_eq "# CLAUDE.md" "$(sed -n 1p "$T/CLAUDE.md")" "title line"
  assert_contains "$T/CLAUDE.md" "This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository."
  assert_contains "$T/CLAUDE.md" "## Working agreements"
  assert_contains "$T/CLAUDE.md" "## Project status doc"
  assert_contains "$T/CLAUDE.md" "Exactly three paragraphs: no headings, no lists, no more, no fewer."
}

test_claude_has_git_workflow_section() {
  local f="$T/CLAUDE.md" l
  assert_contains "$f" "## Git workflow"
  for l in \
    '- Never commit directly to main. `main` changes only by PR and a formal release.' \
    '- `develop` is the running branch. Feature branches (`feature/<topic>`) branch off `develop` and merge back into it, squashed into one commit.' \
    "- Every commit to \`main\` or \`develop\` needs the user's approval, each time." \
    '- After the user approves the PR, squash-merge it and delete the feature branch.' \
    '- Use the start-feature / open-pr / merge-pr skills when installed; never merge locally into `develop` or `main`.'; do
    if grep -qxF -- "$l" "$f"; then echo "ok: line '$l'"; else _fail "missing exact line: $l"; fi
  done
}

test_status_rewrite_happens_on_feature_branch() {
  assert_contains "$T/CLAUDE.md" "rewrite it entirely on the feature branch before opening the PR"
  if grep -q "merging a PR" "$T/CLAUDE.md"; then _fail "status trigger still mentions merging a PR"; else echo "ok: no merging-a-PR trigger"; fi
}

test_no_stack_specific_text() {
  local f
  for f in CLAUDE.md PROJECT_STATUS.md; do
    if grep -qi flutter "$T/$f" 2>/dev/null; then
      _fail "$f mentions flutter"
    else
      echo "ok: $f has no flutter"
    fi
  done
}

test_verification_sentence_generic() {
  assert_contains "$T/CLAUDE.md" "Verify against the code and the project's own analysis and test commands first"
}

test_status_is_three_paragraphs
test_status_states_new_project
test_claude_has_header_and_sections
test_claude_has_git_workflow_section
test_status_rewrite_happens_on_feature_branch
test_no_stack_specific_text
test_verification_sentence_generic
finish
