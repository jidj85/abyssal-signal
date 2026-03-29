class_name SanityThresholdDef extends Resource

@export var id: StringName
@export var min_sanity: int
@export var max_sanity: int
@export var telegraph_mode: StringName  # "exact", "unreliable", "hidden"
@export var corrupted_tiles_active: bool = false
@export var available_abilities: Array[StringName] = []
