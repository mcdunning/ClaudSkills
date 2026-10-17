#!/usr/bin/env bash
# merge-pr.sh <pr_number>: squash-merge an approved feature PR into develop, then sync local state.
# Refuses unless the PR's base is develop and its head is feature/*. Never merges to main.
set -euo pipefail

die() { echo "merge-pr: $1" >&2; exit 1; }

[ $# -eq 1 ] || die "usage: merge-pr.sh <pr_number>"
pr="$1"
case "$pr" in
  ''|*[!0-9]*) die "PR number must be digits only, got '$pr'" ;;
esac

git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
git remote get-url origin >/dev/null 2>&1 || die "no 'origin' remote; merging needs the GitHub repository as origin"
# Check before merging: a dirty tree could block the checkout afterwards and leave things half done.
[ -z "$(git status --porcelain)" ] || die "working tree has uncommitted or untracked changes; commit or remove them before merging"

info=$(gh pr view "$pr" --json baseRefName,headRefName,headRefOid --jq '.baseRefName + " " + .headRefName + " " + .headRefOid') \
  || die "could not read PR #$pr with gh"
read -r base head oid extra <<< "$info"
[ -n "$base" ] && [ -n "$head" ] && [ -n "$oid" ] && [ -z "$extra" ] || die "unexpected gh output for PR #$pr: '$info'"

[ "$base" = "develop" ] || die "PR #$pr targets '$base'; only PRs into develop can be merged (merging to main is never done here)"
case "$head" in
  feature/?*) ;;
  *) die "PR #$pr head '$head' is not a feature/* branch" ;;
esac

# No --delete-branch: gh would force-delete the local branch itself, bypassing the tip guard below.
# --match-head-commit makes gh refuse if the PR head moved since we read it.
gh pr merge "$pr" --squash --match-head-commit "$oid" || die "gh pr merge failed for PR #$pr"

# gh may have switched branches; a missing local branch is fine.
git checkout -q develop || die "PR #$pr merged, but could not check out develop"
git pull -q --ff-only origin develop || die "PR #$pr merged, but could not fast-forward develop from origin"
kept=""
if git show-ref --verify --quiet "refs/heads/$head"; then
  if [ "$(git rev-parse "refs/heads/$head")" = "$oid" ]; then
    # Squash merges leave the branch "unmerged" from git's view, so -D is required;
    # the tip equals the merged head, so nothing is lost.
    git branch -q -D "$head" || die "PR #$pr merged, but could not delete local branch $head"
  else
    kept="kept local branch $head: it has commits that were not part of PR #$pr"
  fi
fi
# Remove the remote branch. A missing remote ref is fine; any other failure is only a warning.
warn=""
if ! del_out=$(LC_ALL=C git push origin --delete "$head" 2>&1); then
  case "$del_out" in
    *"remote ref does not exist"*) ;;
    *) warn="warning: could not delete remote branch $head: $(printf '%s' "$del_out" | tail -n1)" ;;
  esac
fi
echo "merged PR #$pr ($head) into develop; develop is up to date"
[ -z "$kept" ] || echo "$kept"
[ -z "$warn" ] || echo "$warn"
