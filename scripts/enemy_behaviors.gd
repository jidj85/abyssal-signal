class_name EnemyBehaviors extends Node

## Behavior registry: StringName -> Callable
## Each behavior: (entity: Dictionary, player_pos: Vector2i, grid: Dictionary, entities: EntityManager, rng: RandomNumberGenerator) -> Dictionary
## Returns: { "type": "move"/"wait"/"attack", "target": Vector2i }

var _behaviors: Dictionary = {}


func _ready() -> void:
	_behaviors[&"lurker"] = _behavior_lurker
	_behaviors[&"sentinel"] = _behavior_sentinel
	_behaviors[&"drifter"] = _behavior_drifter
	_behaviors[&"flanker"] = _behavior_flanker
	_behaviors[&"blinker"] = _behavior_blinker


func get_action(entity: Dictionary, player_pos: Vector2i, valid_hexes: Dictionary, wall_hexes: Dictionary, entity_mgr: EntityManager, rng: RandomNumberGenerator) -> Dictionary:
	var behavior_name: StringName = entity.def.behavior if entity.def else &"lurker"
	if _behaviors.has(behavior_name):
		return _behaviors[behavior_name].call(entity, player_pos, valid_hexes, wall_hexes, entity_mgr, rng)
	return {"type": "wait", "target": entity.pos}


## Lurker: move 1 hex toward player each turn
func _behavior_lurker(entity: Dictionary, player_pos: Vector2i, valid_hexes: Dictionary, wall_hexes: Dictionary, _entity_mgr: EntityManager, _rng: RandomNumberGenerator) -> Dictionary:
	var walkable := _get_walkable(valid_hexes, wall_hexes)
	var entity_pos: Vector2i = entity.pos
	var next := HexUtils.step_toward(entity_pos, player_pos, walkable)
	return {"type": "move", "target": next}


## Sentinel: stationary, damages adjacent player
func _behavior_sentinel(entity: Dictionary, player_pos: Vector2i, _valid_hexes: Dictionary, _wall_hexes: Dictionary, _entity_mgr: EntityManager, _rng: RandomNumberGenerator) -> Dictionary:
	if HexUtils.hex_distance(entity.pos, player_pos) <= 1:
		return {"type": "attack", "target": player_pos}
	return {"type": "wait", "target": entity.pos}


## Drifter: move in fixed direction, bounce off grid edges
func _behavior_drifter(entity: Dictionary, _player_pos: Vector2i, valid_hexes: Dictionary, wall_hexes: Dictionary, _entity_mgr: EntityManager, _rng: RandomNumberGenerator) -> Dictionary:
	# Store direction in entity state
	var dir_idx: int = entity.state.get("dir_idx", 0)
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
	]
	var entity_pos: Vector2i = entity.pos
	var target: Vector2i = entity_pos + directions[dir_idx]
	if valid_hexes.has(target) and not wall_hexes.has(target):
		return {"type": "move", "target": target}
	# Bounce: reverse direction
	entity.state["dir_idx"] = (dir_idx + 3) % 6
	var bounce_target: Vector2i = entity_pos + directions[entity.state["dir_idx"]]
	if valid_hexes.has(bounce_target) and not wall_hexes.has(bounce_target):
		return {"type": "move", "target": bounce_target}
	return {"type": "wait", "target": entity.pos}


## Flanker: move to minimize distance while preferring lateral movement
func _behavior_flanker(entity: Dictionary, player_pos: Vector2i, valid_hexes: Dictionary, wall_hexes: Dictionary, _entity_mgr: EntityManager, _rng: RandomNumberGenerator) -> Dictionary:
	var walkable := _get_walkable(valid_hexes, wall_hexes)
	var entity_pos: Vector2i = entity.pos
	var neighbors := HexUtils.hex_neighbors(entity_pos)
	var best: Vector2i = entity_pos
	var best_dist := HexUtils.hex_distance(entity_pos, player_pos)
	var best_is_direct := true

	for n in neighbors:
		if not walkable.has(n):
			continue
		var dist := HexUtils.hex_distance(n, player_pos)
		# Direct = moving directly toward player (distance decreases and n is on the line)
		var direct := HexUtils.step_toward(entity_pos, player_pos, walkable)
		var is_direct := (n == direct)

		# Prefer: closer distance, then lateral over direct
		if dist < best_dist or (dist == best_dist and best_is_direct and not is_direct):
			best = n
			best_dist = dist
			best_is_direct = is_direct

	return {"type": "move", "target": best}


## Blinker: teleport to random hex in range every 2 turns, stationary between
func _behavior_blinker(entity: Dictionary, _player_pos: Vector2i, valid_hexes: Dictionary, wall_hexes: Dictionary, entity_mgr: EntityManager, rng: RandomNumberGenerator) -> Dictionary:
	var turn_parity: int = entity.state.get("turn_parity", 0)
	entity.state["turn_parity"] = (turn_parity + 1) % 2

	if turn_parity == 0:
		# Teleport turn
		var blink_range := 4
		var candidates: Array[Vector2i] = []
		for hex in HexUtils.hexes_in_range(entity.pos, blink_range):
			if hex != entity.pos and valid_hexes.has(hex) and not wall_hexes.has(hex) and not entity_mgr.is_hex_occupied(hex):
				candidates.append(hex)
		if candidates.size() > 0:
			var idx := rng.randi_range(0, candidates.size() - 1)
			return {"type": "move", "target": candidates[idx]}
	return {"type": "wait", "target": entity.pos}


func _get_walkable(valid_hexes: Dictionary, wall_hexes: Dictionary) -> Dictionary:
	var walkable := valid_hexes.duplicate()
	for w: Vector2i in wall_hexes:
		walkable.erase(w)
	return walkable
