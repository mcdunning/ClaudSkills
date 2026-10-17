#!/usr/bin/env bash
# start-feature.sh <topic>: create feature/<slug> off develop. Last stdout line is the branch name.
set -euo pipefail

die() { echo "start-feature: $1" >&2; exit 1; }

[ $# -ge 1 ] || die "usage: start-feature.sh <topic>"
topic="$*"
slug=$(printf '%s' "$topic" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
[ -n "$slug" ] || die "topic '$topic' has no letters or digits to build a branch name from"
branch="feature/$slug"

git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
[ -z "$(git status --porcelain)" ] || die "working tree has uncommitted changes; commit or stash them first"
git show-ref --verify --quiet refs/heads/develop || die "no local develop branch"
git show-ref --verify --quiet "refs/heads/$branch" && die "branch $branch already exists locally"

has_origin=0
git remote get-url origin >/dev/null 2>&1 && has_origin=1

if [ "$has_origin" -eq 1 ]; then
  if git ls-remote --exit-code --heads origin "refs/heads/$branch" >/dev/null 2>&1; then
    die "branch $branch already exists on origin"
  fi
fi

git checkout -q develop
if [ "$has_origin" -eq 1 ]; then
  git pull -q --ff-only origin develop || die "could not fast-forward develop from origin"
fi
git checkout -q -b "$branch"
if [ "$has_origin" -eq 1 ]; then
  git push -q -u origin "$branch" || die "created $branch locally but could not push it to origin"
fi
echo "$branch"
