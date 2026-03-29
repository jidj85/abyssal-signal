# Information Layer

## ADDED Requirements

### Requirement: Telegraph Display at HIGH Sanity

At the HIGH sanity threshold (100-51), all enemy next-move telegraphs SHALL be displayed accurately.

#### Scenario: Full telegraph at high sanity

WHEN the player's sanity is 70 (HIGH threshold) and a Lurker will move to (2, 0) next turn
THEN the telegraph display SHALL show (2, 0) as the Lurker's next position.

### Requirement: Telegraph Degradation at FRACTURED Sanity

At the FRACTURED sanity threshold (50-26), telegraphs SHALL include 1-2 fake positions per enemy mixed with the real one.

#### Scenario: Noisy telegraphs at fractured sanity

WHEN the player's sanity is 40 (FRACTURED threshold) and a Lurker will move to (2, 0)
THEN the telegraph display SHALL show (2, 0) plus 1-2 additional fake hex positions.

#### Scenario: Real telegraph always included

WHEN telegraphs are displayed at FRACTURED threshold
THEN the true next-move position SHALL always be among the displayed positions.

### Requirement: Telegraph Suppression at ABYSS Sanity

At the ABYSS sanity threshold (25-0), most telegraphs SHALL be hidden with only occasional real telegraphs shown.

#### Scenario: Most telegraphs hidden at abyss

WHEN the player's sanity is 10 (ABYSS threshold) and 4 enemies are on the grid
THEN at most 1 enemy SHALL have its true telegraph displayed; the rest SHALL be hidden.

### Requirement: Telegraph Computation Timing

Telegraph display SHALL be computed each turn after the ENEMY_AI phase resolves.

#### Scenario: Telegraphs update after enemy AI

WHEN the ENEMY_AI phase completes
THEN the telegraph display SHALL be recalculated based on the resolved enemy intents and the current sanity threshold.

### Requirement: Deterministic True State

The true game state SHALL always be deterministic regardless of sanity level. Only the display layer SHALL vary.

#### Scenario: Game state unaffected by sanity

WHEN two game instances have identical state except sanity levels (one HIGH, one ABYSS)
THEN the enemy positions and movements SHALL be identical; only the telegraph display SHALL differ.

### Requirement: Corrupted Tiles at ABYSS

Corrupted tiles SHALL appear when the player is at the ABYSS threshold. Walking through a corrupted tile SHALL cost sanity.

#### Scenario: Corrupted tiles spawned at abyss

WHEN the player's sanity threshold is ABYSS and a new turn begins
THEN 1-2 corrupted tiles SHALL be placed on random unoccupied hexes.

#### Scenario: Corrupted tile sanity cost

WHEN the player moves onto a corrupted tile
THEN the player SHALL lose a configured amount of sanity (loaded from threshold config).

#### Scenario: No corrupted tiles above abyss

WHEN the player's sanity threshold is HIGH or FRACTURED
THEN no corrupted tiles SHALL be placed.

### Requirement: Glimpse Override

The Glimpse ability SHALL override sanity-based telegraph degradation for 1 turn.

#### Scenario: Glimpse reveals true telegraphs

WHEN the player uses Glimpse at ABYSS threshold
THEN all enemy telegraphs SHALL display their true positions for the remainder of the current turn.

#### Scenario: Glimpse expires after one turn

WHEN the turn after Glimpse was used begins
THEN telegraph display SHALL return to sanity-based degradation rules.
