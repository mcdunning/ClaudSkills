---
name: new-project
description: Use when the user wants to start, create, or set up a new project in the current directory, including an existing folder that has no project structure yet. Creates the git repo, GitHub remote, docs structure and CLAUDE.md, then plans or analyzes the project.
---

# new-project

Sets up the current directory as a project: git repo with `main` and `develop`, GitHub remote, `docs/`, `CLAUDE.md`, `docs/PROJECT_STATUS.md`.

`<skill-base-dir>` means the directory containing this SKILL.md. Scripts and templates live under it (`scripts/`, `templates/`). Always call them by that full path, as in the commands below. Run every command with the project directory (the user's current directory) as the working directory.

Never ask the user for a language, stack or test commands.
Planning decides the stack for an empty directory; a scan discovers it for a non-empty one. Never overwrite or rewrite an existing file. The only change to an existing `CLAUDE.md` is appending new sections (see steps 5 and 6).

## Procedure

1. **Scaffold.** Run `bash "<skill-base-dir>/scripts/scaffold.sh"`. If it exits non-zero it prints a one-line reason (for example the directory is inside another git repository but is not its top level); nothing was created. Relay the reason and ask the user how to proceed (for example a different directory); never push or publish a parent repository. Otherwise read its first output line: `empty` or `non-empty`. This is judged before any file is created, so remember it for step 5. The script creates the git repo (`main` and `develop`, ending on `develop`), `docs/`, `docs/plans/`, `docs/specs/`, and copies `templates/CLAUDE.md` and `templates/PROJECT_STATUS.md` only where missing. Copy templates; do not retype them.

2. **Remote.** Ask whether a GitHub remote already exists or a new one should be made.
   - Existing: get the URL from the user and run `git remote add origin <url>`.
   - New: creating the remote and pushing publish the project's files. First confirm the repo name and public or private with the user (default private).
   - After that confirmation, run `gh repo create <name> --private --source=. --remote=origin` (use `--public` if the user chose public). Do not pass `--push`; push in step 3.

3. **Push.** Pushing publishes the project's files.
   - New repo: the confirmation in step 2 covers it.
   - Existing remote: before pushing, confirm with the user the remote URL and that the project files will be published.
   Then run `git push -u origin main develop` and leave `develop` checked out.

4. **Protect branches.** Get the repo with `gh repo view --json nameWithOwner -q .nameWithOwner` (works for new and existing remotes), then run `bash "<skill-base-dir>/scripts/protect-branches.sh" <owner/repo>`. It requires a pull request for `main` (admins included) and `develop` (admins may bypass). Approval count is 0 because a solo owner cannot approve their own PR. If any output line says "could not protect", relay that message to the user (for example a private repo on the free plan) and continue; this is not fatal.

5. **Plan or learn**, by the result from step 1.
   - `empty`: invoke the `superpowers:brainstorming` skill to plan the project and choose the stack. If that skill is not installed, run a plain question-and-answer planning conversation instead.
   - `non-empty`: scan on your own, bounded to manifests, top-level layout and a small sample of source files; put no questions to the user. Append the language and architecture found to `CLAUDE.md` as a new section (never edit existing text). Write the findings into `docs/PROJECT_STATUS.md` only if step 1 just created it (three paragraphs, no headings or lists, facts only; list anything undetermined in paragraph 3). If it already existed, leave it untouched. Do not modify other existing project files.

6. **Record commands.** Once the stack is known (for `non-empty`, right after step 5 completes), append a `## Build, lint and test` section to `CLAUDE.md` with the real build, lint and test commands. Then, only if `CLAUDE.md` still contains this exact sentence in its "Project status doc" section (from `templates/CLAUDE.md`): "Verify against the code and the project's own analysis and test commands first", edit it to point at the new section. If the sentence is absent (for example an existing `CLAUDE.md`), skip that edit and tell the user it was skipped. For `empty` the stack is not known yet; tell the user this step is still pending and must happen after planning.
