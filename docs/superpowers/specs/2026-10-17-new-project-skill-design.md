# `new-project` skill: design

## Intent

The user starts many projects in different languages and is tired of repeating the same setup ceremony each time. `new-project` is a Claude Code skill that does that setup in one step and leaves every project with the same handoff structure, so any session or engineer can pick it up.

This repository (`ClaudSkills`) holds the user's skills. `new-project` is the first. The skill should be placed in this repo and be installable to wherever Claude Code loads personal skills from (the builder should check the right location; `~/.claude/skills` exists).

## Goals

- One invocation produces a ready project skeleton: git repo, `docs/`, `CLAUDE.md`.
- Every project gets the same working agreement and project-status rules, so handoff docs behave identically across projects.
- Language-agnostic: the skill never asks which language or stack.
- Works in an empty directory (starts planning) and in a non-empty one (learns the existing project).

## Non-goals

- Scaffolding language-specific files (package manifests, build config, source).
- Day-to-day git workflow (feature branches, PRs, merging, releases). These are separate skills, see `2026-10-17-git-flow-skills-design.md`. `new-project` only creates the branches, the remote and the protection they rely on.
- Overwriting or restructuring any file that already exists in a non-empty directory.

## Anti-goals

- Asking the user for a language, framework, or test commands during setup.
- Putting Flutter-specific commands (`flutter analyze`, `flutter test`) into projects that are not Flutter.
- Leaving a `PROJECT_STATUS.md` that breaks its own rules (it must be exactly three paragraphs, with no headings or lists).

## Behavior

The skill is named `new-project` (not `init`, which is the built-in codebase-analysis command).

1. **Create the structure** in the current directory:
   - `git init` (skip if already a repo), with `main` and `develop` branches. `develop` is the working branch afterwards.
   - **GitHub remote:** ask the user whether a remote repo already exists or a new one should be made. Existing: ask for the URL and add it as `origin`. New: confirm the repo name and public/private with the user (private is the default), then create it with the `gh` CLI. Then push `main` and `develop`.
   - **Branch protection** (only when a remote exists): protect `main` (PR with approval required, no bypass) and `develop` (PR with approval required, repo admin may bypass). If GitHub refuses (for example a private repo on the free plan), tell the user and continue without protection.
   - `docs/PROJECT_STATUS.md`, `docs/plans/`, `docs/specs/`.
   - `CLAUDE.md` with the standard header line ("This file provides guidance to Claude Code...") followed by the sections below.
   - If any of these already exist, leave them alone and add only what is missing. For an existing `CLAUDE.md`, add the missing sections rather than replacing the file.
2. **Branch on directory contents** (judged before step 1 creates files):
   - **Empty:** start a planning session using the brainstorming skill. That session decides language and architecture.
   - **Not empty:** read the existing code to determine language and architecture, then record what was found in `CLAUDE.md` and in `PROJECT_STATUS.md`. Do not modify existing project files.
3. **After planning or the context scan identifies the stack,** record the actual build, lint and test commands in `CLAUDE.md`, and use them as the "verify" commands the status-doc rules refer to.

## `CLAUDE.md` content

After the header, two sections, taken verbatim from the user's text below, with one change: the verification sentence must not name Flutter. It reads "Verify against the code and the project's own analysis and test commands first" until real commands are recorded in step 3.

