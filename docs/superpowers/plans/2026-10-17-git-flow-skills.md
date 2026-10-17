# Git Flow Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `start-feature`, `open-pr` and `merge-pr` skills, and add the always-on `## Git workflow` section to the `new-project` CLAUDE.md template.

**Architecture:** Each skill is a `SKILL.md` that orchestrates a small bash script holding the deterministic git/`gh` work. The scripts are tested with plain bash against temporary git repos with a local bare `origin` and a stub `gh` on `PATH`. The skills hold the judgment steps (is the plan complete, did the user approve, notify the user).

**Tech Stack:** bash, git, GitHub `gh` CLI.

**Spec:** `docs/superpowers/specs/2026-10-17-git-flow-skills-design.md`

**Depends on:** `docs/superpowers/plans/2026-10-17-new-project-skill.md` being executed first. This plan reuses `tests/lib.sh`, `tests/run.sh`, `install.sh` and `skills/new-project/templates/CLAUDE.md` from it.

**Out of scope:** the `release` skill. Its design is still open (versioning, tagging, changelog, squash vs merge commit); it gets its own design discussion and plan.

## Global Constraints

- Hosts: GitHub only, via `gh`.
- Feature branches are named `feature/<slug>` and branch from `develop`; PRs target `develop`.
- Merges into `develop` are squash merges; the feature branch is deleted (remote and local) after merge.
- Claude never commits or merges to `main` or `develop` without the user's explicit approval for that action in the current session; `merge-pr` must not run on an unstated or assumed approval.
- Claude may commit freely on a feature branch following the plan.
- "Notify the user" is a clear session message containing the PR URL, plus a push notification if that tool is available.
- No script modifies anything outside the repository it is run in, and every path/argument is quoted.
- Tests are plain bash under `tests/`; `bash tests/run.sh` runs them all.

## Review Focus

- Working tree has uncommitted changes when starting a feature: refuse, change nothing (Task 2).
- Topic text with spaces, capitals or punctuation: becomes a clean lowercase slug (Task 2).
- `start-feature` run when `feature/<slug>` already exists locally or remotely: refuse, no branch moved (Task 2).
- Repo has no `origin` (local only): `start-feature` still works; `open-pr` stops with a clear message (Tasks 2, 3).
- `open-pr` run on `develop` or `main` instead of a feature branch: refuse (Task 3).
- `merge-pr` given a PR whose base is not `develop`, or that is not approved by the user in the session: refuse; never merge to `main` (Task 4).
- Local feature branch already gone when cleaning up after merge: not an error (Task 4).

---

### Task 1: `## Git workflow` section in the `CLAUDE.md` template

**Files:**
- Modify: `skills/new-project/templates/CLAUDE.md`, `tests/test_templates.sh`

**Interfaces:**
- Produces: a third section `## Git workflow` after `## Project status doc`, picked up automatically by `scaffold.sh`'s missing-section merge.

