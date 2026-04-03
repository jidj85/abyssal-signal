# Core Game Loop — Design

## Context

The spike code validated two things: the hex grid engine works, and the sanity-as-information-degradation mechanic creates interesting decisions. But the code is a ~520-line monolith in `scripts/game_board.gd` — grid rendering, player input, enemy AI, sanity management, ability logic, UI, and game state all live in a single script with hardcoded positions and constants.

This works for validation but cannot support the v1 feature set: multiple enemy types, data-driven abilities, floor progression, a real health system, or procedural generation. The architecture needs to decompose into systems that can be built, tested, and iterated independently.

`scripts/hex_utils.gd` is solid — pure functions for hex math (coordinate conversion, distance, neighbors, pathfinding step). It stays mostly as-is and gets minor extensions.

## Goals / Non-Goals

**Goals:**
- Complete playable v1 loop: 5-7 procedurally generated floors, multiple enemy types, sanity-gated abilities, health system, win/lose conditions
- Clean architecture where each system is a single responsibility in its own script (<300 lines each)
- Data-driven content: enemy definitions, ability definitions, sanity thresholds, and floor generation parameters as Godot Resource files
- Maintain the validated feel from the spike — deterministic enemies, sanity-information tradeoff, Hoplite-scale tactics

**Non-Goals:**
- Visual polish, art integration, or animation
- Meta-progression, unlocks, or save systems
- Steam integration or platform-specific features
- Performance optimization (the grid is ~150 hexes; brute force is fine)

## Decisions

### 1. Scene/Node Architecture

Decompose the monolith into a tree of single-responsibility nodes under the main scene.

```
Main (Node2D)
├── TurnManager          — state machine, orchestrates phases
├── GameBoard            — hex grid data + rendering (Node2D._draw)
├── EntityManager        — tracks all entities, handles spawning/removal
├── SanitySystem         — sanity value, threshold checks, threshold effects
├── AbilitySystem        — ability resolution, targeting validation
├── HealthSystem         — player HP, damage application
├── InformationLayer     — telegraph computation, display filtering
├── FloorManager         — floor progression, generation, transitions
└── UILayer (CanvasLayer)
    ├── StatusBar        — turn count, floor number, enemy count
    ├── SanityBar        — sanity display with threshold markers
    ├── HealthBar        — HP display
    └── AbilityPanel     — available abilities and costs
```

TurnManager is the hub. It owns the turn phase enum and emits signals at each phase transition. Other systems connect to these signals. No system calls another system directly — they communicate through TurnManager signals or by reading shared state on EntityManager/GameBoard.

This is **not** an autoload pattern. Everything is in the scene tree under Main. Autoloads are reserved for truly global services (none needed yet).

**Alternatives considered:**
- *Autoload singletons for each system* — rejected; scene tree composition is more Godot-idiomatic, easier to reason about lifecycle, and avoids hidden global state.
- *ECS-style architecture* — rejected; overkill for ~10 entities on a ~150-hex grid. Godot's node tree with signals is sufficient.

### 2. Data-Driven Entities via Resource Files

Enemy types, abilities, and sanity thresholds are defined as Godot Resource files (`.tres`), not JSON or hardcoded constants.

```gdscript
# Example: res://data/enemies/lurker.tres
class_name EnemyDef extends Resource
@export var id: StringName
@export var display_name: String
@export var behavior: StringName     # key into behavior registry
@export var health: int = 1
@export var damage: int = 1
@export var telegraph_visible: bool = true  # hidden at certain sanity levels
@export var spawn_weight: float = 1.0       # for floor generation
@export var min_floor: int = 1              # earliest floor this can appear
```

```gdscript
# Example: res://data/abilities/eldritch_step.tres
class_name AbilityDef extends Resource
@export var id: StringName
@export var display_name: String
@export var sanity_cost: int
@export var range: int
@export var effect: StringName          # key into effect registry
@export var unlock_threshold: int = 100 # sanity must be <= this to use
```

Resources are loaded at startup into dictionaries keyed by `id`. Floor generation references enemy IDs and spawn weights. The ability system references ability IDs.

