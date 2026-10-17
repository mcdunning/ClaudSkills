# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status

This repository is currently empty: no source files, build tooling, tests, README, or editor/agent rule files exist yet, and it is not a git repository. There are no build, lint, or test commands to document.

Once code is added, re-run `/init` to fill in commands (including how to run a single test) and the high-level architecture.

## Working agreements

Rules, preferences, and "remember this" items from the user go in the project files (this `CLAUDE.md`, or `docs/` where it is reference material), not only in personal auto-memory, so anyone can pick the project up and continue. When the user gives a new rule or marks something to be remembered, write it here in the same change.

## Project status doc

`docs/PROJECT_STATUS.md` is the read-first handoff for new sessions and engineers. After significant work (finishing a feature, resolving a major issue), rewrite it entirely on the feature branch before opening the PR, so it lands with the change; never as a direct commit to `develop` after merging. Never append a history log. Rules:

- Exactly three paragraphs: no headings, no lists, no more, no fewer.
- Facts only: no assumptions, theories, or speculation about why something happened or what might be true. Verify against the code and the project's own analysis and test commands first.
- Written as instructions to another developer, as if the document were the only context they get.
- Paragraph 1: what was done and the current state of the project.
- Paragraph 2: files updated/created, mistakes to avoid, key insights/lessons learned.
- Paragraph 3: current problems/errors/open items, and anything else needed to work productively (setup requirements, what's unverified, what's not started).
- In the same change, check `README.md` and everything under `docs/` for stale mentions of a feature's old status and fix them without being asked. Exclude plans: implementation plans are point-in-time instructions, not living reference docs.

## Git workflow

- Never commit directly to main. `main` changes only by PR and a formal release.
- `develop` is the running branch. Feature branches (`feature/<topic>`) branch off `develop` and merge back into it, squashed into one commit.
- Every commit to `main` or `develop` needs the user's approval, each time.
- Version bumps and doc updates may go straight to `develop` only during a release, with no PR, and still need the user's approval. Outside a release, all changes to `develop` go through a PR.
- Commit freely on feature branches, following the steps in the plan.
- When all plan steps are done, open a PR into the parent branch and notify the user.
- After the user approves the PR, squash-merge it and delete the feature branch.
- Use the start-feature / open-pr / merge-pr skills when installed; never merge locally into `develop` or `main`.
