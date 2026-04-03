# Ability System

## ADDED Requirements

### Requirement: Data-Driven Ability Definitions

Abilities SHALL be defined as Resource files containing: name, sanity_cost, range, effect, and unlock_threshold.

#### Scenario: Ability loaded from Resource

WHEN the ability system initializes
THEN each ability's properties SHALL be read from its Resource file.

### Requirement: One Ability Per Turn

The player SHALL use at most one ability per turn. Using an ability SHALL replace the normal move action.

#### Scenario: Ability replaces move

WHEN the player activates an ability during PLAYER_INPUT
THEN the player SHALL NOT also move this turn.

#### Scenario: Second ability rejected

WHEN the player has already used an ability this turn and attempts another
THEN the system SHALL reject the second ability.

### Requirement: Sanity Cost

Activating an ability SHALL deduct its sanity_cost from the player's current sanity.

#### Scenario: Sufficient sanity

WHEN the player activates an ability with cost 15 and has 40 sanity
THEN sanity SHALL decrease to 25 and the ability SHALL resolve.

#### Scenario: Insufficient sanity

WHEN the player activates an ability with cost 20 and has 15 sanity
THEN the ability SHALL be rejected and sanity SHALL remain at 15.

### Requirement: Threshold-Gated Availability

Some abilities SHALL only be available when the player's sanity is at or below a specific threshold.

#### Scenario: Ability available at correct threshold

WHEN the player's sanity threshold is ABYSS and an ability's unlock_threshold is ABYSS
THEN the ability SHALL be available for use.

#### Scenario: Ability locked above threshold

WHEN the player's sanity threshold is HIGH and an ability's unlock_threshold is FRACTURED
THEN the ability SHALL NOT be available for use.

### Requirement: Ability Targeting

Ability activation SHALL follow a two-step process: select ability, then select target hex within range.

#### Scenario: Valid target in range

WHEN the player selects Eldritch Step and targets a hex 2 hexes away (range: 3)
THEN the ability SHALL be activated on that hex.

#### Scenario: Target out of range

WHEN the player selects Eldritch Step and targets a hex 4 hexes away (range: 3)
THEN the ability SHALL be rejected.

### Requirement: Eldritch Step

Eldritch Step SHALL teleport the player to the target hex. Cost: 20 sanity. Range: 3 hexes. Available at any sanity threshold.

#### Scenario: Teleport to empty hex

WHEN the player at (0, 0) uses Eldritch Step targeting (2, -1)
THEN the player SHALL move to (2, -1) without traversing intermediate hexes.

#### Scenario: Teleport to occupied hex blocked

WHEN the player uses Eldritch Step targeting a hex occupied by an enemy
THEN the ability SHALL be rejected.

### Requirement: Void Pulse

Void Pulse SHALL destroy all enemies within range of the player's current position. Cost: 15 sanity. Range: 2 hexes. Available only at ABYSS threshold.

#### Scenario: Enemies destroyed in range

WHEN the player at (0, 0) uses Void Pulse and enemies exist at (1, 0) and (1, 1) (both within range 2)
THEN both enemies SHALL be destroyed.

#### Scenario: Enemies outside range unaffected

WHEN the player at (0, 0) uses Void Pulse and an enemy exists at (3, 0) (range 3, outside range 2)
THEN that enemy SHALL NOT be affected.

### Requirement: Glimpse

Glimpse SHALL reveal true enemy telegraphs for all enemies for 1 turn, overriding sanity-based information degradation. Cost: 10 sanity. Range: unlimited. Available at any sanity threshold.

#### Scenario: Telegraphs revealed

WHEN the player uses Glimpse while at ABYSS threshold
THEN all enemy telegraphs SHALL display their true next-move positions for the current turn.

### Requirement: Warp Strike

Warp Strike SHALL teleport the player to the target hex and deal damage to all enemies adjacent to the destination. Cost: 25 sanity. Range: 2 hexes. Available only at FRACTURED threshold or below.

#### Scenario: Teleport and damage

WHEN the player uses Warp Strike targeting (1, 1) and enemies are adjacent to (1, 1)
THEN the player SHALL move to (1, 1) and adjacent enemies SHALL take 1 damage.

#### Scenario: Warp Strike to occupied hex blocked

WHEN the player uses Warp Strike targeting a hex occupied by an enemy
THEN the ability SHALL be rejected.
