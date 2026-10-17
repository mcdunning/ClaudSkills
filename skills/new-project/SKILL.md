---
name: new-project
description: Use when the user wants to start, create, or set up a new project in the current directory, including an existing folder that has no project structure yet. Creates the git repo, GitHub remote, docs structure and CLAUDE.md, then plans or analyzes the project.
---

# new-project

Sets up the current directory as a project: git repo with `main` and `develop`, GitHub remote, `docs/`, `CLAUDE.md`, `docs/PROJECT_STATUS.md`. Resolve every `scripts/` and `templates/` path below from this skill's base directory (the directory containing this file), not from the project directory.

Never ask the user for a language, framework or test commands. Planning decides the stack for an empty directory; a scan discovers it for a non-empty one. Never overwrite or rewrite an existing file.

## Procedure

1. **Scaffold.** Run `bash scripts/scaffold.sh` with the project directory as the current directory. Read its first output line: `empty` or `non-empty`. This is judged before any file is created, so remember it for step 5. The script creates the git repo (`main` and `develop`, ending on `develop`), `docs/`, `docs/plans/`, `docs/specs/`, and copies `templates/CLAUDE.md` and `templates/PROJECT_STATUS.md` only where missing. Copy templates; do not retype them.

2. **Remote.** Ask whether a GitHub remote already exists or a new one should be made.
   - Existing: ask for the URL and run `git remote add origin <url>`.
   - New: creating the remote and pushing publish the project's files, so first confirm the repo name and public or private with the user (default private). Only after that confirmation run `gh repo create`.

3. **Push.** Pushing publishes files. After the user has confirmed (step 2 counts for a new repo; for an existing remote, confirm before pushing), push `main` and `develop`. Leave `develop` checked out.

4. **Protect branches.** Run `bash scripts/protect-branches.sh <owner/repo>`. It requires a pull request for `main` (admins included) and `develop` (admins may bypass). Approval count is 0 because a solo owner cannot approve their own PR. If any line says "could not protect", relay that message to the user (for example a private repo on the free plan) and continue; this is not fatal.

5. **Plan or learn**, by the result from step 1.
   - `empty`: invoke the `superpowers:brainstorming` skill to plan the project and choose the stack. If that skill is not installed, run a plain question-and-answer planning conversation instead.
   - `non-empty`: do an autonomous, bounded scan without asking questions: manifests, top-level layout, and a small sample of source files. Record the language and architecture found in `CLAUDE.md`. Write the findings into `docs/PROJECT_STATUS.md` only if it was just created by step 1 (three paragraphs, no headings or lists, facts only; list anything the scan could not determine in paragraph 3). If it already existed, leave it untouched. Do not modify existing project files.

6. **Record commands.** Once the stack is known, add a `## Build, lint and test` section to `CLAUDE.md` with the real build, lint and test commands, and edit the verification sentence in the status-doc rules to point at that section. For an empty directory the stack is not known yet; tell the user this step is still pending and must happen after planning.
