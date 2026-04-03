extends Node2D

## GameBoard — hex grid rendering and player input only.
## Reads visible state from InformationLayer and entity positions from EntityManager.

const HEX_SIZE := HexUtils.HEX_SIZE
const SPRITE_SIZE := 64.0
const ENTITY_SCALE := HEX_SIZE * 2.0 / SPRITE_SIZE  # Scale 64px sprites to fit hex
const TILE_SCALE := HEX_SIZE * 2.0 / SPRITE_SIZE

# --- Overlay colors (used for highlights on top of sprites) ---
const COLOR_HEX_BORDER := Color(0.25, 0.25, 0.35)
const COLOR_HEX_HOVER := Color(1.0, 1.0, 1.0, 0.15)
const COLOR_HEX_VALID_MOVE := Color(0.15, 0.9, 0.3, 0.2)
const COLOR_ABILITY_RANGE := Color(0.5, 0.2, 0.8, 0.25)
const COLOR_EXIT_BORDER := Color(0.2, 0.8, 0.4)

# Fallback colors for entities without sprites (drifter, flanker)
const COLOR_ENEMY_DRIFTER := Color(0.7, 0.5, 0.2)
const COLOR_ENEMY_FLANKER := Color(0.9, 0.1, 0.5)

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

# --- Sprite textures ---
var _tex_tile_ground: Texture2D
var _tex_tile_wall: Texture2D
var _tex_tile_exit: Texture2D
var _tex_tile_corrupted: Texture2D
var _tex_telegraph: Texture2D
var _tex_player: Texture2D

# Enemy sprite sheets keyed by behavior name
var _enemy_textures: Dictionary = {}

# Fallback colors for enemies without sprite sheets
var _enemy_fallback_colors: Dictionary = {
	&"drifter": COLOR_ENEMY_DRIFTER,
	&"flanker": COLOR_ENEMY_FLANKER,
}

# Animation state
const FRAME_COUNT := 4
const FRAME_DURATION := 0.4  # seconds per frame
var _anim_frame := 0
var _anim_timer := 0.0


func _ready() -> void:
	hex_polygon = HexUtils.hex_polygon(HEX_SIZE)
	var viewport_size := get_viewport_rect().size
	position = viewport_size / 2.0

	# Load tile textures
	_tex_tile_ground = load("res://assets/sprites/tile_ground.png")
	_tex_tile_wall = load("res://assets/sprites/tile_wall.png")
	_tex_tile_exit = load("res://assets/sprites/tile_exit.png")
	_tex_tile_corrupted = load("res://assets/sprites/tile_corrupted.png")
	_tex_telegraph = load("res://assets/sprites/telegraph_fx.png")

	# Load entity sprite sheets
	_tex_player = load("res://assets/sprites/player_spritesheet.png")
	_enemy_textures[&"lurker"] = load("res://assets/sprites/lurker_spritesheet.png")
	_enemy_textures[&"sentinel"] = load("res://assets/sprites/sentinel_spritesheet.png")
	_enemy_textures[&"blinker"] = load("res://assets/sprites/blinker_spritesheet.png")


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


func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= FRAME_DURATION:
		_anim_timer -= FRAME_DURATION
		_anim_frame = (_anim_frame + 1) % FRAME_COUNT
		queue_redraw()


