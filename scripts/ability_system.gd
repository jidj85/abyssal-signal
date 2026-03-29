class_name AbilitySystem extends Node

signal ability_used(ability_id: StringName)
signal targeting_started(ability_id: StringName)
signal targeting_cancelled()

var entity_mgr: EntityManager
var sanity_system: SanitySystem
var health_system: HealthSystem
var information_layer  # Forward reference, set from Main

var _active_ability: AbilityDef = null
var _ability_used_this_turn: bool = false

# Effect registry
var _effects: Dictionary = {}


func _ready() -> void:
	_effects[&"eldritch_step"] = _effect_eldritch_step
	_effects[&"void_pulse"] = _effect_void_pulse
	_effects[&"glimpse"] = _effect_glimpse
	_effects[&"warp_strike"] = _effect_warp_strike


func reset_turn() -> void:
	_ability_used_this_turn = false
	_active_ability = null


func can_use_ability(ability_def: AbilityDef) -> bool:
	if _ability_used_this_turn:
		return false
	if not sanity_system.can_spend(ability_def.sanity_cost):
		return false
	if not sanity_system.is_ability_available(ability_def.id):
		return false
	return true


func start_targeting(ability_def: AbilityDef) -> void:
	_active_ability = ability_def
	targeting_started.emit(ability_def.id)


func cancel_targeting() -> void:
	_active_ability = null
	targeting_cancelled.emit()


func get_active_ability() -> AbilityDef:
	return _active_ability


func is_targeting() -> bool:
	return _active_ability != null


func try_use_ability(target_pos: Vector2i, valid_hexes: Dictionary) -> bool:
	if _active_ability == null:
		return false
	if not can_use_ability(_active_ability):
		_active_ability = null
		return false

	var ability := _active_ability

	# Validate target
	if ability.range > 0:
		if not valid_hexes.has(target_pos):
			return false
		var player_pos := entity_mgr.get_player_pos()
		var dist := HexUtils.hex_distance(player_pos, target_pos)
		if dist < 1 or dist > ability.range:
			return false

	# Execute
	sanity_system.spend_sanity(ability.sanity_cost)
	_ability_used_this_turn = true

	if _effects.has(ability.effect):
		_effects[ability.effect].call(target_pos)

	_active_ability = null
	ability_used.emit(ability.id)
	return true


func get_available_abilities() -> Array[AbilityDef]:
	var result: Array[AbilityDef] = []
	for def: AbilityDef in entity_mgr.ability_defs.values():
		if sanity_system.is_ability_available(def.id):
			result.append(def)
	return result


# --- Effect implementations ---

func _effect_eldritch_step(target_pos: Vector2i) -> void:
	# Teleport player to target hex
	var player := entity_mgr.get_player()
	if player.is_empty():
		return
	entity_mgr.move_entity(player.id, target_pos)


func _effect_void_pulse(_target_pos: Vector2i) -> void:
	# Destroy all enemies within range of player
	var player_pos := entity_mgr.get_player_pos()
	var vp_def := _get_ability_def(&"void_pulse")
	var range_val: int = vp_def.range if vp_def else 2
	var to_remove: Array[int] = []
	for enemy in entity_mgr.get_enemies():
		if HexUtils.hex_distance(player_pos, enemy.pos) <= range_val:
			to_remove.append(enemy.id)
	for id in to_remove:
		entity_mgr.remove_entity(id)


func _effect_glimpse(_target_pos: Vector2i) -> void:
	# Reveal true telegraphs for 1 turn
	if information_layer:
		information_layer.activate_glimpse()


func _effect_warp_strike(target_pos: Vector2i) -> void:
	# Teleport to hex + damage adjacent enemies
	var player := entity_mgr.get_player()
	if player.is_empty():
		return
	entity_mgr.move_entity(player.id, target_pos)
	# Damage adjacent enemies
	var neighbors := HexUtils.hex_neighbors(target_pos)
	var to_damage: Array[int] = []
	for n in neighbors:
		var entity := entity_mgr.get_entity_at(n)
		if not entity.is_empty() and entity.type == &"enemy":
			to_damage.append(entity.id)
	for id in to_damage:
		var enemy := entity_mgr.get_entity(id)
		if not enemy.is_empty():
			var default_hp: int = enemy.def.health if enemy.def != null else 1
			var hp: int = enemy.state.get("hp", default_hp)
			hp -= 1
			if hp <= 0:
				entity_mgr.remove_entity(id)
			else:
				enemy.state["hp"] = hp


func _get_ability_def(id: StringName) -> AbilityDef:
	return entity_mgr.ability_defs.get(id, null)
