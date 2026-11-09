@tool
class_name PickCard
extends Button

## Emitted when this card is clicked, or activated with keyboard / gamepad.
signal picked(card: PickCard)

@export var card_title: String = "Card":
	set(value):
		card_title = value
		_refresh()

@export_multiline var card_description: String = "Card description.":
	set(value):
		card_description = value
		_refresh()

## Optional picture shown on the left. If empty, only the colour is shown.
@export var card_icon: Texture2D:
	set(value):
		card_icon = value
		_refresh()

## Background colour of the art area on the left.
@export var art_color: Color = Color(0.3, 0.45, 0.8):
	set(value):
		art_color = value
		_refresh()

@onready var _title: Label = %CardTitle
@onready var _description: Label = %CardDescription
@onready var _art: ColorRect = %Art
@onready var _icon: TextureRect = %Icon


func _ready() -> void:
	_refresh()
	if not Engine.is_editor_hint():
		pressed.connect(func() -> void: picked.emit(self))


func _refresh() -> void:
	# Setters can run before the node is ready (and in the editor), so guard.
	if _title == null:
		return
	_title.text = card_title
	_description.text = card_description
	_icon.texture = card_icon
	_art.color = art_color