The first section is headed `## Working agreements` (the user called it "Working Agreement"; the user's pasted heading is used as written):

> Rules, preferences, and "remember this" items from the user go in the project files (this `CLAUDE.md`, or `docs/` where it is reference material), not only in personal auto-memory, so anyone can pick the project up and continue. When the user gives a new rule or marks something to be remembered, write it here in the same change.

The second section is `## Project status doc`:

> `docs/PROJECT_STATUS.md` is the read-first handoff for new sessions and engineers. After significant work (finishing a feature, merging a PR, resolving a major issue), rewrite it entirely. Never append a history log. Rules:
>
> - Exactly three paragraphs: no headings, no lists, no more, no fewer.
> - Facts only: no assumptions, theories, or speculation about why something happened or what might be true. Verify against the code, the project's analysis command and its test command first.
> - Written as instructions to another developer, as if the document were the only context they get.
> - Paragraph 1: what was done and the current state of the project.
> - Paragraph 2: files updated/created, mistakes to avoid, key insights/lessons learned.
> - Paragraph 3: current problems/errors/open items, and anything else needed to work productively (setup requirements, what's unverified, what's not started).
> - In the same change, check `README.md` and everything under `docs/` for stale mentions of a feature's old status and fix them without being asked. Exclude plans: implementation plans are point-in-time instructions, not living reference docs.

## `PROJECT_STATUS.md` initial content

Exactly three paragraphs that obey the rules above, stating that this is a new project:

1. The project was just created from the `new-project` skill; the directory structure, git repository and `CLAUDE.md` exist; nothing else has been done.
2. Files created: `CLAUDE.md`, `docs/PROJECT_STATUS.md`, `docs/plans/`, `docs/specs/`. Mistake to avoid: do not append to this file; rewrite it whole after significant work.
3. Open items: language, architecture, and build/test commands are not yet decided or recorded; no code exists; nothing is verified.

For a non-empty directory, paragraph 1 states what was found (language, architecture) instead, and paragraph 3 lists anything the scan could not determine.

## Decided by the user

- Skill name: `new-project`.
- Initial status doc: three-paragraph placeholder that says it is a new project.
- Git: the project is initialized as a git repository with `main` and `develop`, a GitHub remote (existing or newly created, user is asked), and both branches pushed.
- Branch protection is turned on: `main` strict, `develop` with admin bypass.
- Language is never asked at creation; planning decides it for empty directories, and a scan discovers it for non-empty ones.
- Empty directory triggers a planning session.

## Calls made by the author (not the user)

- The planning session uses the brainstorming skill.
- Verification commands are written generically until the stack is known, then recorded in `CLAUDE.md`.
- Existing files are never overwritten.
- Git workflow rules are out of scope and will be a separate skill.
- Section heading wording follows the user's pasted text.
- The skill invokes `superpowers:brainstorming` directly for an empty directory. If that skill is not installed, it runs a plain question-and-answer planning conversation instead.
- The non-empty scan is bounded (manifests, top-level layout, a sample of source files) and autonomous: it does not ask the user questions. Anything it cannot determine goes in paragraph 3 of `PROJECT_STATUS.md`.
- Existing files are never rewritten. An existing `docs/PROJECT_STATUS.md` is left untouched and the scan findings go only into `CLAUDE.md`. For an existing `CLAUDE.md`, a section counts as missing when no heading matches it exactly (case-insensitive); only missing sections are appended.
- "Empty" means nothing except `.git`, `README*`, `LICENSE*` and `.gitignore`.
- Recorded commands go in a new `## Build, lint and test` section of `CLAUDE.md`, and the verification sentence in the status-doc rules is edited to point at that section.
- The header is the standard wording: "This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository."
- For an empty directory, step 3 happens after planning, outside the skill's own run. The initial status doc's open items and a note in `CLAUDE.md` remind the next session to record the commands once the stack is chosen.
- The skill lives at `skills/new-project/` in this repo and is installed by symlinking it into `~/.claude/skills/`; an install script is optional.

## Build details (author's calls)

- **Layout:** `skills/new-project/SKILL.md` holds the procedure. The text that must be reproduced exactly lives in separate files beside it: `skills/new-project/templates/CLAUDE.md` (header plus the two sections, with the generic verification sentence) and `skills/new-project/templates/PROJECT_STATUS.md` (the three-paragraph new-project placeholder). `SKILL.md` tells Claude to copy them rather than retype them.
- **Frontmatter:** `name: new-project`. The description reads: "Use when the user wants to start, create, or set up a new project in the current directory, including an existing folder that has no project structure yet. Creates the git repo, GitHub remote, docs structure and CLAUDE.md, then plans or analyzes the project." It must not trigger for the built-in `/init`.
- **Empty detection:** as defined in the author's calls above. Check the directory before creating any files.
- **Install:** a script `install.sh` at the repo root symlinks every directory under `skills/` into `~/.claude/skills/`, skipping any that already link correctly and refusing to overwrite a real directory of the same name. It is safe to re-run, and later skills in this repo are installed by the same script.
