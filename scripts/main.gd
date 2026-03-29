extends Node2D

## Main — orchestrates all systems via TurnManager signals.

@onready var turn_manager: TurnManager = $TurnManager
@onready var game_board: Node2D = $GameBoard
@onready var entity_mgr: EntityManager = $EntityManager
@onready var sanity_system: SanitySystem = $SanitySystem
@onready var ability_system: AbilitySystem = $AbilitySystem
@onready var health_system: HealthSystem = $HealthSystem
@onready var information_layer: InformationLayer = $InformationLayer
@onready var floor_manager: FloorManager = $FloorManager
@onready var enemy_behaviors: EnemyBehaviors = $EnemyBehaviors
@onready var ui_layer: UILayer = $UILayer

const CORRUPTED_TILE_SANITY_COST := 5


func _ready() -> void:
	# Wire system references
	game_board.entity_mgr = entity_mgr
	game_board.turn_manager = turn_manager
	game_board.ability_system = ability_system
	game_board.information_layer = information_layer
	game_board.floor_manager = floor_manager

	ability_system.entity_mgr = entity_mgr
	ability_system.sanity_system = sanity_system
	ability_system.health_system = health_system
	ability_system.information_layer = information_layer

	information_layer.entity_mgr = entity_mgr
	information_layer.sanity_system = sanity_system
	information_layer.enemy_behaviors = enemy_behaviors

	floor_manager.entity_mgr = entity_mgr
	floor_manager.sanity_system = sanity_system
	floor_manager.health_system = health_system
	floor_manager.information_layer = information_layer

	ui_layer.entity_mgr = entity_mgr
	ui_layer.sanity_system = sanity_system
	ui_layer.health_system = health_system
	ui_layer.ability_system = ability_system
	ui_layer.turn_manager = turn_manager
	ui_layer.floor_manager = floor_manager

	# Connect signals
	game_board.player_move_requested.connect(_on_player_move_requested)
	game_board.ability_target_selected.connect(_on_ability_target_selected)
	game_board.pass_turn_requested.connect(_on_pass_turn)

	turn_manager.phase_changed.connect(_on_phase_changed)

	floor_manager.floor_started.connect(_on_floor_started)
	floor_manager.run_won.connect(_on_run_won)
	floor_manager.run_lost.connect(_on_run_lost)

	health_system.player_died.connect(_on_player_died)

	ui_layer.ability_button_pressed.connect(_on_ability_button_pressed)
	ui_layer.restart_requested.connect(_start_new_run)

	# Start
	_start_new_run()


func _start_new_run() -> void:
	ui_layer.hide_overlay()
	turn_manager.start_game()
	floor_manager.start_run()


func _unhandled_input(event: InputEvent) -> void:
	# R to restart when game is over
	if not turn_manager.game_active:
		if event is InputEventKey and (event as InputEventKey).pressed:
			if (event as InputEventKey).keycode == KEY_R:
				_start_new_run()


func _on_floor_started(_floor_number: int, _total_floors: int) -> void:
	information_layer.compute_telegraphs(floor_manager.all_hexes, floor_manager.wall_hexes)
	ui_layer.update_status()
	game_board.queue_redraw()


func _on_player_move_requested(target: Vector2i) -> void:
	if not turn_manager.is_player_input_phase():
		return
	if not floor_manager.all_hexes.has(target):
		return
	if floor_manager.wall_hexes.has(target):
		return
	var player_pos := entity_mgr.get_player_pos()
	if HexUtils.hex_distance(player_pos, target) != 1:
		return

	# Check if enemy at target — combat
	var entity_at := entity_mgr.get_entity_at(target)
	if not entity_at.is_empty() and entity_at.type == &"enemy":
		# Player attacks enemy and takes damage
		var hp: int = entity_at.state.get("hp", 1)
		hp -= 1
		if hp <= 0:
			entity_mgr.remove_entity(entity_at.id)
		else:
			entity_at.state["hp"] = hp
			return  # Can't move into occupied hex if enemy survives
		var dmg: int = entity_at.def.damage if entity_at.def != null else 1
		health_system.take_damage(dmg)

	entity_mgr.move_entity(entity_mgr.get_player().id, target)
	_after_player_action()


func _on_ability_target_selected(target: Vector2i) -> void:
	if not turn_manager.is_player_input_phase():
		return
	if ability_system.try_use_ability(target, floor_manager.all_hexes):
		_after_player_action()


func _on_ability_button_pressed(ability_id: StringName) -> void:
	if not turn_manager.is_player_input_phase():
		return
	var def: AbilityDef = entity_mgr.ability_defs.get(ability_id, null)
	if def == null:
		return

	# Glimpse is instant (no targeting needed)
	if def.effect == &"glimpse":
		if ability_system.can_use_ability(def):
			ability_system._active_ability = def
			ability_system.try_use_ability(Vector2i.ZERO, floor_manager.all_hexes)
			_after_player_action()
		return

	if ability_system.can_use_ability(def):
		ability_system.start_targeting(def)
		game_board.queue_redraw()
		ui_layer.update_status()


