# CLAUDE.md

Project instructions for Claude Code working in this repo. Full project overview, inspiration, and roadmap: see README.md.

## Stack

- Godot 4.6, standard (non-Mono) build — GDScript only, no C#
- Primary export target: Web (HTML5)
- Godot MCP server (`@coding-solo/godot-mcp`) is connected — use its tools to launch the editor, run the project, and manage scenes/nodes directly rather than just describing changes for a human to make by hand

## Workflow

- One GitHub Issue per mechanic, each assigned to a Milestone (Foundation, World, Fleet & Conflict, Endgame — see README.md for what's in each)
- Work one issue at a time. Branch as `<issue-number>-<short-name>`, off `main`
- Each issue has a "done when" checklist in its body — treat that as the spec and the stopping point. Don't expand scope beyond it without flagging it first
- Merge to `main` only once the issue is playable and stable — that merge point is the rollback net for future sessions
- Add one line to a dated file in `/devlog` at the end of each session: what got built, what's next

## Current focus

Issue #1 — Ship movement (thrust and gravity), Foundation milestone. No black holes, star map, UI, or art yet — just a single ship responding correctly to thrust, momentum, and one placeholder gravity source. See the issue body for the full "done when" list.

## Notes

- Don't touch World / Fleet & Conflict / Endgame mechanics until Foundation is closed out
- Test via Run in Browser (Web export) where practical, not just the desktop editor's Play button
