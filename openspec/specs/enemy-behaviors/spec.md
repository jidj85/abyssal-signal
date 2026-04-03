# Enemy Behaviors

## ADDED Requirements

### Requirement: Data-Driven Behavior Definitions

Each enemy type SHALL have its behavior defined in a Resource file.

#### Scenario: Behavior loaded from Resource

WHEN an enemy is instantiated with a behavior type
THEN its movement pattern, range, and timing SHALL be read from the corresponding Resource file.

### Requirement: Deterministic Behavior Resolution

Enemy behaviors SHALL be deterministic given the same game state.

#### Scenario: Same state produces same action

WHEN an enemy evaluates its behavior with identical game state on two separate invocations
THEN the resulting action SHALL be identical.

### Requirement: No Enemy Stacking

Enemies SHALL NOT occupy the same hex as another enemy after resolution.

#### Scenario: Enemy blocked by occupied hex

WHEN an enemy's behavior would move it to a hex occupied by another enemy
THEN the enemy SHALL remain at its current position.

### Requirement: Ordered Resolution

Enemy actions SHALL resolve in a fixed order (first enemy in the list moves first).

#### Scenario: Resolution order affects outcome

WHEN two enemies would move to the same hex
THEN the enemy earlier in the resolution order SHALL claim the hex and the later enemy SHALL stay in place.

### Requirement: Lurker Behavior

The Lurker SHALL move 1 hex toward the player each turn, choosing the hex that minimizes distance to the player in axial coordinates (q, r).

#### Scenario: Lurker moves toward player

WHEN a Lurker is 3 hexes from the player at (0, 0) and the Lurker is at (2, 1)
THEN the Lurker SHALL move to the adjacent hex that reduces its distance to the player by 1.

#### Scenario: Lurker blocked by wall

WHEN the Lurker's preferred hex is a wall
THEN the Lurker SHALL choose the next-best adjacent hex that reduces distance, or stay in place if none exist.

### Requirement: Sentinel Behavior

The Sentinel SHALL remain stationary and deal damage to the player if the player is adjacent at the end of the turn.

#### Scenario: Sentinel damages adjacent player

WHEN the RESOLVE_ENEMY phase runs and the player is adjacent to a Sentinel
THEN the Sentinel SHALL deal its configured damage to the player.

#### Scenario: Sentinel ignores distant player

WHEN the RESOLVE_ENEMY phase runs and the player is not adjacent to a Sentinel
THEN the Sentinel SHALL take no action.

### Requirement: Drifter Behavior

The Drifter SHALL move 1 hex in a fixed direction each turn. WHEN it reaches the grid edge, it SHALL reverse direction.

#### Scenario: Drifter moves in fixed direction

WHEN a Drifter has direction (1, 0) and is at (2, 0)
THEN after its turn it SHALL be at (3, 0).

#### Scenario: Drifter bounces off edge

WHEN a Drifter's next hex in its current direction is outside the grid
THEN the Drifter SHALL reverse its direction and move 1 hex in the new direction.

### Requirement: Flanker Behavior

The Flanker SHALL move 1 hex per turn to minimize distance to the player while preferring lateral movement over direct approach.

#### Scenario: Flanker prefers lateral path

WHEN a Flanker has multiple adjacent hexes that reduce distance to the player
THEN the Flanker SHALL prefer the hex that is not on the direct line between itself and the player.

#### Scenario: Flanker with only direct path

WHEN a Flanker's only distance-reducing option is the direct path
THEN the Flanker SHALL take the direct path.

### Requirement: Blinker Behavior

The Blinker SHALL teleport to a random hex within its configured range every 2 turns. On off-turns, it SHALL remain stationary.

#### Scenario: Blinker teleports on active turn

WHEN it is the Blinker's active turn (even turn count since spawn)
THEN the Blinker SHALL teleport to a random unoccupied hex within its configured range.

#### Scenario: Blinker stationary on off-turn

WHEN it is the Blinker's off-turn (odd turn count since spawn)
THEN the Blinker SHALL remain at its current position.

#### Scenario: Blinker teleport uses seeded RNG

WHEN the Blinker teleports
THEN the target hex SHALL be determined by the floor's seeded RNG for reproducibility.
