class_name FloorDef extends Resource

@export var enemy_count_range: Vector2i  # x = min, y = max
@export var enemy_pool: Array[StringName] = []
@export var wall_density: float = 0.1  # 0.0-1.0
@export var has_health_pickup: bool = false