**Alternatives considered:**
- *JSON files* — rejected; no type safety, no editor integration, requires manual parsing. Godot Resources are native, inspectable in the editor, and support `@export` hints.
- *Hardcoded dictionaries in GDScript* — rejected; mixes data with logic, makes balancing tedious, and couples content to code changes.

### 3. Turn Loop as State Machine

Replace the spike's `awaiting_player_input` boolean with an explicit enum-driven state machine.

```gdscript
enum Phase {
    PLAYER_INPUT,     # waiting for player click/ability/pass
    RESOLVE_PLAYER,   # execute player's chosen action
    ENEMY_AI,         # compute all enemy actions
    RESOLVE_ENEMY,    # execute enemy actions, apply damage
    CHECK_STATE,      # check win/lose, spawn effects, advance turn counter
}
```

TurnManager holds the current `Phase` and advances through them sequentially. Each phase emits a signal (`phase_started(phase)`). Systems that care about a phase connect to the signal and do their work. When all work for a phase completes, TurnManager advances to the next.

Phase transitions are synchronous (no animation delays in v1). The loop cycles: `CHECK_STATE` returns to `PLAYER_INPUT` unless the game ended.

**Alternatives considered:**
- *Coroutine-based turn loop* (`await` chains) — rejected; harder to debug, implicit state. Explicit enum is inspectable and trivially serializable if save systems are added later.
- *Event-driven without explicit phases* — rejected; too easy for ordering bugs when systems respond to the same event in undefined order.

### 4. Enemy Behavior System

Each enemy type references a behavior by `StringName`. Behaviors are registered in a dictionary mapping names to callable functions (or small behavior scripts). Each behavior is a pure function:

```gdscript
# signature: (entity_pos, grid_state, entity_positions) -> Action
# Action = { "type": "move", "target": Vector2i } or { "type": "wait" }
```

