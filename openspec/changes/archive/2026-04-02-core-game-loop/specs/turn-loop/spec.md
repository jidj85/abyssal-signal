# Turn Loop

## ADDED Requirements

### Requirement: Turn Phase State Machine

The game loop SHALL operate as a sequential state machine with five phases: PLAYER_INPUT, RESOLVE_PLAYER, ENEMY_AI, RESOLVE_ENEMY, CHECK_STATE.

#### Scenario: Normal turn cycle

WHEN a new turn begins
THEN the phase SHALL transition through PLAYER_INPUT -> RESOLVE_PLAYER -> ENEMY_AI -> RESOLVE_ENEMY -> CHECK_STATE in strict order.

#### Scenario: Phase completion gate

WHEN the current phase has not completed
THEN the next phase SHALL NOT begin.

#### Scenario: Turn counter increments

WHEN the CHECK_STATE phase completes without triggering a win or loss condition
THEN the turn counter SHALL increment by 1 and the phase SHALL return to PLAYER_INPUT.

### Requirement: Player Input Gating

The system SHALL only accept player input during the PLAYER_INPUT phase.

#### Scenario: Input accepted during correct phase

WHEN the current phase is PLAYER_INPUT and the player submits a move or ability action
THEN the system SHALL accept the action and transition to RESOLVE_PLAYER.

#### Scenario: Input rejected outside correct phase

WHEN the current phase is not PLAYER_INPUT and a player action is received
THEN the system SHALL ignore the action.

### Requirement: Deterministic Phase Resolution

Each phase SHALL produce the same output given the same game state input.

#### Scenario: Identical state produces identical resolution

WHEN the same game state is provided to RESOLVE_PLAYER or RESOLVE_ENEMY
THEN the resulting state changes SHALL be identical across invocations.

### Requirement: Phase Signal Emission

Each phase transition SHALL emit a signal for UI and subsystem synchronization.

#### Scenario: Phase change signal

WHEN the turn loop transitions from one phase to the next
THEN a phase_changed signal SHALL be emitted with the new phase identifier.
