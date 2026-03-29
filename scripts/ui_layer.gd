class_name UILayer extends CanvasLayer

signal ability_button_pressed(ability_id: StringName)
signal restart_requested()

var entity_mgr: EntityManager
var sanity_system: SanitySystem
var health_system: HealthSystem
var ability_system: AbilitySystem
var turn_manager: TurnManager
var floor_manager: FloorManager

# UI nodes
var status_label: Label
var sanity_bar: Control
var health_bar: HBoxContainer
var ability_panel: HBoxContainer
var overlay_panel: Panel
var overlay_label: Label
var restart_button: Button

const SANITY_BAR_WIDTH := 300.0
const SANITY_BAR_HEIGHT := 20.0

const COLOR_SANITY_HIGH := Color(0.3, 0.8, 0.4)
const COLOR_SANITY_MID := Color(0.9, 0.7, 0.2)
const COLOR_SANITY_LOW := Color(0.9, 0.2, 0.3)
const COLOR_HP_FULL := Color(0.9, 0.2, 0.3)
const COLOR_HP_EMPTY := Color(0.3, 0.3, 0.3)


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Status bar (top-left)
	status_label = Label.new()
	status_label.position = Vector2(10, 10)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	add_child(status_label)

	# Health bar (top-left, below status)
	health_bar = HBoxContainer.new()
	health_bar.position = Vector2(10, 40)
	add_child(health_bar)

	# Ability panel (bottom-left)
	ability_panel = HBoxContainer.new()
	ability_panel.position = Vector2(10, 660)
	ability_panel.add_theme_constant_override("separation", 8)
	add_child(ability_panel)

	# Sanity bar (bottom-center) — drawn in _draw via a custom Control
	sanity_bar = Control.new()
	sanity_bar.position = Vector2(640 - SANITY_BAR_WIDTH / 2, 690)
	sanity_bar.custom_minimum_size = Vector2(SANITY_BAR_WIDTH, SANITY_BAR_HEIGHT)
	sanity_bar.draw.connect(_draw_sanity_bar)
	add_child(sanity_bar)

	# Game over / victory overlay
	overlay_panel = Panel.new()
	overlay_panel.visible = false
	overlay_panel.position = Vector2(340, 260)
	overlay_panel.size = Vector2(600, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	overlay_panel.add_theme_stylebox_override("panel", style)
	add_child(overlay_panel)

	overlay_label = Label.new()
	overlay_label.position = Vector2(20, 30)
	overlay_label.add_theme_font_size_override("font_size", 28)
	overlay_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	overlay_panel.add_child(overlay_label)

	restart_button = Button.new()
	restart_button.text = "Restart (R)"
	restart_button.position = Vector2(220, 120)
	restart_button.size = Vector2(160, 40)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	overlay_panel.add_child(restart_button)


func update_status() -> void:
	if not turn_manager or not floor_manager:
		return
	var enemies := entity_mgr.get_enemies()
	var threshold_text := ""
	if sanity_system.current_threshold:
		threshold_text = " | %s" % sanity_system.current_threshold.id.to_upper()
	status_label.text = "Floor %d/%d | Turn %d | Enemies: %d%s" % [
		floor_manager.current_floor, floor_manager.total_floors,
		turn_manager.turn_count, enemies.size(), threshold_text
	]
	_update_health_display()
	_update_ability_panel()
	sanity_bar.queue_redraw()


func _update_health_display() -> void:
	# Clear existing pips
	for child in health_bar.get_children():
		child.queue_free()

	for i in health_system.max_hp:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(20, 20)
		pip.color = COLOR_HP_FULL if i < health_system.current_hp else COLOR_HP_EMPTY
		health_bar.add_child(pip)


func _update_ability_panel() -> void:
	for child in ability_panel.get_children():
		child.queue_free()

	var abilities := ability_system.get_available_abilities()
	for ability: AbilityDef in abilities:
		var btn := Button.new()
		var can_use := ability_system.can_use_ability(ability)
		btn.text = "%s (%d)" % [ability.display_name, ability.sanity_cost]
		btn.disabled = not can_use or not turn_manager.is_player_input_phase()
		btn.custom_minimum_size = Vector2(140, 30)
		var ability_id: StringName = ability.id
		btn.pressed.connect(func() -> void: ability_button_pressed.emit(ability_id))
		ability_panel.add_child(btn)


func _draw_sanity_bar() -> void:
	if not sanity_system:
		return
	# Background
	sanity_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(SANITY_BAR_WIDTH, SANITY_BAR_HEIGHT)), Color(0.1, 0.1, 0.15))

	# Fill
	var fill_ratio := float(sanity_system.sanity) / float(SanitySystem.SANITY_MAX)
	var fill_w := SANITY_BAR_WIDTH * fill_ratio
	var fill_color: Color
	if sanity_system.sanity > 50:
		fill_color = COLOR_SANITY_HIGH
	elif sanity_system.sanity > 25:
		fill_color = COLOR_SANITY_MID
	else:
		fill_color = COLOR_SANITY_LOW

	if fill_w > 0:
		sanity_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(fill_w, SANITY_BAR_HEIGHT)), fill_color)

	# Threshold markers
	var t1_x := SANITY_BAR_WIDTH * 0.5  # fractured at 50
	var t2_x := SANITY_BAR_WIDTH * 0.25  # abyss at 25
	sanity_bar.draw_line(Vector2(t1_x, 0), Vector2(t1_x, SANITY_BAR_HEIGHT), Color(0.9, 0.7, 0.2, 0.8), 2.0)
	sanity_bar.draw_line(Vector2(t2_x, 0), Vector2(t2_x, SANITY_BAR_HEIGHT), Color(0.9, 0.2, 0.3, 0.8), 2.0)

	# Border
	sanity_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(SANITY_BAR_WIDTH, SANITY_BAR_HEIGHT)), Color(0.4, 0.4, 0.5), false, 1.5)

	# Text
	sanity_bar.draw_string(ThemeDB.fallback_font, Vector2(SANITY_BAR_WIDTH + 8, 15), "%d/%d" % [sanity_system.sanity, SanitySystem.SANITY_MAX], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8))


func show_game_over() -> void:
	overlay_label.text = "CONSUMED\nYour investigation ends here."
	overlay_panel.visible = true


func show_victory() -> void:
	overlay_label.text = "ESCAPED\nYou survived the signal."
	overlay_panel.visible = true


func hide_overlay() -> void:
	overlay_panel.visible = false
