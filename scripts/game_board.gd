extends Node2D

## GameBoard — hex grid rendering and player input only.
## Reads visible state from InformationLayer and entity positions from EntityManager.

const HEX_SIZE := HexUtils.HEX_SIZE

# --- Colors ---
const COLOR_HEX_FILL := Color(0.12, 0.12, 0.18)
const COLOR_HEX_BORDER := Color(0.25, 0.25, 0.35)
const COLOR_HEX_HOVER := Color(0.2, 0.2, 0.3)
const COLOR_HEX_VALID_MOVE := Color(0.15, 0.3, 0.2)
const COLOR_PLAYER := Color(0.3, 0.7, 1.0)
const COLOR_ENEMY := Color(0.9, 0.2, 0.2)
const COLOR_ENEMY_SENTINEL := Color(0.8, 0.3, 0.1)
const COLOR_ENEMY_DRIFTER := Color(0.7, 0.5, 0.2)
const COLOR_ENEMY_FLANKER := Color(0.9, 0.1, 0.5)
const COLOR_ENEMY_BLINKER := Color(0.6, 0.2, 0.9)
const COLOR_EXIT := Color(0.2, 0.8, 0.4)
const COLOR_WALL := Color(0.08, 0.08, 0.12)
const COLOR_TELEGRAPH := Color(0.9, 0.4, 0.1, 0.35)
const COLOR_TELEGRAPH_FAKE := Color(0.9, 0.4, 0.1, 0.2)
const COLOR_ABILITY_RANGE := Color(0.5, 0.2, 0.8, 0.25)
const COLOR_CORRUPTED := Color(0.4, 0.1, 0.4)

signal player_move_requested(target: Vector2i)
signal ability_target_selected(target: Vector2i)
signal pass_turn_requested()

var entity_mgr: EntityManager
var turn_manager: TurnManager
var ability_system: AbilitySystem
var information_layer: InformationLayer
var floor_manager: FloorManager

var hovered_hex := Vector2i(99, 99)
var hex_polygon: PackedVector2Array

var _enemy_colors: Dictionary = {
	&"lurker": COLOR_ENEMY,
	&"sentinel": COLOR_ENEMY_SENTINEL,
	&"drifter": COLOR_ENEMY_DRIFTER,
	&"flanker": COLOR_ENEMY_FLANKER,
	&"blinker": COLOR_ENEMY_BLINKER,
}


func _ready() -> void:
	hex_polygon = HexUtils.hex_polygon(HEX_SIZE)
	var viewport_size := get_viewport_rect().size
	position = viewport_size / 2.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var local_pos := to_local((event as InputEventMouseMotion).position)
		var new_hover := HexUtils.pixel_to_hex(local_pos, HEX_SIZE)
		if new_hover != hovered_hex:
			hovered_hex = new_hover
			queue_redraw()

	if not turn_manager.is_player_input_phase():
		return

	# Escape cancels ability targeting
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			if ability_system.is_targeting():
				ability_system.cancel_targeting()
				queue_redraw()

	# Space = pass turn
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_SPACE:
			pass_turn_requested.emit()

	# Left-click
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var local_pos := to_local(mb.position)
			var clicked := HexUtils.pixel_to_hex(local_pos, HEX_SIZE)
			if ability_system.is_targeting():
				ability_target_selected.emit(clicked)
			else:
				player_move_requested.emit(clicked)


