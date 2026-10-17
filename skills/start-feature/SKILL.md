---
name: start-feature
description: Use when starting implementation of a plan or spec and work needs a feature branch off develop
---

# start-feature

Creates `feature/<slug>` off an up-to-date `develop` and, when the repo has an `origin`, pushes it with upstream tracking.

`<skill-base-dir>` means the directory containing this SKILL.md. Call the script by its full path, with the project repository (the user's current directory) as the working directory.

## Procedure

1. Derive a short topic from the name of the plan or spec being implemented (for example the plan file `2026-10-17-login-page.md` gives `login page`). The script lowercases it and turns runs of other characters into `-`.
2. Run `bash "<skill-base-dir>/scripts/start-feature.sh" "<topic>"`.
3. The last output line is the created branch name. Report it to the user.
4. If the script exits non-zero it prints a one-line reason (dirty working tree, branch already exists locally or on origin, topic with no letters or digits or longer than 60 characters once slugged, `develop` cannot be fast-forwarded from origin). Relay that reason to the user and stop; no branch is created, and the script returns to the branch you started on if it had already switched to `develop`. Do not stash, commit, or delete branches to work around a refusal without the user's say-so.
