# Entity System

## ADDED Requirements

### Requirement: Hex-Based Entity Positioning

All entities SHALL occupy a position on the hex grid using axial coordinates (q, r).

#### Scenario: Entity placed at valid hex

WHEN an entity is created at position (q, r) within the grid radius
THEN the entity SHALL be registered at that hex position.

#### Scenario: Entity placed outside grid

WHEN an entity is created at position (q, r) outside the grid radius
THEN the entity system SHALL reject the placement.

### Requirement: Single Occupancy

Each hex SHALL contain at most one entity, except during player movement resolution.

#### Scenario: Placement on occupied hex blocked

WHEN an entity attempts to be placed on a hex already occupied by another entity
THEN the placement SHALL be rejected.

#### Scenario: Player movement through occupied hex

WHEN the player moves through a hex occupied by an enemy during RESOLVE_PLAYER
THEN the movement SHALL be allowed as a transient state during resolution.

### Requirement: Entity Types

The system SHALL support three entity types: player, enemy, and exit.

#### Scenario: Player entity created

WHEN a player entity is created
THEN it SHALL have type "player" and be the only entity of that type on the floor.

#### Scenario: Enemy entity created

WHEN an enemy entity is created
THEN it SHALL have type "enemy" and reference a behavior Resource.

#### Scenario: Exit entity created

WHEN an exit entity is created
THEN it SHALL have type "exit" and be the only entity of that type on the floor.

### Requirement: Entity Lifecycle Management

Entities SHALL be created and destroyed exclusively through the entity manager.

#### Scenario: Entity creation

WHEN the entity manager creates an entity with a type and position
THEN the entity SHALL be tracked and queryable by position or type.

#### Scenario: Entity destruction

WHEN the entity manager destroys an entity
THEN the entity SHALL be removed from the grid and no longer queryable.

### Requirement: Data-Driven Entity Definitions

Entity definitions SHALL be loaded from Resource files.

#### Scenario: Enemy definition loaded from Resource

WHEN an enemy entity is instantiated
THEN its properties (health, behavior type, display info) SHALL be read from a Resource file.
