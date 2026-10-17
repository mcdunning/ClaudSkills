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
  local p
  assert_contains "$T/CLAUDE.md" "## Git workflow"
  for p in "Never commit directly to main" "develop" "feature/" "squash" "approval"; do
    assert_contains "$T/CLAUDE.md" "$p"
  done
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
test_no_stack_specific_text
test_verification_sentence_generic
finish
