# Git flow skills: design

## Intent

The user wants Claude to follow one consistent git workflow in every project without being re-told. The workflow is split into small skills that load on demand; the always-on rules also live in each project's `CLAUDE.md`. These skills depend on the setup `new-project` performs (see `2026-10-17-new-project-skill-design.md`).

## Goals

- Claude never commits to `main` or `develop` without the user's approval, and never pushes anything unreviewed to either.
- All real work happens on feature branches off `develop`, and is reviewed through a GitHub PR.
- Claude works autonomously on a feature branch following the plan, then hands off for review.

## Non-goals

- Hosts other than GitHub. The `gh` CLI is installed and authenticated on this machine.
- Release versioning scheme, changelog format and tagging: not yet decided (see Open below).

## Rules (stated by the user)

- No direct commits to `main`. `main` changes only by PR and a formal release.
- `develop` is the running set of changes. Feature branches branch off `develop` and merge back into it.
- Merging a feature branch squashes its commits into one.
- Every commit to `main` and `develop` requires the user's approval, each time.
- During the release phase only, version bumps and documentation updates are committed directly to `develop` with no PR, still after the user approves. Outside a release, all changes to `develop` go through a PR.
- Claude may commit to a feature branch, following the steps in the plan, without asking.
- When all plan steps are complete, Claude generates a PR into the parent branch and notifies the user.
- When the user approves the PR, Claude squash-merges it and deletes the feature branch.
- GitHub branch protection backs this up: `main` strict, `develop` PR-required with admin bypass (set up by `new-project`).

## Skills

Built one at a time, in this order. Each is a Claude Code skill in `skills/<name>/` in this repo.

1. **start-feature:** from `develop`, pull latest, create and check out a feature branch named for the plan, push upstream if a remote exists.
2. **open-pr:** when the plan's steps are complete and verified, push the feature branch and create a PR into its parent branch with `gh`, with a generated description. Then notify the user.
3. **merge-pr:** only after the user says the PR is approved, squash-merge it with `gh`, delete the feature branch (remote and local), and update local `develop`.
4. **release:** from `develop`, with the user's approval at each commit, bump the version and update docs directly on `develop`, then open a PR from `develop` into `main`, and after approval merge it.

## Calls made by the author (not the user)

- "Notify the user" means a clear message in the session saying the PR is ready, with its URL, plus a push notification if that tool is available.
- Feature branch names are derived from the plan or spec name (for example `feature/<topic>`).
- The merge into `main` for a release uses the same approve-then-merge steps as `merge-pr`. Whether that merge is a squash is open (see below).
- The always-on rules are also written as a `## Git workflow` section in the `CLAUDE.md` that `new-project` generates, so they apply even when no git skill is loaded.

## Open

- Release details are not decided: versioning scheme, where the version lives (depends on the project's language), tagging, GitHub releases, changelog, and whether the `develop` to `main` merge is a squash or a merge commit. The `release` skill gets its own design discussion before it is built; the first three skills do not depend on it.
