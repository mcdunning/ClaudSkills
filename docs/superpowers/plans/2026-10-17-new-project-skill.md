# new-project Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `new-project` Claude Code skill and the `install.sh` that links this repo's skills into `~/.claude/skills/`.

**Architecture:** Deterministic work (empty detection, git/docs scaffolding, template merging, branch protection calls, installing) lives in small bash scripts that are unit-tested with plain bash tests. `SKILL.md` is the orchestration: it calls the scripts, asks the user the remote/visibility questions, and chains into planning or analysis. Exact-copy text lives in `templates/`.

**Tech Stack:** bash, git, GitHub `gh` CLI. No other dependencies.

**Spec:** `docs/superpowers/specs/2026-10-17-new-project-skill-design.md`

## Global Constraints

- Skill name is `new-project` (never `init`); lives at `skills/new-project/`.
- Never overwrite an existing file in the target directory; only add what is missing. Existing `docs/PROJECT_STATUS.md` is left untouched.
- Empty means nothing except `.git`, `README*`, `LICENSE*`, `.gitignore`; judged before any file is created.
- Branches are `main` and `develop`; `develop` is checked out afterwards.
- No language- or Flutter-specific text anywhere in templates.
- `PROJECT_STATUS.md` is exactly three paragraphs: no headings, no lists.
- `CLAUDE.md` header is exactly: `This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.` under a `# CLAUDE.md` title.
- Section headings: `## Working agreements`, `## Project status doc`; section added later for commands: `## Build, lint and test`.
- Remote creation defaults to private and requires user confirmation of name and visibility first; GitHub protection: `main` strict (PR required, applies to admins), `develop` PR required with admin bypass.
- Tests are plain bash under `tests/`; run all with `bash tests/run.sh`.

## Review Focus

- Target directory path contains spaces: scripts must quote paths (test in Task 3).
- `scaffold.sh` run twice in the same directory: second run changes nothing (Task 3).
- Directory already a git repo with commits, or already has a `develop` branch: no failure, no branch clobbering (Task 3).
- Existing `CLAUDE.md` with one of the two sections already present (different case): that section is not duplicated (Task 3).
- `gh` refuses protection (free plan, private repo): script reports it and exits 0 so setup continues (Task 4).
- Solo owner cannot approve their own PR on GitHub, so protection requires a PR but zero required approving reviews; the user's approval happens in the session (Task 4). Flag this to the user at handoff.

---

### Task 1: Test harness and `install.sh`

**Files:**
- Create: `tests/lib.sh`, `tests/run.sh`, `tests/test_install.sh`, `install.sh`

**Interfaces:**
- Produces: `tests/lib.sh` exposes `assert_eq <expected> <actual> <msg>`, `assert_file <path>`, `assert_no_file <path>`, `assert_contains <file> <text>`, `new_tmp` (prints a fresh temp dir, removed on exit), and `finish` (exits non-zero if any assertion failed). `tests/run.sh` runs every `tests/test_*.sh` and exits non-zero on any failure. `install.sh [target_dir]` links each `skills/*/` into `target_dir` (default `$HOME/.claude/skills`).

