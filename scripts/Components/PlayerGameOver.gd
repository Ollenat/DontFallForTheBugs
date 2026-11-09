class_name PlayerGameOver
extends Node

const MAIN_MENU_THEME: Theme = preload("res://themes/Text_theme.tres")
const SETTINGS_PATH := "user://settings.cfg"

var _player: CharacterBody3D
var _upgrades: PlayerUpgradeComponent
var _shown := false
var _score: int = 1
var _high_score: int = 1

func configure(player: CharacterBody3D, upgrades: PlayerUpgradeComponent) -> void:
	_player = player
	_upgrades = upgrades
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if health:
		health.died.connect(_on_died)

func _on_died() -> void:
	if _shown:
		return
	_shown = true
	_show_screen()

func _show_screen() -> void:
	_score = _get_score()
	_high_score = _save_high_score(_score)
	var canvas := CanvasLayer.new()
	canvas.name = "GameOver"
	canvas.layer = 20
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.04, 0.05, 0.86)
	canvas.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, 520.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#321d18")
	style.border_color = Color("#8b542f")
	style.set_border_width_all(5)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	panel.theme = MAIN_MENU_THEME
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 14)
	margin.add_child(contents)
	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#f4c542"))
	title.add_theme_font_size_override("font_size", 42)
	contents.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "FLOOR %d  •  HIGH SCORE %d" % [_score, _high_score]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#ffe28a"))
	contents.add_child(subtitle)
	var upgrades_title := Label.new()
	upgrades_title.text = "UPGRADES COLLECTED"
	upgrades_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrades_title.add_theme_color_override("font_color", Color("#ffe28a"))
	contents.add_child(upgrades_title)
	var upgrades_scroll := ScrollContainer.new()
	upgrades_scroll.custom_minimum_size = Vector2(480.0, 290.0)
	upgrades_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contents.add_child(upgrades_scroll)
	var upgrades := Label.new()
	upgrades.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrades.text = _upgrade_summary()
	upgrades_scroll.add_child(upgrades)
	var menu_button := Button.new()
	menu_button.text = "RETURN TO MAIN MENU"
	menu_button.custom_minimum_size = Vector2(0.0, 48.0)
	menu_button.pressed.connect(_return_to_main_menu)
	contents.add_child(menu_button)
	menu_button.grab_focus()
	get_tree().paused = true

func _get_score() -> int:
	var tower: Node = get_tree().get_first_node_in_group("tower")
	if tower and tower.has_method("get_score_floor_number"):
		return int(tower.get_score_floor_number())
	return 1

func _save_high_score(score: int) -> int:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	var saved_score: int = int(config.get_value("score", "high_score", 0))
	var high_score: int = maxi(saved_score, score)
	if high_score != saved_score:
		config.set_value("score", "high_score", high_score)
		var error: Error = config.save(SETTINGS_PATH)
		if error != OK:
			push_error("Could not save high score: %s" % error)
	return high_score

func _upgrade_summary() -> String:
	if not _upgrades or _upgrades.upgrade_levels.is_empty():
		return "No upgrades collected."
	var lines: Array[String] = []
	for upgrade in UpgradeCatalog.all():
		var level: int = int(_upgrades.upgrade_levels.get(upgrade.id, 0))
		if level > 0:
			lines.append("%s  x%d" % [upgrade.title, level])
	return "\n".join(lines)

func _return_to_main_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