- [ ] **Step 1: Write the failing test** in `tests/test_templates.sh`: `claude_has_git_workflow_section` asserts the heading `## Git workflow` and these exact phrases: `Never commit directly to main`, `develop`, `feature/`, `squash`, `approval`.
- [ ] **Step 2: Run** `bash tests/run.sh`. Expected: FAIL.
- [ ] **Step 3: Add the section** to the template as short bullets stating the Rules list from the spec (no direct commits to `main`; `main` changes only by PR and formal release; `develop` is the running branch; feature branches off and back into `develop`, squashed; every commit to `main`/`develop` needs the user's approval each time; version bumps and doc updates may go straight to `develop` only during a release and still need approval; Claude commits freely on feature branches following the plan; when plan steps are done, open a PR and notify the user; after the user approves, squash-merge and delete the branch).
- [ ] **Step 4: Run** `bash tests/run.sh`. Expected: all pass, including the existing scaffold tests.
- [ ] **Step 5: Commit** `git add skills tests && git commit -m "feat: add git workflow rules to new-project template"`

---

### Task 2: `start-feature`

**Files:**
- Create: `skills/start-feature/SKILL.md`, `skills/start-feature/scripts/start-feature.sh`, `tests/test_start_feature.sh`

**Interfaces:**
- Produces: `start-feature.sh <topic>` run inside a repo. Prints the created branch name `feature/<slug>` as its last stdout line. `<slug>` is the topic lowercased, runs of non-alphanumerics collapsed to `-`, trimmed of leading/trailing `-`. Steps: fail if the working tree is dirty; check out `develop`; `git pull --ff-only` if `origin` exists; fail if `feature/<slug>` exists locally or on `origin`; create and check out the branch; `git push -u origin` it if `origin` exists. Non-zero exit with a one-line reason on any refusal.

- [ ] **Step 1: Write the failing tests** in `tests/test_start_feature.sh`, with helper `make_repo` creating a repo with `main`, `develop` and, optionally, a bare local `origin`: `creates_branch_from_develop` (branch exists, checked out, its parent commit equals `develop`'s tip); `slugs_topic` (input `Add  Login Page!` gives `feature/add-login-page`); `refuses_dirty_tree` (exit non-zero, still on original branch); `refuses_existing_branch` (local and remote variants); `works_without_origin`; `pulls_latest_develop_first` (a commit pushed to `origin/develop` by a second clone is in the new branch); `pushes_upstream` (branch exists on `origin` and tracks it).
- [ ] **Step 2: Run** `bash tests/run.sh`. Expected: FAIL, script missing.
- [ ] **Step 3: Implement** `start-feature.sh` (`set -euo pipefail`).
- [ ] **Step 4: Write `SKILL.md`** with the trigger description "Use when starting implementation of a plan or spec and work needs a feature branch off develop", telling Claude to derive the topic from the plan or spec name, run the script, and report the branch name; add a test `skill_frontmatter_and_script_path` to the same test file asserting name `start-feature` and that the referenced script exists.
- [ ] **Step 5: Run** `bash tests/run.sh`. Expected: all pass.
- [ ] **Step 6: Commit** `git add skills tests && git commit -m "feat: add start-feature skill"`

---

### Task 3: `open-pr`

**Files:**
- Create: `skills/open-pr/SKILL.md`, `skills/open-pr/scripts/open-pr.sh`, `tests/test_open_pr.sh`

**Interfaces:**
- Produces: `open-pr.sh <title> <body_file>` run inside a repo on a `feature/*` branch. Fails if the branch does not start with `feature/`, the tree is dirty, or there is no `origin`. Pushes the branch (`git push -u origin <branch>`), runs `gh pr create --base develop --head <branch> --title <title> --body-file <body_file>`, and prints the PR URL as its last stdout line.

- [ ] **Step 1: Write the failing tests** in `tests/test_open_pr.sh` using the bare `origin` and a stub `gh` that logs its arguments and prints a fake URL: `creates_pr_into_develop` (log shows `--base develop`, the head branch, the title and body file; last output line is the URL); `pushes_branch_first` (branch present on `origin`); `refuses_on_develop_and_main`; `refuses_dirty_tree`; `refuses_without_origin` (message mentions adding a remote); `skill_frontmatter_and_script_path`.
- [ ] **Step 2: Run** `bash tests/run.sh`. Expected: FAIL.
- [ ] **Step 3: Implement** `open-pr.sh`.
- [ ] **Step 4: Write `SKILL.md`**, description "Use when all steps of a plan on a feature branch are complete and the work should be reviewed". Procedure: confirm every plan step is done and the project's verification commands pass (stop and report if not); write a PR body to a temp file (summary of the change, how it was verified, link to the plan/spec); run the script; notify the user per the Global Constraints; stop. Claude does not merge.
- [ ] **Step 5: Run** `bash tests/run.sh`. Expected: all pass.
- [ ] **Step 6: Commit** `git add skills tests && git commit -m "feat: add open-pr skill"`

---

### Task 4: `merge-pr`

**Files:**
- Create: `skills/merge-pr/SKILL.md`, `skills/merge-pr/scripts/merge-pr.sh`, `tests/test_merge_pr.sh`

**Interfaces:**
- Produces: `merge-pr.sh <pr_number>`. Reads the PR's base and head with `gh pr view <n> --json baseRefName,headRefName`. Refuses unless the base is `develop` and the head starts with `feature/`. Runs `gh pr merge <n> --squash --delete-branch`, then checks out `develop`, `git pull --ff-only`, and deletes the local head branch if it still exists. Exit non-zero with a one-line reason on any refusal.

- [ ] **Step 1: Write the failing tests** in `tests/test_merge_pr.sh` with a stub `gh` that serves canned `pr view` JSON and logs calls: `squash_merges_and_deletes_branch` (log has `pr merge 12 --squash --delete-branch`); `refuses_base_main` and `refuses_non_feature_head` (no `pr merge` call logged); `cleans_up_local_branch_and_updates_develop`; `missing_local_branch_is_not_an_error`; `skill_frontmatter_and_script_path`.
- [ ] **Step 2: Run** `bash tests/run.sh`. Expected: FAIL.
- [ ] **Step 3: Implement** `merge-pr.sh`.
- [ ] **Step 4: Write `SKILL.md`**, description "Use when the user has approved a feature PR and it should be merged". Procedure: proceed only if the user has said, in this session, that this PR is approved (otherwise ask and stop); run the script; report the result and that `develop` is updated. State plainly that merging to `main` is never done by this skill.
- [ ] **Step 5: Run** `bash tests/run.sh`, then `bash install.sh`. Expected: all pass; `~/.claude/skills/{start-feature,open-pr,merge-pr}` are symlinks.
- [ ] **Step 6: Manual smoke test (needs the user's approval first):** in a scratch private GitHub repo made by `new-project`, run start-feature, make a trivial commit, run open-pr, approve it, run merge-pr; confirm `develop` has one squashed commit and the branch is gone; delete the scratch repo.
- [ ] **Step 7: Commit** `git add skills tests && git commit -m "feat: add merge-pr skill"`
