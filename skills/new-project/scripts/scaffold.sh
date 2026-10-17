#!/usr/bin/env bash
# Usage: scaffold.sh [target_dir]
# Prints "empty" or "non-empty" as the first line (judged before anything is
# created), then scaffolds git branches, docs/ and CLAUDE.md. Never modifies
# any other existing file.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tpl="$script_dir/../templates"
target="${1:-.}"
cd "$target"

# 1. Judge emptiness first. README*, LICENSE*, .gitignore and .git do not count.
state=empty
while IFS= read -r -d '' entry; do
  case "$entry" in
    .git|.gitignore|README|README.*|LICENSE|LICENSE.*) ;;
    *) state=non-empty; break ;;
  esac
done < <(find . -mindepth 1 -maxdepth 1 -printf '%P\0')
echo "$state"

# 2. Git repo and branches.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  git init -q -b main
fi
if ! git rev-parse --verify -q HEAD >/dev/null; then
  # No commits yet: unborn branch becomes main with an empty initial commit.
  git symbolic-ref HEAD refs/heads/main
  git -c user.name="${GIT_AUTHOR_NAME:-$(git config user.name || echo scaffold)}" \
      -c user.email="${GIT_AUTHOR_EMAIL:-$(git config user.email || echo scaffold@localhost)}" \
      commit -q --allow-empty -m "chore: initial commit"
fi
git show-ref --verify -q refs/heads/main || git branch main HEAD
git show-ref --verify -q refs/heads/develop || git branch develop main
git checkout -q develop

# 3. Docs structure.
mkdir -p docs/plans docs/specs
[ -e docs/PROJECT_STATUS.md ] || cp "$tpl/PROJECT_STATUS.md" docs/PROJECT_STATUS.md

# 4. CLAUDE.md: copy, or append only missing sections.
if [ ! -e CLAUDE.md ]; then
  cp "$tpl/CLAUDE.md" CLAUDE.md
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  # Split the template into section files on lines starting with "## ".
  awk -v dir="$tmp" '
    /^## / { n++; f = sprintf("%s/sec%03d", dir, n) }
    n { print > f }
  ' "$tpl/CLAUDE.md"
  eol=$'\n'
  grep -q $'\r' CLAUDE.md && eol=$'\r\n'
  for sec in "$tmp"/sec*; do
    [ -e "$sec" ] || continue
    heading="$(head -n1 "$sec" | sed 's/[[:space:]]*$//')"
    if ! tr -d '\r' < CLAUDE.md | grep -qixF -- "$heading"; then
      # Ensure the file ends with a newline, then a blank separator line.
      [ -z "$(tail -c1 CLAUDE.md)" ] || printf '%s' "$eol" >> CLAUDE.md
      printf '%s' "$eol" >> CLAUDE.md
      # Drop trailing blank lines of the section, keep its text.
      sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$sec" | sed "s/\$/${eol%$'\n'}/" >> CLAUDE.md
    fi
  done
fi
