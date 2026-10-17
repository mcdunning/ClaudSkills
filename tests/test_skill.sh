#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$REAL/skills/new-project"
S="$D/SKILL.md"

test_frontmatter_name_and_description() {
  assert_file "$S"
  assert_eq "---" "$(head -n1 "$S" 2>/dev/null)" "frontmatter opens with ---"
  assert_contains "$S" "name: new-project"
  assert_contains "$S" "description: Use when the user wants to start, create, or set up a new project in the current directory, including an existing folder that has no project structure yet. Creates the git repo, GitHub remote, docs structure and CLAUDE.md, then plans or analyzes the project."
}

test_references_resolve() {
  local p n=0
  while IFS= read -r p; do
    n=$((n + 1))
    assert_file "$D/$p"
  done < <(grep -oE '(scripts|templates)/[A-Za-z0-9_./-]+' "$S" 2>/dev/null | sed 's/[.,;:)]*$//' | sort -u)
  if [ "$n" -eq 0 ]; then _fail "SKILL.md mentions no scripts/ or templates/ paths"; fi
}

test_does_not_ask_language() {
  if grep -qi "never ask the user for a language" "$S"; then echo "ok: states never ask for language"; else _fail "SKILL.md lacks the never-ask-language rule"; fi
  if grep -iE '(^|[^a-z])ask[^.]*(which|what) (programming )?(language|stack|framework)' "$S" | grep -viE 'never|not|do n' >/dev/null 2>&1; then
    _fail "SKILL.md appears to ask the user for a language or stack"
  else
    echo "ok: no instruction to ask for language"
  fi
}

test_frontmatter_name_and_description
test_references_resolve
test_does_not_ask_language
finish
