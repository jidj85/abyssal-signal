class_name FloorManager extends Node

signal floor_started(floor_number: int, total_floors: int)
signal floor_completed(floor_number: int)
signal run_won()
signal run_lost()

var entity_mgr: EntityManager
var sanity_system: SanitySystem
var health_system: HealthSystem
var information_layer: InformationLayer

var current_floor: int = 0
var total_floors: int = 7
var floor_defs: Array[FloorDef] = []
var _rng := RandomNumberGenerator.new()

# Current floor state
var all_hexes: Dictionary = {}
var wall_hexes: Dictionary = {}
var exit_pos := Vector2i.ZERO


func _ready() -> void:
	_load_floor_defs()


func _load_floor_defs() -> void:
	for i in range(1, 8):
		var path := "res://data/floors/floor_%d.tres" % i
		if ResourceLoader.exists(path):
			var def: FloorDef = load(path)
			if def:
				floor_defs.append(def)


func start_run(seed_val: int = 0) -> void:
	if seed_val == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_val
	current_floor = 0
	health_system.reset()
	_start_next_floor()


func _start_next_floor() -> void:
	current_floor += 1
	sanity_system.reset()
	entity_mgr.clear_all()
	information_layer.reset_floor()
	# Note: turn_count is managed by TurnManager and persists across floors (intentional)
	information_layer.setup(_rng.randi())

	var floor_idx := mini(current_floor - 1, floor_defs.size() - 1)
	var floor_def: FloorDef = floor_defs[floor_idx]

	var floor_state := FloorGenerator.generate(floor_def, _rng.randi(), current_floor, entity_mgr.enemy_defs)

	all_hexes = floor_state.all_hexes
	wall_hexes = floor_state.walls
	exit_pos = floor_state.exit_pos

	# Spawn player
	entity_mgr.spawn_entity(&"player", floor_state.player_pos)

	# Exit position is tracked by floor_manager directly (not as entity)

	# Spawn enemies
	for enemy_data: Dictionary in floor_state.enemies:
		var def: EnemyDef = entity_mgr.enemy_defs.get(enemy_data.def_id, null)
		var state := {"hp": def.health if def else 1}
		# Initialize drifter direction randomly
		if def and def.behavior == &"drifter":
			state["dir_idx"] = _rng.randi_range(0, 5)
		entity_mgr.spawn_entity(&"enemy", enemy_data.pos, def, state)

	floor_started.emit(current_floor, total_floors)


func on_exit_reached() -> void:
	if current_floor >= total_floors:
		run_won.emit()
	else:
		floor_completed.emit(current_floor)
		# Heal between floors
		health_system.heal(1)
		_start_next_floor()


func on_player_died() -> void:
	run_lost.emit()
