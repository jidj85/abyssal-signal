# Health System

## ADDED Requirements

### Requirement: Configurable Player Health

The player SHALL have a health value with a configurable maximum (default: 3).

#### Scenario: Health initialized at max

WHEN a new run begins
THEN the player's health SHALL be set to the configured maximum.

### Requirement: Damage from Enemy Collision

Enemies SHALL deal damage to the player when they move onto the player's hex during RESOLVE_ENEMY.

#### Scenario: Enemy moves onto player hex

WHEN an enemy moves onto the player's hex at (0, 0) during RESOLVE_ENEMY
THEN the player SHALL take 1 damage.

#### Scenario: Player moves onto enemy hex

WHEN the player moves onto an enemy's hex during RESOLVE_PLAYER
THEN the player SHALL take 1 damage and the enemy SHALL be destroyed.

### Requirement: Game Over on Zero Health

Health reaching 0 SHALL trigger the lose condition.

#### Scenario: Health reaches zero

WHEN the player takes damage that reduces health from 1 to 0
THEN the game SHALL transition to a game-over state.

#### Scenario: Health above zero

WHEN the player takes damage that reduces health from 3 to 2
THEN the game SHALL continue normally.

### Requirement: Floor Transition Healing

The player SHALL recover 1 HP when transitioning to a new floor, capped at maximum health.

#### Scenario: Heal on floor transition

WHEN the player transitions to a new floor with 2 HP (max 3)
THEN the player's health SHALL increase to 3.

#### Scenario: Heal capped at max

WHEN the player transitions to a new floor with 3 HP (max 3)
THEN the player's health SHALL remain at 3.

### Requirement: Health Independent of Sanity

Sanity loss SHALL NOT reduce the player's health. Health and sanity are separate resources.

#### Scenario: Sanity drops without health change

WHEN the player spends 20 sanity on an ability
THEN the player's health SHALL remain unchanged.
