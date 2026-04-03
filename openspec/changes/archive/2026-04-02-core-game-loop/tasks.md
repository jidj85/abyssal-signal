## 1. Data Foundation — Resource Definitions

- [x] 1.1 Create `EnemyDef` Resource class (`scripts/resources/enemy_def.gd`) with fields: id, display_name, behavior, health, damage, telegraph_visible, spawn_weight, min_floor
- [x] 1.2 Create `AbilityDef` Resource class (`scripts/resources/ability_def.gd`) with fields: id, display_name, sanity_cost, range, effect, unlock_threshold
- [x] 1.3 Create `SanityThresholdDef` Resource class (`scripts/resources/sanity_threshold_def.gd`) with fields: id, min_sanity, max_sanity, telegraph_mode, corrupted_tiles_active, available_abilities
- [x] 1.4 Create `FloorDef` Resource class (`scripts/resources/floor_def.gd`) with fields: enemy_count_range, enemy_pool, wall_density, has_health_pickup
- [x] 1.5 Create `.tres` data files for 5 enemy types: lurker, sentinel, drifter, flanker, blinker (`data/enemies/`)
- [x] 1.6 Create `.tres` data files for 4 abilities: eldritch_step, void_pulse, glimpse, warp_strike (`data/abilities/`)
- [x] 1.7 Create `.tres` data files for 3 sanity thresholds: lucid, fractured, abyss (`data/thresholds/`)
- [x] 1.8 Create `.tres` data files for 7 floor definitions with scaling difficulty (`data/floors/`)

## 2. Core Architecture — Scene Tree and HexUtils Extensions

- [x] 2.1 Extend `HexUtils` with `bfs_path()`, `hexes_in_range()`, and `hex_ring()` static functions (`scripts/hex_utils.gd`)
- [x] 2.2 Restructure `scenes/main.tscn` scene tree: Main → TurnManager, GameBoard, EntityManager, SanitySystem, AbilitySystem, HealthSystem, InformationLayer, FloorManager, UILayer
- [x] 2.3 Create `TurnManager` script (`scripts/turn_manager.gd`) with Phase enum (PLAYER_INPUT, RESOLVE_PLAYER, ENEMY_AI, RESOLVE_ENEMY, CHECK_STATE), phase signals, and sequential phase advancement

## 3. Entity System

- [x] 3.1 Create `EntityManager` script (`scripts/entity_manager.gd`) — entity registry, spawn/remove functions, position tracking, single-occupancy enforcement, entity lookup by hex position
- [x] 3.2 Load all `EnemyDef` and `AbilityDef` resources at startup into dictionaries keyed by id

## 4. Game Board Refactor

- [x] 4.1 Refactor `GameBoard` (`scripts/game_board.gd`) to only handle hex grid data and rendering — remove all game logic, enemy AI, sanity, abilities, and input handling. Rendering reads from InformationLayer for display state
- [x] 4.2 Extract input handling to respond only during PLAYER_INPUT phase via TurnManager signals — player move clicks, ability targeting, pass turn

## 5. Sanity System

- [x] 5.1 Create `SanitySystem` script (`scripts/sanity_system.gd`) — sanity value, spend_sanity(), threshold checking, threshold transition signals, loads threshold configs from Resource files
- [x] 5.2 Wire sanity system to TurnManager: threshold changes emit signals that other systems (InformationLayer, AbilitySystem) connect to

## 6. Health System

- [x] 6.1 Create `HealthSystem` script (`scripts/health_system.gd`) — player HP, take_damage(), heal(), game-over signal when HP reaches 0, configurable max HP (default 3)

## 7. Enemy Behavior System

