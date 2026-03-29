extends Node2D

const GRID_RADIUS := 7
const HEX_SIZE := HexUtils.HEX_SIZE

# Colors
const COLOR_HEX_FILL := Color(0.12, 0.12, 0.18)
const COLOR_HEX_BORDER := Color(0.25, 0.25, 0.35)
const COLOR_HEX_HOVER := Color(0.2, 0.2, 0.3)
const COLOR_HEX_VALID_MOVE := Color(0.15, 0.3, 0.2)
const COLOR_PLAYER := Color(0.3, 0.7, 1.0)
const COLOR_ENEMY := Color(0.9, 0.2, 0.2)

# Game state
var all_hexes: Dictionary = {}  # Vector2i -> true
var player_pos := Vector2i(0, 0)
var enemy_pos := Vector2i(3, -1)
var hovered_hex := Vector2i(99, 99)  # offscreen sentinel
var awaiting_player_input := true
var hex_polygon: PackedVector2Array

# UI
var turn_count := 0
var status_label: Label


func _ready() -> void:
	# Pre-compute hex polygon shape
	hex_polygon = HexUtils.hex_polygon(HEX_SIZE)

	# Build grid lookup
	for hex in HexUtils.get_all_hexes(GRID_RADIUS):
		all_hexes[hex] = true

	# Center the board in the viewport
	var viewport_size := get_viewport_rect().size
	position = viewport_size / 2.0

	# Status label
	status_label = Label.new()
	status_label.position = Vector2(-viewport_size.x / 2.0, -viewport_size.y / 2.0 + 10)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	add_child(status_label)
	_update_status()


func _update_status() -> void:
	var dist := HexUtils.hex_distance(player_pos, enemy_pos)
	status_label.text = "Turn: %d | Distance: %d | Click adjacent hex to move" % [turn_count, dist]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var local_pos := to_local((event as InputEventMouseMotion).position)
		var new_hover := HexUtils.pixel_to_hex(local_pos, HEX_SIZE)
		if new_hover != hovered_hex:
			hovered_hex = new_hover
			queue_redraw()

	elif event is InputEventMouseButton and awaiting_player_input:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var local_pos := to_local(mb.position)
			var clicked := HexUtils.pixel_to_hex(local_pos, HEX_SIZE)
			_try_player_move(clicked)


func _try_player_move(target: Vector2i) -> void:
	# Must be a valid adjacent hex
	if not all_hexes.has(target):
		return
	if HexUtils.hex_distance(player_pos, target) != 1:
		return
	# Can't move onto enemy
	if target == enemy_pos:
		return

	awaiting_player_input = false
	player_pos = target
	_enemy_turn()
	turn_count += 1
	awaiting_player_input = true
	_update_status()
	queue_redraw()


func _enemy_turn() -> void:
	# Simple chase: step toward player, avoiding occupied hex
	var occupied := {player_pos: true}
	var valid := all_hexes.duplicate()
	for key in occupied:
		valid.erase(key)

	enemy_pos = HexUtils.step_toward(enemy_pos, player_pos, valid)

	# Check if enemy caught player
	if HexUtils.hex_distance(enemy_pos, player_pos) <= 1:
		pass  # Will add game-over later


func _draw() -> void:
	var valid_moves := _get_valid_moves()

	# Draw all hexes
	for hex: Vector2i in all_hexes:
		var center := HexUtils.hex_to_pixel(hex, HEX_SIZE)
		var fill_color := COLOR_HEX_FILL

		if hex in valid_moves:
			fill_color = COLOR_HEX_VALID_MOVE
		if hex == hovered_hex and all_hexes.has(hex):
			fill_color = COLOR_HEX_HOVER
			if hex in valid_moves:
				fill_color = COLOR_HEX_VALID_MOVE.lightened(0.15)

		var offset_poly := PackedVector2Array()
		for point in hex_polygon:
			offset_poly.append(point + center)

		draw_colored_polygon(offset_poly, fill_color)
		# Border
		for i in 6:
			draw_line(
				offset_poly[i],
				offset_poly[(i + 1) % 6],
				COLOR_HEX_BORDER,
				1.5
			)

	# Draw enemy (red triangle)
	var enemy_center := HexUtils.hex_to_pixel(enemy_pos, HEX_SIZE)
	var tri_size := HEX_SIZE * 0.45
	var tri_points := PackedVector2Array([
		enemy_center + Vector2(0, -tri_size),
		enemy_center + Vector2(-tri_size * 0.866, tri_size * 0.5),
		enemy_center + Vector2(tri_size * 0.866, tri_size * 0.5),
	])
	draw_colored_polygon(tri_points, COLOR_ENEMY)

	# Draw player (blue circle approximation — 12-gon)
	var player_center := HexUtils.hex_to_pixel(player_pos, HEX_SIZE)
	var circle_radius := HEX_SIZE * 0.4
	var circle_points := PackedVector2Array()
	for i in 12:
		var angle := TAU * i / 12.0
		circle_points.append(player_center + Vector2(cos(angle), sin(angle)) * circle_radius)
	draw_colored_polygon(circle_points, COLOR_PLAYER)


func _get_valid_moves() -> Dictionary:
	var moves := {}
	if not awaiting_player_input:
		return moves
	for neighbor in HexUtils.hex_neighbors(player_pos):
		if all_hexes.has(neighbor) and neighbor != enemy_pos:
			moves[neighbor] = true
	return moves
