class_name AbilityDef extends Resource

@export var id: StringName
@export var display_name: String
@export var sanity_cost: int
@export var range: int
@export var effect: StringName
@export var unlock_threshold: int = 100  # sanity must be <= this to use (100 = always available)
