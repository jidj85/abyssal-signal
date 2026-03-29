class_name EntityManager extends Node

## Entity data structure
## Each entity is a dictionary: { id: int, type: StringName, pos: Vector2i, def: Resource, state: Dictionary }

signal entity_spawned(entity_id: int)
signal entity_removed(entity_id: int)

var _next_id: int = 0
var _entities: Dictionary = {}  # id -> entity dict
var _position_map: Dictionary = {}  # Vector2i -> entity id
var _player_id: int = -1

# Data registries loaded from resources
var enemy_defs: Dictionary = {}  # StringName -> EnemyDef
var ability_defs: Dictionary = {}  # StringName -> AbilityDef


func _ready() -> void:
	_load_enemy_defs()
	_load_ability_defs()


func _load_enemy_defs() -> void:
	var dir := DirAccess.open("res://data/enemies/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var def: EnemyDef = load("res://data/enemies/" + file_name)
				if def:
					enemy_defs[def.id] = def
			file_name = dir.get_next()


func _load_ability_defs() -> void:
	var dir := DirAccess.open("res://data/abilities/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var def: AbilityDef = load("res://data/abilities/" + file_name)
				if def:
					ability_defs[def.id] = def
			file_name = dir.get_next()


func clear_all() -> void:
	_entities.clear()
	_position_map.clear()
	_player_id = -1
	_next_id = 0


func spawn_entity(type: StringName, pos: Vector2i, def: Resource = null, state: Dictionary = {}) -> int:
	if _position_map.has(pos):
		return -1  # hex occupied
	var id := _next_id
	_next_id += 1
	var entity := {
		"id": id,
		"type": type,
		"pos": pos,
		"def": def,
		"state": state,
	}
	_entities[id] = entity
	_position_map[pos] = id
	if type == &"player":
		_player_id = id
	entity_spawned.emit(id)
	return id


func remove_entity(id: int) -> void:
	if not _entities.has(id):
		return
	var entity: Dictionary = _entities[id]
	_position_map.erase(entity.pos)
	if id == _player_id:
		_player_id = -1
	_entities.erase(id)
	entity_removed.emit(id)


func move_entity(id: int, new_pos: Vector2i) -> bool:
	if not _entities.has(id):
		return false
	var entity: Dictionary = _entities[id]
	# Allow move even if destination occupied (collision handled by game logic)
	_position_map.erase(entity.pos)
	entity.pos = new_pos
	_position_map[new_pos] = id
	return true


func get_entity(id: int) -> Dictionary:
	return _entities.get(id, {})


func get_entity_at(pos: Vector2i) -> Dictionary:
	var id: int = _position_map.get(pos, -1)
	if id == -1:
		return {}
	return _entities.get(id, {})


func get_player() -> Dictionary:
	return get_entity(_player_id)


func get_player_pos() -> Vector2i:
	var player := get_player()
	if player.is_empty():
		return Vector2i.ZERO
	return player.pos


func get_enemies() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entity: Dictionary in _entities.values():
		if entity.type == &"enemy":
			result.append(entity)
	return result


func get_enemy_positions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for entity: Dictionary in _entities.values():
		if entity.type == &"enemy":
			result.append(entity.pos)
	return result


func get_all_occupied_positions() -> Dictionary:
	return _position_map.duplicate()


func is_hex_occupied(pos: Vector2i) -> bool:
	return _position_map.has(pos)


func get_entity_id_at(pos: Vector2i) -> int:
	return _position_map.get(pos, -1)
