#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
D="$REAL/skills/new-project"
S="$D/SKILL.md"

test_frontmatter_name_and_description() {
  assert_file "$S"
  assert_eq "---" "$(head -n1 "$S" 2>/dev/null)" "frontmatter opens with ---"
  assert_contains "$S" "name: new-project"
  local desc="description: Use when the user wants to start, create, or set up a new project in the current directory, including an existing folder that has no project structure yet. Creates the git repo, GitHub remote, docs structure and CLAUDE.md, then plans or analyzes the project."
  local fm
  fm=$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$S")
  if printf '%s\n' "$fm" | grep -qxF -- "$desc"; then echo "ok: description inside frontmatter"; else _fail "description missing from frontmatter block"; fi
  if printf '%s\n' "$fm" | grep -qxF -- "name: new-project"; then echo "ok: name inside frontmatter"; else _fail "name missing from frontmatter block"; fi
}

test_references_resolve() {
  local p n=0
  while IFS= read -r p; do
    n=$((n + 1))
    assert_file "$D/$p"
  done < <(grep -oE '(scripts|templates)/[A-Za-z0-9_./-]+' "$S" 2>/dev/null | sed 's/[.,;:)]*$//' | sort -u)
  if [ "$n" -eq 0 ]; then _fail "SKILL.md mentions no scripts/ or templates/ paths"; fi
}

NEVER_LINE="Never ask the user for a language, stack or test commands."
ASK_RE='ask.*(language|stack|framework|test command|build command|lint command)'

# Prints offending lines of file $1: any ask-for-stack match except the exact never line.
ask_offenders() {
  grep -iE "$ASK_RE" "$1" | grep -vxF "$NEVER_LINE"
}

test_does_not_ask_language() {
  assert_contains "$S" "$NEVER_LINE"
  local off
  off=$(ask_offenders "$S")
  assert_eq "" "$off" "no line asks for language/stack/commands"
}

test_ask_check_catches_injection() {
  local t line
  t=$(new_tmp)
  for line in "Ask the user which language they prefer" "ask for the test command"; do
    cp "$S" "$t/SKILL.md"
    printf '%s\n' "$line" >> "$t/SKILL.md"
    off=$(ask_offenders "$t/SKILL.md")
    assert_eq "$line" "$off" "check flags injected '$line'"
  done
}

test_confirm_before_repo_create() {
  local c g
  c=$(grep -niE 'confirm.*(name|visibility|public or private)' "$S" | head -n1 | cut -d: -f1)
  g=$(grep -n 'gh repo create' "$S" | head -n1 | cut -d: -f1)
  if [ -n "$c" ] && [ -n "$g" ] && [ "$c" -lt "$g" ]; then
    echo "ok: confirmation (line $c) precedes gh repo create (line $g)"
  else
    _fail "no confirm line before gh repo create (confirm=$c, create=$g)"
  fi
}

test_paths_use_skill_base_dir() {
  local bad
  bad=$(grep -E 'bash +"?(scripts|templates)/' "$S")
  assert_eq "" "$bad" "no bare relative script commands"
  assert_contains "$S" 'bash "<skill-base-dir>/scripts/scaffold.sh"'
}

test_frontmatter_name_and_description
test_references_resolve
test_does_not_ask_language
test_ask_check_catches_injection
test_confirm_before_repo_create
test_paths_use_skill_base_dir
finish
