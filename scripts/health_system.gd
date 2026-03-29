class_name HealthSystem extends Node

signal health_changed(new_hp: int, old_hp: int)
signal player_died()

var max_hp: int = 3
var current_hp: int = 3


func reset(max_health: int = 3) -> void:
	max_hp = max_health
	current_hp = max_hp


func take_damage(amount: int = 1) -> void:
	var old := current_hp
	current_hp = maxi(0, current_hp - amount)
	health_changed.emit(current_hp, old)
	if current_hp <= 0:
		player_died.emit()


func heal(amount: int = 1) -> void:
	var old := current_hp
	current_hp = mini(max_hp, current_hp + amount)
	if current_hp != old:
		health_changed.emit(current_hp, old)


func is_alive() -> bool:
	return current_hp > 0
