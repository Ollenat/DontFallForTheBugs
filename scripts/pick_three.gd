extends Control

const MAIN_MENU_THEME: Theme = preload("res://themes/Text_theme.tres")

## Emitted after the player picks a card and the cards have slid away.
## `index` is the card's position: 0, 1 or 2 (top to bottom).
signal card_picked(index: int)

## How long one card takes to slide.
@export var card_slide_time: float = 0.45
## Delay between one card starting and the next one starting.
@export var card_stagger: float = 0.15

@onready var cards_list: VBoxContainer = %Cards
## The area that clips the cards, so they appear to slide out from the
## banner's edge instead of flying across the whole screen.
@onready var clip_area: Control = %CardArea

var _locked := false


func _ready() -> void:
	theme = MAIN_MENU_THEME
	for card in cards_list.get_children():
		if card is PickCard:
			card.picked.connect(_on_card_picked)
	slide_in()


## Slides the cards down into the banner, one by one. The banner stays put.
func slide_in() -> void:
	_locked = true # ignore clicks while sliding

	# Hide the cards, then let the container put them back in their slots.
	var cards: Array[Node] = cards_list.get_children()
	for card in cards:
		card.modulate.a = 0.0
	cards_list.queue_sort()
	await get_tree().process_frame

	# Bottom card first, so a card never slides across one that already landed.
	cards.reverse()
	var targets: Array[float] = []
	var start_positions: Array[float] = []
	for card in cards:
		var rest_y: float = card.position.y
		targets.append(rest_y)
		start_positions.append(rest_y - _distance_above(card))
	for i in cards.size():
		var card: Control = cards[i]
		card.position.y = start_positions[i] # start above the banner
		card.modulate.a = 1.0
	await _animate_cards(cards, targets, Tween.EASE_OUT)

	_locked = false
	cards_list.get_child(0).grab_focus() # keyboard / gamepad can start right away


## Slides the cards down and out of the banner, one by one.
func slide_out() -> void:
	var cards: Array[Node] = cards_list.get_children()
	cards.reverse() # bottom card leaves first
	var targets: Array[float] = []
	for card in cards:
		targets.append(card.position.y + _distance_below(card))
	await _animate_cards(cards, targets, Tween.EASE_IN)

func _animate_cards(cards: Array[Node], targets: Array[float], ease_type: Tween.EaseType) -> void:
	var starts: Array[float] = []
	for card in cards:
		starts.append((card as Control).position.y)
	var started: int = Time.get_ticks_msec()
	var total_duration: float = card_slide_time + card_stagger * float(maxi(cards.size() - 1, 0))
	while true:
		var elapsed: float = float(Time.get_ticks_msec() - started) / 1000.0
		if elapsed >= total_duration:
			break
		for i in cards.size():
			var card: Control = cards[i]
			var local_time: float = clampf((elapsed - float(i) * card_stagger) / card_slide_time, 0.0, 1.0)
			var eased: float = float(Tween.interpolate_value(0.0, 1.0, local_time, 1.0, Tween.TRANS_CUBIC, ease_type))
			card.position.y = lerpf(starts[i], targets[i], eased)
		await get_tree().process_frame
	for i in cards.size():
		(cards[i] as Control).position.y = targets[i]

func _wait_real_seconds(seconds: float) -> void:
	var started: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - started) / 1000.0 < seconds:
		await get_tree().process_frame


# How far a card must move up to be completely hidden above the banner.
func _distance_above(card: Control) -> float:
	return card.get_global_rect().end.y - clip_area.get_global_rect().position.y + 4.0


# How far a card must move down to be completely hidden below the banner.
func _distance_below(card: Control) -> float:
	return clip_area.get_global_rect().end.y - card.get_global_rect().position.y + 4.0


func _on_card_picked(card: PickCard) -> void:
	if _locked:
		return
	_locked = true

	# Highlight the picked card and fade the others.
	card.grab_focus()
	for other in cards_list.get_children():
		if other != card:
			_fade_card(other as Control)

	await _wait_real_seconds(0.6)
	await slide_out()
	card_picked.emit(card.get_index())

func _fade_card(card: Control) -> void:
	var start_alpha: float = card.modulate.a
	var started: int = Time.get_ticks_msec()
	while true:
		var weight: float = clampf(float(Time.get_ticks_msec() - started) / 250.0, 0.0, 1.0)
		card.modulate.a = lerpf(start_alpha, 0.25, weight)
		if weight >= 1.0:
			return
		await get_tree().process_frame
