# Abyssal Signal

Hoplite-scale cosmic horror roguelike. Solo investigator on small hex grids, turn-based, deterministic enemy behaviors, 10-15 minute runs. Core mechanic: spending sanity grants power but degrades battlefield information.

## Tech Stack

- **Engine:** Godot 4.x (GDScript)
- **Target:** Steam (desktop)
- **Art:** AI-generated tile sprites (PixelLab or equivalent)
- **Audio:** TBD

## Repo Structure

- `openspec/` — behavioral specs and active changes (initialize after spikes complete)
- `docs/` — architecture decisions, design references, integration guides
- `DECISIONS.md` — project-level technical decisions with reasoning
- `SESSION.md` — context recovery bookmark (overwritten each session)

## Core Design Constraints

- **Scope ceiling:** 1 character, 5-8 enemy types, 3-5 abilities per run, 3 sanity thresholds, 1 tileset. No meta-progression in v1.
- **Grid:** Hex grid, ~7 radius. Small enough for perfect-information reasoning at full sanity.
- **Sanity mechanic:** Sanity is a single bar. Spending it activates powerful abilities. As it drops past thresholds, the game changes: enemy telegraphing degrades, corrupted tiles appear, new chaotic abilities unlock. Low sanity is not death — it's a different, harder game.
- **Enemies:** Deterministic behaviors. At full sanity, the player can reason about every move (Hoplite model). Sanity degradation introduces controlled uncertainty.
- **Runs:** ~10-15 minutes. Multiple floors, each a self-contained tactical encounter. Reach the exit to descend.

## Development Constraints

- Solo dev, 8 hours/week. Every feature must justify its complexity.
- Agentic development: Claude Code writes GDScript, AI generates art assets. Lean into what agents do well (data-driven systems, state machines, procedural generation) and avoid what they struggle with (nuanced animation, subjective "feel" tuning).
- **No premature polish.** Programmer art and colored shapes until the mechanics are validated.
- **Ship fast.** Target: playable prototype in 4 sessions, Steam-ready in 3-6 months.

## Key Patterns

- Turn-based game loop: player input → resolve player action → enemy AI → resolve enemy actions → check win/loss → next turn
- Hex grid uses axial coordinates (q, r). Reference: Red Blob Games hex guide.
- Entity data (enemies, abilities, items) should be data-driven (JSON/Resource files), not hardcoded. This makes balancing and content addition cheap.
- Sanity thresholds are config-driven: each threshold defines what changes (visibility rules, new tile types, ability unlocks).

## What NOT to Do

- Don't add systems not in the scope ceiling without explicit approval.
- Don't optimize prematurely — correctness and playability first.
- Don't create custom art assets — use colored shapes or placeholder sprites until art pipeline is validated.
- Don't implement meta-progression, save systems, or Steam integration until core loop is proven fun.