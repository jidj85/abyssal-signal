## Why

Both validation spikes passed: the hex grid engine works (Spike 1) and the sanity-as-information-degradation mechanic creates interesting decisions (Spike 2). The spike code is a monolithic proof-of-concept (~520 lines in one script, hardcoded enemies/positions, no floor progression, no health system). This change builds the real v1 game loop on top of validated foundations — refactoring spike code into a proper architecture and implementing all systems needed for a complete 10-15 minute run.

Discovery reference: https://www.notion.so/3328031c55bd8197afd6ff98da4ca9e7
Go decision: https://www.notion.so/3328031c55bd8195bd2ffbca68765b92

## What Changes

- **Refactor spike monolith** into separated systems: grid management, entity management, turn controller, sanity system, UI layer
- **Turn-based game loop**: player input → resolve player action → enemy AI → resolve enemy actions → check win/loss → next turn. Formalized as a state machine rather than ad-hoc flags
- **Entity system**: data-driven enemy definitions (Resource files) with deterministic behavior patterns. 5-8 enemy types replacing the single "chase" enemy
- **Sanity system**: extracted into its own system with config-driven thresholds that modify visibility rules, tile effects, and ability availability
- **Ability system**: 3-5 abilities that cost sanity, replacing the hardcoded Eldritch Step and Void Pulse. Abilities defined as data (Resource files)
- **Health system**: separate HP bar. Enemies deal damage on collision instead of instant game over. Health pickups between floors
- **Floor progression**: 5-7 procedurally generated floors per run. Each floor: generate layout → place entities → play → reach exit → descend
- **Floor generation**: procedural placement of walls, enemies, exit, and hazard tiles. Validation that each floor is solvable
- **Information layer**: telegraph system that degrades based on sanity thresholds — reliable at high sanity, unreliable/hidden at low sanity
- **Win/lose conditions**: win by surviving all floors; lose when health reaches 0 (not sanity)
- **UI**: hex grid rendering, sanity bar, health bar, ability buttons, enemy telegraph overlays, floor indicator

## Capabilities

### New Capabilities

- `turn-loop`: Turn-based game loop state machine — manages phase transitions from player input through enemy resolution to state checks
- `entity-system`: Data-driven entity definitions and management — player, enemies, and their properties/behaviors on the hex grid
- `enemy-behaviors`: Deterministic enemy AI patterns — 5-8 enemy types with distinct, readable behaviors that interact with the sanity system
- `sanity-system`: Sanity resource management with config-driven thresholds — tracks sanity, applies threshold effects to information and abilities
- `ability-system`: Sanity-costed abilities — data-driven ability definitions, targeting, resolution, and sanity threshold unlocks
- `health-system`: Player health, damage from enemies, and between-floor recovery
- `floor-progression`: Multi-floor run structure — floor generation, transitions, and run completion
- `floor-generation`: Procedural floor layout — hex grid population with walls, enemies, exit, and hazard tiles with solvability validation
- `information-layer`: Enemy telegraph system degraded by sanity — controls what battlefield information the player can see at each threshold

### Modified Capabilities

_(No existing specs to modify — this is the initial build)_

## Impact

- **Spike code** (`scripts/game_board.gd`): refactored into multiple scripts/scenes. The monolithic 520-line script becomes the orchestration layer, with systems extracted into dedicated scripts
- **Hex utilities** (`scripts/hex_utils.gd`): retained and extended with pathfinding and line-of-sight utilities needed by enemy behaviors and floor generation
- **Scene structure** (`scenes/main.tscn`): restructured from single-scene to layered architecture (grid manager → entity layer → UI layer)
- **New data files**: Resource definitions for enemies, abilities, sanity thresholds, and floor generation parameters
- **No external dependencies** added — all systems built with core Godot 4.x / GDScript
