---
name: open-pr
description: Use when all steps of a plan on a feature branch are complete and the work should be reviewed
---

# open-pr

Pushes the current `feature/*` branch and opens a pull request into `develop` with `gh`. Claude never merges the PR; merging happens only after the user approves (see merge-pr).

`<skill-base-dir>` means the directory containing this SKILL.md. Call the script by its full path, with the project repository (the user's current directory) as the working directory.

## Procedure

1. Confirm every step of the plan is done and committed on the feature branch. Run the project's verification commands (tests, lint, build; whatever the project's CLAUDE.md or README names). If a step is unfinished or any check fails, stop and report what is missing or failing. Do not open the PR.
2. Write the PR body to a temp file (for example with `mktemp`), in Markdown, containing:
   - a short summary of the change,
   - how it was verified (the commands run and their results),
   - a link or path to the plan and spec it implements.
3. Choose a concise PR title that describes the change.
4. Run `bash "<skill-base-dir>/scripts/open-pr.sh" "<title>" "<body-file>"`.
5. The last output line is the PR URL. If the script exits non-zero it prints a one-line reason (not on a `feature/*` branch, uncommitted or untracked changes, no `origin` remote, push failure, `gh` failure). Relay it and stop; do not commit, stash, or add remotes to work around it without the user's say-so.
6. Notify the user: send a clear message in the session saying the PR is ready, with its URL. If a push notification tool is available, send one too.
7. Stop. Do not merge, approve, or close the PR. Wait for the user to say it is approved.