func _draw() -> void:
	var all_hexes := floor_manager.all_hexes
	var wall_hexes := floor_manager.wall_hexes
	var exit_pos := floor_manager.exit_pos

	var valid_moves := _get_valid_moves(all_hexes, wall_hexes)

	var ability_range_hexes := {}
	if ability_system.is_targeting():
		ability_range_hexes = _get_ability_range_hexes(all_hexes, wall_hexes)

	# Draw all hexes
	for hex: Vector2i in all_hexes:
		var center := HexUtils.hex_to_pixel(hex, HEX_SIZE)
		var fill_color := COLOR_HEX_FILL

		if wall_hexes.has(hex):
			fill_color = COLOR_WALL
		elif information_layer.corrupted_hexes.has(hex):
			fill_color = COLOR_CORRUPTED
		elif ability_system.is_targeting() and hex in ability_range_hexes:
			fill_color = COLOR_ABILITY_RANGE
		elif not ability_system.is_targeting() and hex in valid_moves:
			fill_color = COLOR_HEX_VALID_MOVE

		if hex == hovered_hex and all_hexes.has(hex):
			fill_color = fill_color.lightened(0.15)

		var offset_poly := PackedVector2Array()
		for point in hex_polygon:
			offset_poly.append(point + center)

		draw_colored_polygon(offset_poly, fill_color)

		# Border
		var border_color := COLOR_EXIT if hex == exit_pos else COLOR_HEX_BORDER
		var border_width := 3.0 if hex == exit_pos else 1.5
		for i in 6:
			draw_line(offset_poly[i], offset_poly[(i + 1) % 6], border_color, border_width)

	# Draw telegraph indicators
	for t_hex in information_layer.visible_telegraphs:
		var center := HexUtils.hex_to_pixel(t_hex, HEX_SIZE)
		var d_size := HEX_SIZE * 0.2
		var diamond := PackedVector2Array([
			center + Vector2(0, -d_size),
			center + Vector2(d_size, 0),
			center + Vector2(0, d_size),
			center + Vector2(-d_size, 0),
		])
		var color := COLOR_TELEGRAPH if information_layer.telegraph_is_reliable else COLOR_TELEGRAPH_FAKE
		draw_colored_polygon(diamond, color)

	# Draw enemies
	for enemy in entity_mgr.get_enemies():
		var epos: Vector2i = enemy.pos
		var enemy_center := HexUtils.hex_to_pixel(epos, HEX_SIZE)
		var tri_size := HEX_SIZE * 0.45
		var tri_points := PackedVector2Array([
			enemy_center + Vector2(0, -tri_size),
			enemy_center + Vector2(-tri_size * 0.866, tri_size * 0.5),
			enemy_center + Vector2(tri_size * 0.866, tri_size * 0.5),
		])
		var behavior_name: StringName = enemy.def.behavior if enemy.def else &"lurker"
		var color: Color = _enemy_colors.get(behavior_name, COLOR_ENEMY)
		draw_colored_polygon(tri_points, color)

	# Draw exit
	var exit_center := HexUtils.hex_to_pixel(exit_pos, HEX_SIZE)
	var e_size := HEX_SIZE * 0.35
	var exit_diamond := PackedVector2Array([
		exit_center + Vector2(0, -e_size),
		exit_center + Vector2(e_size, 0),
		exit_center + Vector2(0, e_size),
		exit_center + Vector2(-e_size, 0),
	])
	draw_colored_polygon(exit_diamond, COLOR_EXIT)

	# Draw player
	var player_pos := entity_mgr.get_player_pos()
	var player_center := HexUtils.hex_to_pixel(player_pos, HEX_SIZE)
	var circle_radius := HEX_SIZE * 0.4
	var circle_points := PackedVector2Array()
	for i in 12:
		var angle := TAU * i / 12.0
		circle_points.append(player_center + Vector2(cos(angle), sin(angle)) * circle_radius)
	draw_colored_polygon(circle_points, COLOR_PLAYER)


func _get_valid_moves(all_hexes: Dictionary, wall_hexes: Dictionary) -> Dictionary:
	var moves := {}
	if not turn_manager.is_player_input_phase():
		return moves
	var player_pos := entity_mgr.get_player_pos()
	for neighbor in HexUtils.hex_neighbors(player_pos):
		if all_hexes.has(neighbor) and not wall_hexes.has(neighbor):
			# Allow moving into enemy hexes (causes combat)
			moves[neighbor] = true
	return moves


func _get_ability_range_hexes(all_hexes: Dictionary, wall_hexes: Dictionary) -> Dictionary:
	var targets := {}
	var ability := ability_system.get_active_ability()
	if ability == null:
		return targets
	var player_pos := entity_mgr.get_player_pos()
	for hex: Vector2i in all_hexes:
		if wall_hexes.has(hex):
			continue
		var dist := HexUtils.hex_distance(player_pos, hex)
		if dist >= 1 and dist <= ability.range:
			targets[hex] = true
	return targets
