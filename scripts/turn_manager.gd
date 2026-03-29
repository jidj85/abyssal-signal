class_name TurnManager extends Node

enum Phase {
	PLAYER_INPUT,
	RESOLVE_PLAYER,
	ENEMY_AI,
	RESOLVE_ENEMY,
	CHECK_STATE,
}

signal phase_changed(phase: Phase)
signal turn_completed(turn_number: int)

var current_phase: Phase = Phase.PLAYER_INPUT
var turn_count: int = 0
var game_active: bool = true


func start_game() -> void:
	game_active = true
	turn_count = 0
	current_phase = Phase.PLAYER_INPUT
	phase_changed.emit(current_phase)


func advance_phase() -> void:
	if not game_active:
		return
	match current_phase:
		Phase.PLAYER_INPUT:
			current_phase = Phase.RESOLVE_PLAYER
		Phase.RESOLVE_PLAYER:
			current_phase = Phase.ENEMY_AI
		Phase.ENEMY_AI:
			current_phase = Phase.RESOLVE_ENEMY
		Phase.RESOLVE_ENEMY:
			current_phase = Phase.CHECK_STATE
		Phase.CHECK_STATE:
			turn_count += 1
			turn_completed.emit(turn_count)
			current_phase = Phase.PLAYER_INPUT
	phase_changed.emit(current_phase)


func stop_game() -> void:
	game_active = false


func is_player_input_phase() -> bool:
	return current_phase == Phase.PLAYER_INPUT and game_active
