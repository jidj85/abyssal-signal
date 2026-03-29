# Decisions

Project-level technical and design decisions with context. Per-change decisions live in each OpenSpec change's `design.md`.

---

## 001 — Game scope: Hoplite-scale, not FFT-scale

**Date:** 2026-03-28
**Context:** Cosmic Tactics opportunity assessment (v3 Final) came back No-Go. Primary blockers: unknown developer capability, 5+ year timeline at 8hr/week, unproven audience intersection. Assessment recommended shipping something smaller first.
**Options Considered:**
1. Full FFT-scale tactical roguelite (Cosmic Tactics as originally conceived)
2. Hoplite-scale roguelike — single character, small grid, deterministic enemies, short runs
3. Deckbuilder or puzzle game (different genre entirely)
**Decision:** Option 2. Hoplite-scale roguelike that tests the sanity-as-positioning mechanic from Cosmic Tactics at minimal scope.
**Reasoning:** Teaches transferable game dev skills (grid systems, proc-gen, state machines, Steam shipping). Directly validates the core novel mechanic. Small enough to ship in 3-6 months at 8hr/week. If the mechanic works, it informs a future return to Cosmic Tactics.
**Risk:** The sanity-as-information-degradation mechanic might fight Hoplite's perfect-information model rather than complement it. Spike 2 will test this.

---

## 002 — Engine: Godot 4.x with GDScript (confirmed)

**Date:** 2026-03-28
**Context:** Need a game engine for a 2D hex-grid turn-based roguelike. Developer is a generalist programmer with no prior game engine experience. Development will rely heavily on Claude Code writing engine code.
**Options Considered:**
1. Godot 4.x with GDScript — free, strong 2D, Python-like syntax, exports to Steam
2. Godot 4.x with C# — familiar to some devs, but GDScript has better Godot ecosystem support
3. Unity with C# — industry standard, heavy for a tile-based game, licensing concerns
4. Web-based (Phaser/custom) — fastest to prototype, harder to ship on Steam
**Decision:** Godot 4.x with GDScript, confirmed.
**Reasoning:** Free and open source. Excellent 2D support. GDScript is approachable for a generalist programmer. Clean Steam export pipeline. Strong community and documentation. The unknown is whether Claude Code can write GDScript productively — Spike 1 will answer this.
**Risk:** If Claude Code struggles with GDScript (poor code quality, constant errors, slow iteration), will reconsider Godot with C# or a different engine. Decision point: end of Spike 1.

---

## 003 — Core mechanic: sanity-as-information-degradation

**Date:** 2026-03-28
**Context:** The Cosmic Tactics assessment identified sanity-as-positioning as a genuinely novel mechanic that no shipped game implements. Need to decide what the core differentiator is for this smaller game.
**Options Considered:**
1. Standard roguelike (no sanity mechanic) — pure Hoplite clone with horror theme
2. Sanity as health (lose sanity, die) — simplest, but not interesting
3. Sanity as information degradation — spend sanity for power, lose battlefield clarity
4. Sanity as unit control (units go rogue) — interesting but requires multiple units, breaks Hoplite scale
**Decision:** Option 3. Sanity-as-information-degradation.
**Reasoning:** Creates the push-your-luck tension: "Do I play safe with full info, or burn sanity for a powerful ability and accept degraded clarity?" This is the smallest testable version of the Cosmic Tactics concept. Doesn't require multiple units. Creates a spectrum of play styles within a single run.
**Risk:** Information degradation may feel punishing rather than interesting. If players always play at full sanity because losing info is too costly, the mechanic fails. If they always burn sanity because the abilities are too strong, it also fails. Tuning window may be narrow. Spike 2 will test this.

---

## 004 — Art approach: AI-generated tiles, deferred until mechanics validated

**Date:** 2026-03-28
**Context:** Horror games depend heavily on art for atmosphere. AI art tools (PixelLab) can generate isometric sprites. But art consistency for cosmic horror is high-risk.
**Options Considered:**
1. Commission artist from day 1
2. AI-generated art from day 1
3. Programmer art / colored shapes for spikes, AI art pipeline spike later
**Decision:** Option 3. No art investment until core mechanics are validated.
**Reasoning:** The Cosmic Tactics assessment rated horror art as HIGH risk. But at Hoplite scale (8-12 entity types), the asset count is small enough that AI art becomes feasible. Deferring art keeps focus on the mechanic question. A separate art pipeline spike will test whether AI can produce consistent cosmic horror tiles before committing.
**Risk:** If AI art can't produce the atmosphere, the game loses its horror identity and becomes a generic roguelike. At that point, either commission an artist or pivot the theme.