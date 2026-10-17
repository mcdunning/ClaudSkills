#!/usr/bin/env bash
# open-pr.sh <title> <body_file>: push the current feature/* branch and open a PR into develop.
# Last stdout line is the PR URL.
set -euo pipefail

die() { echo "open-pr: $1" >&2; exit 1; }

[ $# -eq 2 ] || die "usage: open-pr.sh <title> <body_file>"
title="$1"
body_file="$2"
[ -n "$title" ] || die "title must not be empty"
[ -f "$body_file" ] || die "body file '$body_file' not found"

git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
branch=$(git branch --show-current)
case "$branch" in
  feature/?*) ;;
  *) die "current branch '${branch:-detached HEAD}' is not a feature/* branch; PRs are opened from feature branches only" ;;
esac
[ -z "$(git status --porcelain)" ] || die "working tree has uncommitted or untracked changes; commit or remove them first"
git remote get-url origin >/dev/null 2>&1 || die "no 'origin' remote; add a remote (git remote add origin <url>) before opening a PR"

git push -q -u origin "$branch" || die "could not push $branch to origin"
gh pr create --base develop --head "$branch" --title "$title" --body-file "$body_file"
