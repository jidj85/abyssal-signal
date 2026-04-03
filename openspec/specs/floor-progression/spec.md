# Floor Progression

## ADDED Requirements

### Requirement: Configurable Run Length

A run SHALL consist of a configurable number of floors (default: 5-7, loaded from config).

#### Scenario: Run starts at floor 1

WHEN a new run begins
THEN the current floor number SHALL be 1.

### Requirement: Floor Lifecycle

Each floor SHALL follow the sequence: generate -> play -> reach exit -> transition.

#### Scenario: Floor generation triggers play

WHEN floor generation completes
THEN the game SHALL enter the play phase with the turn loop active.

#### Scenario: Exit reached triggers transition

WHEN the player moves onto the exit entity's hex
THEN the floor SHALL end and transition SHALL begin.

### Requirement: Floor Transition Effects

Floor transition SHALL heal the player +1 HP (capped at max) and reset sanity to 100.

#### Scenario: Transition heals and resets sanity

WHEN the player transitions from floor 2 to floor 3 with 1 HP and 30 sanity
THEN health SHALL become 2 and sanity SHALL become 100.

### Requirement: Run Victory

Reaching the exit on the final floor SHALL trigger the win condition.

#### Scenario: Final floor exit

WHEN the player reaches the exit on the last configured floor
THEN the game SHALL transition to a victory state.

#### Scenario: Non-final floor exit

WHEN the player reaches the exit on any floor that is not the last
THEN the game SHALL generate and transition to the next floor.

### Requirement: Difficulty Scaling

Deeper floors SHALL have more enemies and access to harder enemy types.

#### Scenario: Floor 1 enemy count

WHEN floor 1 is generated
THEN the enemy count SHALL be at the configured minimum for floor 1.

#### Scenario: Floor 5 enemy count

WHEN floor 5 is generated
THEN the enemy count SHALL be greater than floor 1's count.

#### Scenario: Advanced enemy types on later floors

WHEN floor 4 is generated
THEN the enemy type pool SHALL include types not available on floor 1.

### Requirement: Floor Number Display

The current floor number SHALL be available for UI display.

#### Scenario: Floor number queryable

WHEN the UI queries the current floor
THEN the system SHALL return the current floor number (1-indexed).
