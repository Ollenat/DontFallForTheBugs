class_name PauseMenu
extends Node

const SETTINGS_PATH := "user://settings.cfg"
const MAIN_MENU_THEME: Theme = preload("res://themes/Text_theme.tres")

var _overlay: Control
var _volume_slider: HSlider
var _volume_value: Label
var _paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_overlay()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()

func _create_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.theme = MAIN_MENU_THEME
	_overlay.visible = false
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.04, 0.05, 0.86)
	_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520.0, 330.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#321d18")
	panel_style.border_color = Color("#8b542f")
	panel_style.set_border_width_all(5)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 18)
	margin.add_child(contents)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#f4c542"))
	title.add_theme_font_size_override("font_size", 42)
	contents.add_child(title)

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 14)
	contents.add_child(volume_row)
	var volume_label := Label.new()
	volume_label.text = "Master Volume"
	volume_label.custom_minimum_size = Vector2(150.0, 0.0)
	volume_row.add_child(volume_label)
	_volume_slider = HSlider.new()
	_volume_slider.custom_minimum_size = Vector2(220.0, 0.0)
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.01
	volume_row.add_child(_volume_slider)
	_volume_value = Label.new()
	_volume_value.custom_minimum_size = Vector2(56.0, 0.0)
	_volume_row_add_value(volume_row)
	_load_volume()
	_volume_slider.value_changed.connect(_on_volume_changed)

	var resume := Button.new()
	resume.text = "RESUME"
	resume.pressed.connect(_resume)
	contents.add_child(resume)
	var menu := Button.new()
	menu.text = "RETURN TO MAIN MENU"
	menu.pressed.connect(_return_to_main_menu)
	contents.add_child(menu)

func _volume_row_add_value(volume_row: HBoxContainer) -> void:
	volume_row.add_child(_volume_value)
	_volume_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _load_volume() -> void:
	var config := ConfigFile.new()
	var value: float = 1.0
	if config.load(SETTINGS_PATH) == OK:
		value = float(config.get_value("audio", "master_volume", 1.0))
	_volume_slider.set_value_no_signal(value)
	_apply_volume(value)
	_update_volume_label(value)

func _on_volume_changed(value: float) -> void:
	_apply_volume(value)
	_update_volume_label(value)
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", value)
	config.save(SETTINGS_PATH)

func _apply_volume(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, value <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.0001)))

func _update_volume_label(value: float) -> void:
	_volume_value.text = "%d%%" % roundi(value * 100.0)

func _pause() -> void:
	_paused = true
	_overlay.visible = true
	get_tree().paused = true
	_volume_slider.grab_focus()

func _resume() -> void:
	_paused = false
	_overlay.visible = false
	get_tree().paused = false

func _return_to_main_menu() -> void:
	_resume()
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