This is the same approach as the spike's `HexUtils.step_toward` but generalized. Behaviors:
- **Chaser** (spike's existing logic): step toward player via shortest path
- **Flanker**: step toward a hex adjacent to the player, not directly toward the player
- **Lurker**: wait until player is within detection range, then chase
- **Patroller**: follow a fixed path until player is nearby
- **Blocker**: move toward the exit, not the player

Behaviors are pure and deterministic — given the same inputs, they always produce the same output. This makes them testable in isolation and ensures the Hoplite-style perfect-information property at full sanity.

**Alternatives considered:**
- *Behavior trees* — rejected; too heavy for 1-step-per-turn decisions. A single function call per enemy per turn is sufficient.
- *State machines per enemy* — possible for Lurker (idle/active states), but a simple conditional in the behavior function handles this without extra infrastructure.

### 5. Floor Generation

Constraint-based procedural placement, not complex algorithmic generation.

Algorithm per floor:
1. Start with full hex grid (radius 7).
2. Place impassable wall hexes (10-20% of tiles, random but clustered for tactical interest via a simple random-walk cluster approach).
3. Place player start at center.
4. Place exit at a grid-edge hex, minimum 8 distance from center.
5. Validate pathfinding from start to exit (BFS). If no path, regenerate walls.
6. Place enemies based on floor number (types and counts from floor config). Minimum distance 4 from player start.
7. Place corrupted hexes if sanity is below threshold (carried across floors).

Floor config is a Resource:
```gdscript
class_name FloorDef extends Resource
@export var enemy_count_range: Vector2i  # min, max
@export var enemy_pool: Array[StringName]  # which enemy types can spawn
@export var wall_density: float           # 0.0-1.0
@export var has_health_pickup: bool
```

Generation is isolated in `FloorGenerator` — a pure function that takes a `FloorDef` + RNG seed and returns a `FloorState` (grid, entity positions, exit position). This isolation means generation can be improved or replaced without touching other systems.

**Alternatives considered:**
- *BSP / room-and-corridor* — rejected; designed for rectangular grids, awkward on hex. Also more complexity than needed for a 7-radius grid.
- *Wave Function Collapse* — rejected; significant implementation effort for a small grid where simple placement produces acceptable results.
- *Hand-authored floors* — rejected for v1; doesn't scale and contradicts the roguelike replayability goal. But a hybrid approach (hand-authored templates with procedural enemy placement) could work as a future improvement.

### 6. Information Layer

The information layer is a filter between the true game state and what the player sees. It replaces the spike's inline telegraph logic.

The true game state is always complete and deterministic. The `InformationLayer` node reads the true state and produces a "visible state" based on current sanity thresholds:

| Sanity Range | Telegraph | Corrupted Tiles | Enemy Count |
|---|---|---|---|
| 100-51 (Lucid) | Exact next positions shown | None | Accurate |
| 50-26 (Fractured) | Real + fake telegraphs mixed in | None | Accurate |
| 25-0 (Abyss) | No telegraphs shown | Active, spawning each turn | Accurate |

The rendering code (GameBoard._draw) reads from InformationLayer's visible state, never from the true game state directly. Game logic (damage, collision, win/lose) always uses true state.

This separation means: sanity threshold behavior is configured in threshold Resource files, the display is always consistent with the configuration, and the underlying game remains deterministic regardless of what the player can see.

**Alternatives considered:**
- *Shader-based fog/distortion* — rejected for v1; visual polish, not mechanical. The information layer is a data filter, not a rendering effect.
- *Per-entity visibility flags* — rejected; centralized filtering is simpler and ensures consistency across all display elements.

### 7. Spike Code Reuse

Not a rewrite — a decomposition. Specific reuse plan:

- **HexUtils** (`scripts/hex_utils.gd`): kept as-is. Add `bfs_path()` for floor validation and `hex_ring()` / `hexes_in_range()` for ability targeting. All additions are static pure functions matching the existing pattern.
- **Grid rendering** (`_draw()` method): the Node2D._draw approach stays. The hex fill/border/entity drawing code moves to GameBoard but the rendering logic is preserved. Rendering reads from InformationLayer instead of computing visibility inline.
- **Enemy stepping** (`step_toward` in HexUtils): becomes the "Chaser" behavior. Other behaviors are new code.
- **Telegraph computation** (`_compute_telegraphs`): extracted to InformationLayer with the same algorithm, parameterized by threshold config.
- **Sanity bar rendering**: moves to UILayer as a dedicated SanityBar control.
- **Input handling**: moves to TurnManager (phase gating) + InputHandler (mouse/key mapping to actions).

**Alternatives considered:**
- *Full rewrite from scratch* — rejected; the spike algorithms are validated. Extracting them preserves correctness and saves time.
- *Keep monolith and bolt on features* — rejected; the file is already 520 lines and would become unmaintainable. Separation now prevents compounding tech debt.

## Risks / Trade-offs

- **Over-engineering.** Nine systems for a small game risks architecture astronautics. Mitigation: keep it Godot-idiomatic (nodes + signals, not framework abstractions). Build incrementally — TurnManager and EntityManager first, then layer on systems one at a time. If a system is <50 lines, consider keeping it inline rather than extracting.

- **Floor generation quality.** Simple constraint placement may produce tactically uninteresting layouts — flat open grids with scattered walls. Mitigation: generation is isolated, so it can be tuned or replaced independently. Start simple, playtest, iterate. Wall clustering (random walk) and minimum enemy-to-exit distances add baseline tactical structure.

- **Scope creep in enemy design.** The proposal says 5-8 enemy types. Designing 8 distinct behaviors that all interact well with sanity thresholds and each other is significant design work. Mitigation: start with 5 (Chaser, Flanker, Lurker, Patroller, Blocker). Add more only after the core loop is validated as fun with those 5.

- **Agentic development friction.** Large cross-file refactors are harder for Claude Code than changes within a single file. Mitigation: keep files small (<300 lines), interfaces narrow (signals with typed arguments), and decompose the refactor into sequential steps (extract one system at a time, verify it works, then extract the next).

- **Health system changing game feel.** The spike uses instant death on enemy contact. Adding HP and multi-hit enemies changes the tactical calculus significantly. Mitigation: start with low HP (3-5) so encounters still feel dangerous. Tune after playtesting.
