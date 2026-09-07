# Gravity

A cozy-scale reimagining of *Gravity* (Image Works, 1990) — the Atari ST isometric action/strategy game built around black-hole travel and space colonisation. Not affiliated with the original publisher; this is a personal, fan-inspired project exploring the same core hook with modern tooling.

## Status

🚧 Early development. Web export pipeline confirmed working; core mechanics not yet implemented.

## Built with

- **[Godot 4.6](https://godotengine.org/)** — GDScript, targeting Web (HTML5) as the primary export platform
- **[Claude Code](https://claude.com/product/claude-code)** via the Godot MCP server, for AI-assisted development
- Version control via Git/GitHub, Issues + Milestones for planning

## Getting started

1. Install [Godot 4.6](https://godotengine.org/download), standard (non-Mono) build
2. Clone this repo and open `project.godot` in the Godot editor
3. Export templates (Web) need to be installed once via **Editor > Manage Export Templates**
4. Use **Remote Debug > Run in Browser** to playtest locally

## Roadmap

Development is planned in four tiers, each its own GitHub Milestone. Later tiers aren't started until earlier ones are solid.

### Foundation
- Ship movement, thrust, and gravity
- Black hole travel, including the ship-time/calendar-time split
- 3D cube star map and navigation

### World
- StarCom orders
- Planetary systems, star/planet classes
- Colonisation and tech levels

### Fleet & Conflict
- Fleet mechanics
- Ship propulsion and weapons
- Damage control
- The Outies (opposing faction) and combat

### Endgame
- Terraforming, star formation/collapse
- Victory and loss conditions

## Development workflow

- One GitHub Issue per mechanic, each with a "done when" definition, assigned to its tier's Milestone
- One branch per issue (`<issue-number>-<short-name>`), merged to `main` once playable and stable
- `/devlog` — dated session notes, one line on what was built and what's next