- [ ] **Step 1: Write the failing test** `tests/test_install.sh` using `new_tmp` for both a fake repo-root copy of `install.sh` with `skills/a`, `skills/b`, and a fake target. Tests: `links_every_skill_dir` (target/a and target/b are symlinks to the repo's skills); `rerun_is_idempotent` (second run exits 0, links unchanged); `refuses_real_directory` (a real dir `target/a` makes the run exit non-zero, its contents intact, `b` still linked).
- [ ] **Step 2: Run** `bash tests/run.sh`. Expected: FAIL, `install.sh` missing.
- [ ] **Step 3: Implement** `tests/lib.sh`, `tests/run.sh` and `install.sh`. The script resolves its own directory so it works from anywhere, creates the target if missing, replaces nothing that is not already the correct symlink, and reports each skipped or refused name.
- [ ] **Step 4: Run** `bash tests/run.sh`. Expected: all pass.
- [ ] **Step 5: Commit** `git add tests install.sh && git commit -m "feat: add install script and bash test harness"`

---

### Task 2: Templates

**Files:**
- Create: `skills/new-project/templates/CLAUDE.md`, `skills/new-project/templates/PROJECT_STATUS.md`, `tests/test_templates.sh`

**Interfaces:**
- Produces: `templates/CLAUDE.md` (title, header line, `## Working agreements`, `## Project status doc`) and `templates/PROJECT_STATUS.md` (three paragraphs), both copied byte-for-byte by Task 3.

- [ ] **Step 1: Write the failing test** `tests/test_templates.sh`. Tests: `status_is_three_paragraphs` (paragraphs separated by blank lines count to exactly 3; no line starts with `#`, `-`, `*` or a digit followed by `.`); `status_states_new_project` (contains "new project"); `claude_has_header_and_sections` (exact header sentence, both exact headings, the pasted bullet `Exactly three paragraphs: no headings, no lists, no more, no fewer.` present); `no_stack_specific_text` (neither file contains `flutter`, case-insensitive); `verification_sentence_generic` (CLAUDE.md contains `Verify against the code and the project's own analysis and test commands first`).
- [ ] **Step 2: Run** `bash tests/run.sh`. Expected: FAIL, templates missing.
- [ ] **Step 3: Write both templates** with the exact text in the spec's "`CLAUDE.md` content" and "`PROJECT_STATUS.md` initial content" sections (the pasted rules verbatim except the generic verification sentence; the three placeholder paragraphs as listed in the spec).
- [ ] **Step 4: Run** `bash tests/run.sh`. Expected: all pass.
- [ ] **Step 5: Commit** `git add skills tests && git commit -m "feat: add new-project templates"`

---

### Task 3: `scaffold.sh`

**Files:**
- Create: `skills/new-project/scripts/scaffold.sh`, `tests/test_scaffold.sh`

**Interfaces:**
- Consumes: Task 2 templates (located relative to the script, `../templates`).
- Produces: `scaffold.sh [target_dir]` (default `.`). First stdout line is `empty` or `non-empty` (judged before creating anything). Then it: runs `git init` if not a repo; ensures branches `main` and `develop` exist (creating an initial commit on `main` only when the repo has no commits, then `develop` from it); checks out `develop`; creates `docs/plans`, `docs/specs`; copies `PROJECT_STATUS.md` template only if `docs/PROJECT_STATUS.md` is absent; copies `CLAUDE.md` template if absent, otherwise appends only template sections whose `## ` heading is missing (case-insensitive exact match). Exit 0 on success. Never modifies any other file.

- [ ] **Step 1: Write the failing tests** in `tests/test_scaffold.sh`, each in a fresh temp dir: `empty_dir_reports_empty_and_scaffolds` (output line 1 is `empty`; `docs/plans`, `docs/specs`, `docs/PROJECT_STATUS.md`, `CLAUDE.md` exist; `git branch --list` shows `main` and `develop`; current branch is `develop`); `readme_license_gitignore_count_as_empty`; `source_file_makes_non_empty` (output `non-empty`, the source file byte-identical afterwards); `second_run_changes_nothing` (checksums of all non-`.git` files equal before and after); `existing_status_doc_untouched`; `existing_claude_md_gets_only_missing_sections` (file with `## working agreements` in lowercase plus custom text: custom text kept, `## Project status doc` appended, no duplicate working-agreements section); `path_with_spaces_works`; `existing_repo_with_commits_and_develop` (existing history and `develop` branch preserved, exit 0).
- [ ] **Step 2: Run** `bash tests/run.sh`. Expected: FAIL, script missing.
- [ ] **Step 3: Implement** `scaffold.sh` with `set -euo pipefail`, everything quoted. Section merge: split the template on lines beginning with `## `, and for each section test the target for a matching heading with `grep -qix`.
- [ ] **Step 4: Run** `bash tests/run.sh`. Expected: all pass.
- [ ] **Step 5: Commit** `git add skills tests && git commit -m "feat: add new-project scaffold script"`

---

### Task 4: `protect-branches.sh`

**Files:**
- Create: `skills/new-project/scripts/protect-branches.sh`, `tests/test_protect.sh`

**Interfaces:**
- Produces: `protect-branches.sh <owner/repo>`. Calls `gh api -X PUT repos/<owner/repo>/branches/<branch>/protection` for `main` and `develop` with a JSON body on stdin. `main`: `enforce_admins: true`. `develop`: `enforce_admins: false`. Both: `required_pull_request_reviews` with `required_approving_review_count: 0`, `required_status_checks: null`, `restrictions: null`. On any `gh` failure it prints `could not protect <branch>: <gh error>` and still exits 0.

- [ ] **Step 1: Write the failing tests** in `tests/test_protect.sh`, putting a stub `gh` first on `PATH` that appends its arguments and stdin to a log file and can be told to fail: `protects_both_branches` (log has PUT calls for exactly `main` and `develop` on the given repo); `main_enforces_admins_develop_does_not` (`"enforce_admins": true` in the main body, `false` in the develop body); `requires_pull_request_without_approval_count` (`"required_approving_review_count": 0` in both); `failure_is_reported_not_fatal` (stub exits 1: script exits 0 and output contains `could not protect main`).
- [ ] **Step 2: Run** `bash tests/run.sh`. Expected: FAIL, script missing.
- [ ] **Step 3: Implement** the script; build each JSON body with a heredoc, no `jq` dependency.
- [ ] **Step 4: Run** `bash tests/run.sh`. Expected: all pass.
- [ ] **Step 5: Commit** `git add skills tests && git commit -m "feat: add branch protection script"`

---

### Task 5: `SKILL.md` and end-to-end check

**Files:**
- Create: `skills/new-project/SKILL.md`, `tests/test_skill.sh`

**Interfaces:**
- Consumes: `scripts/scaffold.sh`, `scripts/protect-branches.sh`, both templates.

- [ ] **Step 1: Write the failing test** `tests/test_skill.sh`. Tests: `frontmatter_name_and_description` (first line `---`, `name: new-project`, description exactly the wording in the spec's Build details); `references_resolve` (every `scripts/...` and `templates/...` path mentioned in `SKILL.md` exists); `does_not_ask_language` (no instruction to ask the user for a language or test commands).
- [ ] **Step 2: Run** `bash tests/run.sh`. Expected: FAIL, `SKILL.md` missing.
- [ ] **Step 3: Write `SKILL.md`** as a numbered procedure: (1) run `scripts/scaffold.sh` on the current directory and read the first output line; (2) ask whether a GitHub remote exists or a new one should be made. Existing: ask for the URL, `git remote add origin`. New: confirm name and public/private (default private) with the user, then `gh repo create`; (3) after the user's confirmation, push `main` and `develop`; (4) run `scripts/protect-branches.sh` and relay any "could not protect" message; (5) `empty`: invoke `superpowers:brainstorming` (plain Q&A planning if absent); `non-empty`: scan manifests, top-level layout and a sample of source files without asking questions, record language and architecture in `CLAUDE.md` and write the findings into a new `PROJECT_STATUS.md` only when it was just created, listing anything undetermined in paragraph 3; (6) once the stack is known, add a `## Build, lint and test` section to `CLAUDE.md` and edit the verification sentence to point at it, and tell the user this step is still pending for an empty directory.
- [ ] **Step 4: Run** `bash tests/run.sh` and `bash install.sh`. Expected: all tests pass; `~/.claude/skills/new-project` is a symlink to `skills/new-project`.
- [ ] **Step 5: Manual smoke test (needs the user's approval before step c):** (a) in a scratch empty directory, invoke the skill and check the structure, branches and that planning starts; (b) in a scratch directory containing one source file, check that nothing existing changes and the scan result is recorded; (c) with the user's go-ahead, create a private test repo and confirm protection is applied (or reported as refused), then delete the test repo.
- [ ] **Step 6: Commit** `git add skills tests && git commit -m "feat: add new-project skill"`
