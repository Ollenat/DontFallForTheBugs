class_name PlayerHealthHud
extends Node

const MAIN_MENU_THEME: Theme = preload("res://themes/Text_theme.tres")

@export var health: HealthComponent
var _health_bar: ProgressBar
var _health_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if health == null:
		health = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	_create_display()

func _process(_delta: float) -> void:
	if health:
		_health_bar.max_value = health.max_health
		_health_bar.value = health.current_health
		_health_label.text = "HEALTH  %d / %d" % [health.current_health, health.max_health]

func _create_display() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "PlayerHud"
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(28.0, 28.0)
	panel.custom_minimum_size = Vector2(280.0, 64.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#321d18")
	panel_style.border_color = Color("#8b542f")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.theme = MAIN_MENU_THEME
	canvas.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 3)
	panel.add_child(contents)
	_health_label = Label.new()
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_label.add_theme_color_override("font_color", Color("#ffe28a"))
	contents.add_child(_health_label)
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(250.0, 22.0)
	_health_bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#4b2d21")
	background.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#d94a3a")
	fill.set_corner_radius_all(5)
	_health_bar.add_theme_stylebox_override("background", background)
	_health_bar.add_theme_stylebox_override("fill", fill)
	contents.add_child(_health_bar)
