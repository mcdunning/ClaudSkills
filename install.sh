#!/usr/bin/env bash
# Links each skills/*/ directory into a target dir (default ~/.claude/skills).
# Usage: install.sh [target_dir]
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-$HOME/.claude/skills}"
mkdir -p "$target" || exit 1

rc=0
for src in "$root"/skills/*/; do
  [ -d "$src" ] || continue
  src="${src%/}"
  name="$(basename "$src")"
  dest="$target/$name"
  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" == "$src" ]; then
      echo "skipped (already linked): $name"
    else
      echo "refused (symlink points elsewhere): $name" >&2
      rc=1
    fi
  elif [ -e "$dest" ]; then
    echo "refused (exists and is not a symlink): $name" >&2
    rc=1
  else
    ln -s "$src" "$dest" && echo "linked: $name" || rc=1
  fi
done
exit "$rc"
