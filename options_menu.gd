class_name OptionsMenu
extends Control

const SETTINGS_PATH := "user://settings.cfg"

## Scene to return to when "Back" is pressed.
@export_file("*.tscn") var back_scene: String = "res://scenes/main_menu.tscn"

@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var back_button: Button = %BackButton


func _ready() -> void:
	# Load saved values into the UI without firing signals.
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH) # Missing file is fine, defaults are used below.
	volume_slider.set_value_no_signal(config.get_value("audio", "master_volume", 1.0))
	fullscreen_check.set_pressed_no_signal(config.get_value("video", "fullscreen", false))
	_update_volume_label(volume_slider.value)

	volume_slider.value_changed.connect(_on_volume_changed)
	volume_slider.drag_ended.connect(_on_volume_drag_ended)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)

	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


# --- Signal handlers ---------------------------------------------------------

func _on_volume_changed(value: float) -> void:
	_apply_volume(value)
	_update_volume_label(value)
	# Keyboard/gamepad changes don't emit drag_ended, so save here too
	# when the slider isn't being dragged with the mouse.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_save()


func _on_volume_drag_ended(_value_changed: bool) -> void:
	_save()


func _on_fullscreen_toggled(enabled: bool) -> void:
	_apply_fullscreen(enabled)
	_save()


func _on_back_pressed() -> void:
	_save()
	if ResourceLoader.exists(back_scene):
		get_tree().change_scene_to_file(back_scene)
	else:
		push_warning("Back scene not found: %s" % back_scene)


# --- Helpers -----------------------------------------------------------------

func _update_volume_label(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value * 100.0)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", volume_slider.value)
	config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	config.save(SETTINGS_PATH)


## Call this once at game start (the main menu does) so saved settings
## are applied even if the player never opens the options screen.
static func apply_saved_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	_apply_volume(config.get_value("audio", "master_volume", 1.0))
	_apply_fullscreen(config.get_value("video", "fullscreen", false))


static func _apply_volume(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, value <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.0001)))


static func _apply_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)