- [x] 7.1 Create `EnemyBehaviors` script (`scripts/enemy_behaviors.gd`) — behavior registry mapping StringName → callable, pure function signature: (entity_pos, player_pos, grid_state, entities) → Action
- [x] 7.2 Implement Lurker behavior: move 1 hex toward player each turn (extracted from spike's step_toward)
- [x] 7.3 Implement Sentinel behavior: stationary, deals damage to adjacent player at end of turn
- [x] 7.4 Implement Drifter behavior: move in fixed direction, bounce off grid edges
- [x] 7.5 Implement Flanker behavior: move to minimize distance while avoiding direct path (prefer lateral movement)
- [x] 7.6 Implement Blinker behavior: teleport to random hex in range every 2 turns, stationary between
- [x] 7.7 Wire enemy behaviors into ENEMY_AI phase — EntityManager iterates enemies in order, each queries behavior registry, actions resolve sequentially with no-stacking enforcement

## 8. Ability System

- [x] 8.1 Create `AbilitySystem` script (`scripts/ability_system.gd`) — ability resolution, targeting validation, sanity threshold gating, one-ability-per-turn enforcement
- [x] 8.2 Implement Eldritch Step effect: teleport player to target hex within range (cost 20, range 3, any sanity)
- [x] 8.3 Implement Void Pulse effect: destroy all enemies within range (cost 15, range 2, requires ABYSS)
- [x] 8.4 Implement Glimpse effect: reveal true telegraphs for 1 turn (cost 10, any sanity)
- [x] 8.5 Implement Warp Strike effect: teleport to hex + damage adjacent enemies (cost 25, range 2, requires FRACTURED)

## 9. Information Layer

- [x] 9.1 Create `InformationLayer` script (`scripts/information_layer.gd`) — reads true game state, produces visible state filtered by current sanity threshold
- [x] 9.2 Implement telegraph filtering: exact at Lucid, real+fakes at Fractured, hidden at Abyss (extracted and parameterized from spike telegraph logic)
- [x] 9.3 Implement corrupted tile spawning at Abyss threshold (1-2 per turn, sanity cost on walk-through)
- [x] 9.4 Implement Glimpse override: temporarily show true telegraphs for 1 turn regardless of threshold

## 10. Floor Generation

- [x] 10.1 Create `FloorGenerator` script (`scripts/floor_generator.gd`) — pure function: takes FloorDef + RNG seed, returns FloorState (grid, walls, entity positions, exit position)
- [x] 10.2 Implement wall placement: random-walk clustering for tactical interest, 5-15% of grid
- [x] 10.3 Implement exit placement on grid edge, minimum 8 distance from center
- [x] 10.4 Implement enemy placement: scaled by floor number, minimum distance 4 from player start, respecting enemy pool from FloorDef
- [x] 10.5 Implement BFS path validation from player start to exit — regenerate if no valid path

## 11. Floor Progression

- [x] 11.1 Create `FloorManager` script (`scripts/floor_manager.gd`) — floor sequence (5-7 floors), current floor tracking, floor transitions
- [x] 11.2 Implement floor transition: heal +1 HP, reset sanity to max, generate next floor, update UI
- [x] 11.3 Implement win condition: reaching exit on final floor triggers victory
- [x] 11.4 Implement lose condition: health reaching 0 triggers game over with restart option

## 12. UI Layer

- [x] 12.1 Create `UILayer` scene (`scenes/ui_layer.tscn`) with CanvasLayer containing StatusBar, SanityBar, HealthBar, AbilityPanel
- [x] 12.2 Implement SanityBar — extract and refine spike's sanity bar rendering with threshold markers, wire to SanitySystem signals
- [x] 12.3 Implement HealthBar — simple HP pips or bar display, wire to HealthSystem signals
- [x] 12.4 Implement AbilityPanel — show available abilities with costs, highlight usable ones based on current sanity, handle ability selection clicks
- [x] 12.5 Implement StatusBar — turn count, floor number, enemy count, threshold state text
- [x] 12.6 Implement game over / victory overlay with restart option

## 13. Integration and Playtesting

- [x] 13.1 Wire all systems together in main scene — TurnManager signals connected to all systems, full turn loop executing player → enemy → check → next turn
- [x] 13.2 End-to-end playtest: complete a full run (all floors, win condition) and verify all specs pass
- [x] 13.3 Balance pass: tune enemy counts per floor, ability costs, health values, wall density based on playtest feedback
