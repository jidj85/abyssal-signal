# Floor Generation

## ADDED Requirements

### Requirement: Grid-Bounded Generation

Floor generation SHALL produce content within a hex grid of configured radius.

#### Scenario: All placed entities within bounds

WHEN a floor is generated with grid radius 7
THEN every entity and tile SHALL have axial coordinates (q, r) where abs(q) + abs(r) + abs(-q-r) <= 2 * radius.

### Requirement: Player Placement

The player SHALL be placed at the center of the grid at (0, 0).

#### Scenario: Player at origin

WHEN a floor is generated
THEN the player entity SHALL be at position (0, 0).

### Requirement: Exit Placement

The exit SHALL be placed on a random edge hex of the grid.

#### Scenario: Exit on grid edge

WHEN a floor is generated with radius 7
THEN the exit entity SHALL be at a hex where the hex distance from (0, 0) equals 7.

### Requirement: Wall Placement

Wall hexes (impassable, blocking movement and abilities) SHALL occupy 5-15% of the grid.

#### Scenario: Wall density within range

WHEN a floor is generated
THEN the number of wall hexes SHALL be between 5% and 15% of the total hex count.

#### Scenario: Walls block movement

WHEN an entity attempts to move onto a wall hex
THEN the movement SHALL be rejected.

### Requirement: Enemy Placement

Enemies SHALL be placed based on the current floor number, scaling count and types.

#### Scenario: Enemies placed on floor 1

WHEN floor 1 is generated
THEN enemies SHALL be placed at valid unoccupied hexes using the floor-1 enemy configuration.

#### Scenario: No enemy at player start

WHEN a floor is generated
THEN no enemy SHALL be placed at (0, 0) or on hexes adjacent to (0, 0).

### Requirement: Path Validation

A valid path MUST exist from the player start (0, 0) to the exit hex, verified by A* or flood fill.

#### Scenario: Valid path exists

WHEN a floor is generated
THEN a walkable path from (0, 0) to the exit hex SHALL exist, avoiding walls.

#### Scenario: Invalid layout regenerated

WHEN floor generation produces a layout with no valid path from player to exit
THEN the generator SHALL discard the layout and regenerate.

### Requirement: Seeded RNG

Floor generation SHALL use a seeded random number generator for reproducibility.

#### Scenario: Same seed produces same floor

WHEN floor generation runs twice with the same seed and floor number
THEN the resulting layouts SHALL be identical (same walls, enemies, exit position).

#### Scenario: Different seeds produce different floors

WHEN floor generation runs with two different seeds
THEN the resulting layouts SHALL differ.