func _on_pass_turn() -> void:
	if not turn_manager.is_player_input_phase():
		return
	_after_player_action()


func _after_player_action() -> void:
	# Check corrupted tile
	var player_pos := entity_mgr.get_player_pos()
	if information_layer.check_corrupted_tile(player_pos):
		sanity_system.spend_sanity(CORRUPTED_TILE_SANITY_COST)

	# Check exit
	if player_pos == floor_manager.exit_pos:
		floor_manager.on_exit_reached()
		return

	# Advance through phases
	turn_manager.advance_phase()  # -> RESOLVE_PLAYER


func _on_phase_changed(phase: TurnManager.Phase) -> void:
	match phase:
		TurnManager.Phase.RESOLVE_PLAYER:
			# Player action already resolved, advance
			turn_manager.advance_phase()  # -> ENEMY_AI

		TurnManager.Phase.ENEMY_AI:
			_resolve_enemy_ai()
			turn_manager.advance_phase()  # -> RESOLVE_ENEMY

		TurnManager.Phase.RESOLVE_ENEMY:
			_resolve_enemy_actions()
			turn_manager.advance_phase()  # -> CHECK_STATE

		TurnManager.Phase.CHECK_STATE:
			_check_state()

		TurnManager.Phase.PLAYER_INPUT:
			ability_system.reset_turn()
			ui_layer.update_status()
			game_board.queue_redraw()


var _pending_enemy_actions: Array[Dictionary] = []


func _resolve_enemy_ai() -> void:
	_pending_enemy_actions.clear()
	var enemies := entity_mgr.get_enemies()
	var player_pos := entity_mgr.get_player_pos()
	var claimed: Dictionary = {}  # positions already claimed by earlier enemies

	for enemy in enemies:
		var enemy_pos: Vector2i = enemy.pos
		var enemy_id: int = enemy.id
		var action := enemy_behaviors.get_action(
			enemy, player_pos,
			floor_manager.all_hexes, floor_manager.wall_hexes,
			entity_mgr, information_layer._rng
		)
		# No-stacking: if another enemy already claims the target, stay put
		var action_target: Vector2i = action.get("target", enemy_pos)
		if action.type == "move" and action_target != enemy_pos:
			if claimed.has(action_target) or (entity_mgr.is_hex_occupied(action_target) and entity_mgr.get_entity_at(action_target).type == &"enemy"):
				action = {"type": "wait", "target": enemy_pos}
				action_target = enemy_pos
		claimed[action_target] = true
		_pending_enemy_actions.append({"entity_id": enemy_id, "action": action})


func _resolve_enemy_actions() -> void:
	var player_pos := entity_mgr.get_player_pos()
	for entry in _pending_enemy_actions:
		var eid: int = entry.entity_id
		var entity := entity_mgr.get_entity(eid)
		if entity.is_empty():
			continue
		var action: Dictionary = entry.action
		var action_type: String = action.type
		var action_target: Vector2i = action.get("target", Vector2i.ZERO)
		var entity_pos: Vector2i = entity.pos
		var edef: EnemyDef = entity.def if entity.def != null else null
		var enemy_dmg: int = edef.damage if edef != null else 1
		match action_type:
			"move":
				entity_mgr.move_entity(eid, action_target)
				# Check collision with player
				if action_target == player_pos:
					health_system.take_damage(enemy_dmg)
			"attack":
				# Sentinel-style adjacent damage
				if HexUtils.hex_distance(entity_pos, player_pos) <= 1:
					health_system.take_damage(enemy_dmg)
	_pending_enemy_actions.clear()


func _check_state() -> void:
	if not health_system.is_alive():
		return  # player_died signal handles this

	# Spawn corrupted tiles
	information_layer.spawn_corrupted_tiles(floor_manager.all_hexes, floor_manager.wall_hexes)

	# Compute telegraphs for next turn
	information_layer.compute_telegraphs(floor_manager.all_hexes, floor_manager.wall_hexes)

	# Advance to next turn
	turn_manager.advance_phase()  # -> PLAYER_INPUT


func _on_player_died() -> void:
	turn_manager.stop_game()
	floor_manager.on_player_died()


func _on_run_won() -> void:
	turn_manager.stop_game()
	ui_layer.show_victory()
	ui_layer.update_status()
	game_board.queue_redraw()


func _on_run_lost() -> void:
	turn_manager.stop_game()
	ui_layer.show_game_over()
	ui_layer.update_status()
	game_board.queue_redraw()
