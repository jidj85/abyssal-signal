class_name FloorGenerator extends RefCounted

## Pure function: takes FloorDef + RNG seed, returns floor state.
## No side effects — can be called repeatedly for regeneration.

const GRID_RADIUS := 7


static func generate(floor_def: FloorDef, seed_val: int, floor_number: int, enemy_defs: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Attempt generation, retry if path invalid
	for _attempt in 20:
		var result := _try_generate(floor_def, rng, floor_number, enemy_defs)
		if result.valid:
			return result
		rng.seed = rng.randi()  # re-seed for retry

	# Fallback: generate without walls
	return _try_generate_fallback(floor_def, rng, floor_number, enemy_defs)


static func _try_generate(floor_def: FloorDef, rng: RandomNumberGenerator, floor_number: int, enemy_defs: Dictionary) -> Dictionary:
	var all_hexes := _build_hex_dict()
	var walls: Dictionary = {}

	# Place walls via random walk clustering
	var total_hexes := all_hexes.size()
	var target_walls := int(total_hexes * floor_def.wall_density)
	target_walls = clampi(target_walls, 0, int(total_hexes * 0.15))

	if target_walls > 0:
		walls = _generate_walls(all_hexes, target_walls, rng)

	# Player at center
	var player_pos := Vector2i(0, 0)
	walls.erase(player_pos)
	# Clear walls adjacent to player start
	for n in HexUtils.hex_neighbors(player_pos):
		walls.erase(n)

	# Place exit at grid edge, minimum 8 distance from center
	var exit_pos := _place_exit(all_hexes, walls, rng)

	# Validate path
	var walkable := all_hexes.duplicate()
	for w: Vector2i in walls:
		walkable.erase(w)
	var path := HexUtils.bfs_path(player_pos, exit_pos, walkable)
	if path.is_empty():
		return {"valid": false}

	# Place enemies
	var enemies := _place_enemies(floor_def, floor_number, enemy_defs, all_hexes, walls, player_pos, exit_pos, rng)

	return {
		"valid": true,
		"all_hexes": all_hexes,
		"walls": walls,
		"player_pos": player_pos,
		"exit_pos": exit_pos,
		"enemies": enemies,  # Array of { def_id: StringName, pos: Vector2i }
	}


static func _try_generate_fallback(floor_def: FloorDef, rng: RandomNumberGenerator, floor_number: int, enemy_defs: Dictionary) -> Dictionary:
	var all_hexes := _build_hex_dict()
	var player_pos := Vector2i(0, 0)
	var exit_pos := _place_exit(all_hexes, {}, rng)
	var enemies := _place_enemies(floor_def, floor_number, enemy_defs, all_hexes, {}, player_pos, exit_pos, rng)
	return {
		"valid": true,
		"all_hexes": all_hexes,
		"walls": {},
		"player_pos": player_pos,
		"exit_pos": exit_pos,
		"enemies": enemies,
	}


static func _build_hex_dict() -> Dictionary:
	var hexes: Dictionary = {}
	for hex in HexUtils.get_all_hexes(GRID_RADIUS):
		hexes[hex] = true
	return hexes


static func _generate_walls(all_hexes: Dictionary, target_count: int, rng: RandomNumberGenerator) -> Dictionary:
	var walls: Dictionary = {}
	var seeds_count := maxi(1, target_count / 3)

	# Pick random seed positions for wall clusters
	var all_hex_list: Array[Vector2i] = []
	for hex: Vector2i in all_hexes:
		if HexUtils.hex_distance(Vector2i.ZERO, hex) >= 3:  # Not too close to center
			all_hex_list.append(hex)

	for _i in seeds_count:
		if all_hex_list.is_empty():
			break
		var idx := rng.randi_range(0, all_hex_list.size() - 1)
		var seed_hex := all_hex_list[idx]
		walls[seed_hex] = true

		# Random walk from seed to create cluster
		var current := seed_hex
		var walk_length := rng.randi_range(1, 3)
		for _j in walk_length:
			if walls.size() >= target_count:
				break
			var neighbors := HexUtils.hex_neighbors(current)
			var valid_neighbors: Array[Vector2i] = []
			for n in neighbors:
				if all_hexes.has(n) and HexUtils.hex_distance(Vector2i.ZERO, n) >= 2:
					valid_neighbors.append(n)
			if valid_neighbors.is_empty():
				break
			current = valid_neighbors[rng.randi_range(0, valid_neighbors.size() - 1)]
			walls[current] = true

	return walls


static func _place_exit(all_hexes: Dictionary, walls: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	# Exit must be on grid edge (distance = GRID_RADIUS from origin), not a wall
	var edge_hexes: Array[Vector2i] = []
	for hex: Vector2i in all_hexes:
		if HexUtils.hex_distance(Vector2i.ZERO, hex) == GRID_RADIUS and not walls.has(hex):
			edge_hexes.append(hex)
	if edge_hexes.is_empty():
		# Fallback: any hex at distance >= 8
		for hex: Vector2i in all_hexes:
			if HexUtils.hex_distance(Vector2i.ZERO, hex) >= GRID_RADIUS - 1 and not walls.has(hex):
				edge_hexes.append(hex)
	return edge_hexes[rng.randi_range(0, edge_hexes.size() - 1)]


static func _place_enemies(floor_def: FloorDef, floor_number: int, enemy_defs: Dictionary, all_hexes: Dictionary, walls: Dictionary, player_pos: Vector2i, exit_pos: Vector2i, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var enemies: Array[Dictionary] = []
	var count := rng.randi_range(floor_def.enemy_count_range.x, floor_def.enemy_count_range.y)

	# Filter enemy pool by min_floor
	var valid_types: Array[StringName] = []
	for type_id in floor_def.enemy_pool:
		if enemy_defs.has(type_id):
			var def: EnemyDef = enemy_defs[type_id]
			if def.min_floor <= floor_number:
				valid_types.append(type_id)
	if valid_types.is_empty():
		valid_types = [&"lurker"]  # Fallback

	# Build candidate positions: min distance 4 from player, not wall, not exit
	var occupied: Dictionary = {player_pos: true, exit_pos: true}
	var candidates: Array[Vector2i] = []
	for hex: Vector2i in all_hexes:
		if HexUtils.hex_distance(player_pos, hex) >= 4 and not walls.has(hex) and not occupied.has(hex):
			candidates.append(hex)
	candidates.shuffle()

	for i in mini(count, candidates.size()):
		var type_id := valid_types[rng.randi_range(0, valid_types.size() - 1)]
		enemies.append({"def_id": type_id, "pos": candidates[i]})
		occupied[candidates[i]] = true

	return enemies
