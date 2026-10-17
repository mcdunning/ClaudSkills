---
name: merge-pr
description: Use when the user has approved a feature PR and it should be merged
---

# merge-pr

Squash-merges an approved `feature/*` pull request into `develop` with `gh`, then updates local `develop` and removes the feature branch where it safely can. This skill never merges to `main`; releasing to `main` is always the user's own action.

`<skill-base-dir>` means the directory containing this SKILL.md. Call the script by its full path, with the project repository (the user's current directory) as the working directory.

## Procedure

1. Proceed only if, after this PR was opened, the user explicitly told you to merge PR #N or said PR #N is approved; earlier general statements, passing checks or approval of another PR do not count. Otherwise ask and stop.
2. Identify the PR number (digits only, from the open-pr output URL or the user).
3. Run `bash "<skill-base-dir>/scripts/merge-pr.sh" <pr_number>`.
4. If the script exits non-zero it prints a one-line reason (invalid number, no `origin` remote, uncommitted or untracked changes, PR base is not `develop`, head is not `feature/*`, `gh` failure). Relay it and stop; do not work around it (no stashing, retargeting the PR, or merging by hand) without the user's say-so.
5. On success, relay the script output: the PR was squash-merged and local `develop` is updated. The script also deletes the remote feature branch and, when the local tip matches the merged head, the local one. Relay any `kept local branch` note and any `warning: could not delete remote branch` line as printed; do not claim the branch is deleted unconditionally.
6. State plainly that nothing was merged to `main` and this skill never does that.
