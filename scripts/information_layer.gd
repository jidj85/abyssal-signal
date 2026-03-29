class_name InformationLayer extends Node

var entity_mgr: EntityManager
var sanity_system: SanitySystem
var enemy_behaviors: EnemyBehaviors

# Visible state — what the rendering layer reads
var visible_telegraphs: Array[Vector2i] = []
var telegraph_is_reliable: bool = true
var corrupted_hexes: Dictionary = {}  # Vector2i -> true

var _glimpse_active: bool = false
var _rng := RandomNumberGenerator.new()


func setup(seed_val: int) -> void:
	_rng.seed = seed_val


func reset_floor() -> void:
	visible_telegraphs.clear()
	corrupted_hexes.clear()
	_glimpse_active = false
	telegraph_is_reliable = true


func activate_glimpse() -> void:
	_glimpse_active = true


func compute_telegraphs(valid_hexes: Dictionary, wall_hexes: Dictionary) -> void:
	visible_telegraphs.clear()

	var enemies := entity_mgr.get_enemies()
	if enemies.is_empty():
		telegraph_is_reliable = true
		return

	# Compute true next positions
	var real_telegraphs: Array[Vector2i] = []
	var player_pos := entity_mgr.get_player_pos()
	for enemy in enemies:
		var epos: Vector2i = enemy.pos
		var action := enemy_behaviors.get_action(enemy, player_pos, valid_hexes, wall_hexes, entity_mgr, _rng)
		var action_type: String = action.type
		if action_type == "move":
			var atarget: Vector2i = action.target
			real_telegraphs.append(atarget)
		else:
			real_telegraphs.append(epos)

	var mode := sanity_system.get_telegraph_mode()

	# Glimpse overrides everything
	if _glimpse_active:
		visible_telegraphs = real_telegraphs.duplicate()
		telegraph_is_reliable = true
		_glimpse_active = false
		return

	match mode:
		&"exact":
			visible_telegraphs = real_telegraphs.duplicate()
			telegraph_is_reliable = true
		&"unreliable":
			telegraph_is_reliable = false
			visible_telegraphs = real_telegraphs.duplicate()
			# Add 1-2 fake telegraphs per enemy
			for enemy in enemies:
				var epos: Vector2i = enemy.pos
				var neighbors := HexUtils.hex_neighbors(epos)
				neighbors.shuffle()
				var fakes_to_add := _rng.randi_range(1, 2)
				var added := 0
				for n in neighbors:
					if valid_hexes.has(n) and n not in real_telegraphs and n not in visible_telegraphs:
						visible_telegraphs.append(n)
						added += 1
						if added >= fakes_to_add:
							break
		&"hidden":
			telegraph_is_reliable = false
			# Show at most 1 in ~4 enemies' true telegraph
			for i in real_telegraphs.size():
				if _rng.randi_range(0, 3) == 0:
					visible_telegraphs.append(real_telegraphs[i])


func spawn_corrupted_tiles(valid_hexes: Dictionary, wall_hexes: Dictionary) -> void:
	if not sanity_system.are_corrupted_tiles_active():
		return
	var count := _rng.randi_range(1, 2)
	var player_pos := entity_mgr.get_player_pos()
	var candidates: Array[Vector2i] = []
	for hex: Vector2i in valid_hexes:
		if hex != player_pos and not wall_hexes.has(hex) and not corrupted_hexes.has(hex) and not entity_mgr.is_hex_occupied(hex):
			candidates.append(hex)
	candidates.shuffle()
	for i in mini(count, candidates.size()):
		corrupted_hexes[candidates[i]] = true


func check_corrupted_tile(pos: Vector2i) -> bool:
	if corrupted_hexes.has(pos):
		corrupted_hexes.erase(pos)
		return true
	return false