func _draw() -> void:
	var all_hexes := floor_manager.all_hexes
	var wall_hexes := floor_manager.wall_hexes
	var exit_pos := floor_manager.exit_pos

	var valid_moves := _get_valid_moves(all_hexes, wall_hexes)

	var ability_range_hexes := {}
	if ability_system.is_targeting():
		ability_range_hexes = _get_ability_range_hexes(all_hexes, wall_hexes)

	# Draw all hex tiles
	for hex: Vector2i in all_hexes:
		var center := HexUtils.hex_to_pixel(hex, HEX_SIZE)

		# Pick the right tile texture
		var tile_tex: Texture2D
		if wall_hexes.has(hex):
			tile_tex = _tex_tile_wall
		elif information_layer.corrupted_hexes.has(hex):
			tile_tex = _tex_tile_corrupted
		elif hex == exit_pos:
			tile_tex = _tex_tile_exit
		else:
			tile_tex = _tex_tile_ground

		# Draw tile sprite centered on hex
		_draw_texture_centered(tile_tex, center, TILE_SCALE)

		# Draw hex border
		var offset_poly := PackedVector2Array()
		for point in hex_polygon:
			offset_poly.append(point + center)
		var border_color := COLOR_EXIT_BORDER if hex == exit_pos else COLOR_HEX_BORDER
		var border_width := 3.0 if hex == exit_pos else 1.5
		for i in 6:
			draw_line(offset_poly[i], offset_poly[(i + 1) % 6], border_color, border_width)

		# Draw state overlays (valid move, ability range, hover)
		var overlay_color := Color.TRANSPARENT
		if ability_system.is_targeting() and hex in ability_range_hexes:
			overlay_color = COLOR_ABILITY_RANGE
		elif not ability_system.is_targeting() and hex in valid_moves:
			overlay_color = COLOR_HEX_VALID_MOVE
		if hex == hovered_hex and all_hexes.has(hex):
			overlay_color = overlay_color if overlay_color != Color.TRANSPARENT else Color(0, 0, 0, 0)
			overlay_color.a = max(overlay_color.a, 0.1)
			overlay_color = overlay_color.lightened(0.3)
			if overlay_color == Color(0, 0, 0, 0):
				overlay_color = COLOR_HEX_HOVER
		if overlay_color != Color.TRANSPARENT:
			draw_colored_polygon(offset_poly, overlay_color)

	# Draw telegraph indicators
	for t_hex in information_layer.visible_telegraphs:
		var center := HexUtils.hex_to_pixel(t_hex, HEX_SIZE)
		var telegraph_alpha := 0.8 if information_layer.telegraph_is_reliable else 0.4
		_draw_texture_centered(_tex_telegraph, center, TILE_SCALE * 0.5, telegraph_alpha)

	# Draw enemies
	for enemy in entity_mgr.get_enemies():
		var epos: Vector2i = enemy.pos
		var enemy_center := HexUtils.hex_to_pixel(epos, HEX_SIZE)
		var behavior_name: StringName = enemy.def.behavior if enemy.def else &"lurker"

		if _enemy_textures.has(behavior_name):
			_draw_spritesheet_frame(_enemy_textures[behavior_name], enemy_center, _anim_frame, ENTITY_SCALE)
		else:
			# Fallback: colored triangle for enemies without sprites
			var tri_size := HEX_SIZE * 0.45
			var tri_points := PackedVector2Array([
				enemy_center + Vector2(0, -tri_size),
				enemy_center + Vector2(-tri_size * 0.866, tri_size * 0.5),
				enemy_center + Vector2(tri_size * 0.866, tri_size * 0.5),
			])
			var color: Color = _enemy_fallback_colors.get(behavior_name, Color(0.9, 0.2, 0.2))
			draw_colored_polygon(tri_points, color)

	# Draw exit sprite (already drawn as tile, but layer the sprite on top for emphasis)
	var exit_center := HexUtils.hex_to_pixel(exit_pos, HEX_SIZE)
	_draw_texture_centered(_tex_tile_exit, exit_center, TILE_SCALE * 0.6)

	# Draw player
	var player_pos := entity_mgr.get_player_pos()
	var player_center := HexUtils.hex_to_pixel(player_pos, HEX_SIZE)
	_draw_spritesheet_frame(_tex_player, player_center, _anim_frame, ENTITY_SCALE)


## Draw a single texture centered at pos, scaled uniformly.
func _draw_texture_centered(tex: Texture2D, pos: Vector2, tex_scale: float, alpha: float = 1.0) -> void:
	var size := Vector2(tex.get_width(), tex.get_height()) * tex_scale
	var rect := Rect2(pos - size * 0.5, size)
	var modulate := Color(1, 1, 1, alpha)
	draw_texture_rect(tex, rect, false, modulate)


## Draw one frame from a horizontal sprite sheet (4 frames, each 64x64).
func _draw_spritesheet_frame(sheet: Texture2D, pos: Vector2, frame: int, tex_scale: float) -> void:
	var frame_w := sheet.get_height()  # Frames are square: height == frame width
	var src := Rect2(frame * frame_w, 0, frame_w, frame_w)
	var draw_size := Vector2(frame_w, frame_w) * tex_scale
	var dest := Rect2(pos - draw_size * 0.5, draw_size)
	draw_texture_rect_region(sheet, dest, src)


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
