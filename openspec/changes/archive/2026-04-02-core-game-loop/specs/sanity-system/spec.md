# Sanity System

## ADDED Requirements

### Requirement: Sanity Initialization

Sanity SHALL start at the maximum value (100) at the beginning of each floor.

#### Scenario: Sanity reset on floor start

WHEN a new floor begins
THEN the player's sanity SHALL be set to 100.

### Requirement: Voluntary Sanity Spending

Sanity SHALL only decrease when the player activates an ability. Sanity loss SHALL NOT be forced by enemy actions or environmental effects (except corrupted tiles).

#### Scenario: Ability reduces sanity

WHEN the player activates an ability with sanity cost 20 and current sanity is 80
THEN sanity SHALL decrease to 60.

#### Scenario: Sanity not reduced by enemy damage

WHEN an enemy deals damage to the player
THEN the player's sanity SHALL remain unchanged.

### Requirement: Config-Driven Sanity Thresholds

Three thresholds SHALL be defined in a configuration Resource: HIGH (100-51), FRACTURED (50-26), ABYSS (25-0).

#### Scenario: Threshold boundaries

WHEN sanity is 51
THEN the active threshold SHALL be HIGH.

WHEN sanity is 50
THEN the active threshold SHALL be FRACTURED.

WHEN sanity is 25
THEN the active threshold SHALL be ABYSS.

### Requirement: Threshold Configuration Contents

Each threshold definition SHALL specify: visibility rules, available abilities, and tile effects.

#### Scenario: Threshold defines visibility rules

WHEN the threshold config for FRACTURED is loaded
THEN it SHALL contain a visibility_rules property that the information layer can query.

#### Scenario: Threshold defines available abilities

WHEN the threshold config for ABYSS is loaded
THEN it SHALL contain an abilities list that the ability system can query.

### Requirement: Sanity Floor at Zero

Sanity reaching 0 SHALL NOT cause death or game over. The player SHALL remain in the ABYSS threshold.

#### Scenario: Sanity at zero

WHEN sanity reaches 0
THEN the player SHALL remain alive and the threshold SHALL be ABYSS.

#### Scenario: Ability at zero sanity

WHEN sanity is 0 and the player attempts an ability with cost > 0
THEN the ability SHALL be rejected (insufficient sanity).

### Requirement: Threshold Transition Events

The system SHALL emit a signal when sanity crosses a threshold boundary.

#### Scenario: Crossing into FRACTURED

WHEN sanity decreases from 51 to 45
THEN a threshold_changed signal SHALL be emitted with the value FRACTURED.

#### Scenario: No signal within same threshold

WHEN sanity decreases from 80 to 60 (both HIGH)
THEN no threshold_changed signal SHALL be emitted.
