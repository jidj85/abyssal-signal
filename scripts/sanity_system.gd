class_name SanitySystem extends Node

signal sanity_changed(new_value: int, old_value: int)
signal threshold_changed(new_threshold: SanityThresholdDef, old_threshold: SanityThresholdDef)

const SANITY_MAX := 100

var sanity: int = SANITY_MAX
var thresholds: Array[SanityThresholdDef] = []
var current_threshold: SanityThresholdDef = null


func _ready() -> void:
	_load_thresholds()
	_update_threshold()


func _load_thresholds() -> void:
	var dir := DirAccess.open("res://data/thresholds/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var def: SanityThresholdDef = load("res://data/thresholds/" + file_name)
				if def:
					thresholds.append(def)
			file_name = dir.get_next()
	# Sort by max_sanity descending so we check highest first
	thresholds.sort_custom(func(a: SanityThresholdDef, b: SanityThresholdDef) -> bool:
		return a.max_sanity > b.max_sanity
	)


func reset() -> void:
	var old := sanity
	sanity = SANITY_MAX
	sanity_changed.emit(sanity, old)
	_update_threshold()


func spend_sanity(amount: int) -> bool:
	if amount > sanity:
		return false
	var old := sanity
	sanity = maxi(0, sanity - amount)
	sanity_changed.emit(sanity, old)
	_update_threshold()
	return true


func can_spend(amount: int) -> bool:
	return sanity >= amount


func get_telegraph_mode() -> StringName:
	if current_threshold:
		return current_threshold.telegraph_mode
	return &"exact"


func are_corrupted_tiles_active() -> bool:
	if current_threshold:
		return current_threshold.corrupted_tiles_active
	return false


func is_ability_available(ability_id: StringName) -> bool:
	if current_threshold:
		return ability_id in current_threshold.available_abilities
	return false


func _update_threshold() -> void:
	for t in thresholds:
		if sanity >= t.min_sanity and sanity <= t.max_sanity:
			if t != current_threshold:
				var old := current_threshold
				current_threshold = t
				if old != null:
					threshold_changed.emit(current_threshold, old)
			return
