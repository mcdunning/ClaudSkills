# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working agreements

Rules, preferences, and "remember this" items from the user go in the project files (this `CLAUDE.md`, or `docs/` where it is reference material), not only in personal auto-memory, so anyone can pick the project up and continue. When the user gives a new rule or marks something to be remembered, write it here in the same change.

## Project status doc

`docs/PROJECT_STATUS.md` is the read-first handoff for new sessions and engineers. After significant work (finishing a feature, merging a PR, resolving a major issue), rewrite it entirely. Never append a history log. Rules:

- Exactly three paragraphs: no headings, no lists, no more, no fewer.
- Facts only: no assumptions, theories, or speculation about why something happened or what might be true. Verify against the code and the project's own analysis and test commands first.
- Written as instructions to another developer, as if the document were the only context they get.
- Paragraph 1: what was done and the current state of the project.
- Paragraph 2: files updated/created, mistakes to avoid, key insights/lessons learned.
- Paragraph 3: current problems/errors/open items, and anything else needed to work productively (setup requirements, what's unverified, what's not started).
- In the same change, check `README.md` and everything under `docs/` for stale mentions of a feature's old status and fix them without being asked. Exclude plans: implementation plans are point-in-time instructions, not living reference docs.
