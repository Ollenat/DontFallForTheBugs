extends Control

## Path to the scene that starts when "Start Game" is pressed.
@export_file("*.tscn") var game_scene: String = "res://scenes/Game.tscn"
## Path to the options scene.
@export_file("*.tscn") var options_scene: String = "res://scenes/options_menu.tscn"

@onready var start_button: Button = %StartButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var title_label: Label = %Title


func _ready() -> void:
	# Apply saved volume / fullscreen settings on launch.
	OptionsMenu.apply_saved_settings()

	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Quitting doesn't make sense in a web export.
	if OS.has_feature("web"):
		quit_button.hide()

	# Lets keyboard / gamepad users navigate right away.
	start_button.grab_focus()

	_animate_title()


func _on_start_pressed() -> void:
	if ResourceLoader.exists(game_scene):
		get_tree().change_scene_to_file(game_scene)
	else:
		push_warning("Game scene not found: %s" % game_scene)


func _on_options_pressed() -> void:
	if ResourceLoader.exists(options_scene):
		get_tree().change_scene_to_file(options_scene)
	else:
		push_warning("Options scene not found: %s" % options_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_title_laid_out() -> void:
	# Called after the container lays out the title (it resets scale and
	# rotation each time), so our settings are re-applied here.
	# Scale from the middle of the label instead of its top-left corner.
	title_label.pivot_offset = title_label.size / 2.0
	# Godot snaps controls to whole pixels, which makes scaling text jump
	# by up to 1px per frame. A tiny rotation turns that snapping off for
	# this label only, and is far too small to see.
	title_label.rotation = 0.001


func _animate_title() -> void:
	if title_label == null:
		push_error("Title node not found. Right-click it in the Scene dock and choose 'Access as Unique Name'.")
		return

	title_label.get_parent().sort_children.connect(_on_title_laid_out)

	# Hide right away so there is no flash before the animation starts.
	title_label.modulate.a = 0.0

	# Containers reset a child's scale during their first layout pass,
	# so wait one frame before setting the starting scale.
	await get_tree().process_frame
	_on_title_laid_out()
	title_label.scale = Vector2(0.5, 0.5)

	# Intro: fade in while bouncing up to full size.
	var intro := create_tween().set_parallel(true)
	intro.tween_property(title_label, "modulate:a", 1.0, 0.6)
	intro.tween_property(title_label, "scale", Vector2.ONE, 1.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await intro.finished

	# Then a gentle, endless pulse.
	var pulse := create_tween().set_loops()
	pulse.tween_property(title_label, "scale", Vector2(1.1, 1.1), 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(title_label, "scale", Vector2.ONE, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)