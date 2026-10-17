#!/usr/bin/env bash
# start-feature.sh <topic>: create feature/<slug> off develop. Last stdout line is the branch name.
set -euo pipefail

die() { echo "start-feature: $1" >&2; exit 1; }

[ $# -ge 1 ] || die "usage: start-feature.sh <topic>"
topic="$*"
slug=$(printf '%s' "$topic" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
[ -n "$slug" ] || die "topic '$topic' has no letters or digits to build a branch name from"
[ "${#slug}" -le 60 ] || die "topic is too long (branch slug is ${#slug} chars, the limit is 60); use a shorter topic"
branch="feature/$slug"

git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
git check-ref-format --branch "$branch" >/dev/null 2>&1 || die "'$branch' is not a valid branch name"
[ -z "$(git status --porcelain)" ] || die "working tree has uncommitted or untracked changes; commit or remove them first"
git show-ref --verify --quiet refs/heads/develop || die "no local develop branch"
git show-ref --verify --quiet "refs/heads/$branch" && die "branch $branch already exists locally"

has_origin=0
git remote get-url origin >/dev/null 2>&1 && has_origin=1

if [ "$has_origin" -eq 1 ]; then
  if git ls-remote --exit-code --heads origin "refs/heads/$branch" >/dev/null 2>&1; then
    die "branch $branch already exists on origin"
  fi
fi

orig="$(git branch --show-current)"
[ -n "$orig" ] || orig="$(git rev-parse HEAD)"
git checkout -q develop
if [ "$has_origin" -eq 1 ]; then
  if ! git pull -q --ff-only origin develop; then
    git checkout -q "$orig" || true
    die "could not fast-forward develop from origin; returned to $orig"
  fi
fi
git checkout -q -b "$branch"
if [ "$has_origin" -eq 1 ]; then
  git push -q -u origin "$branch" || die "created $branch locally but could not push it to origin"
fi
echo "$branch"
