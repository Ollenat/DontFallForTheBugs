extends Control

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
	for card in cards_list.get_children():
		if card is PickCard:
			card.picked.connect(_on_card_picked)
	slide_in()


## Slides the cards down into the banner, one by one. The banner stays put.
func slide_in() -> void:
	_locked = true # ignore clicks while sliding

	# Hide the cards, then let the container put them back in their slots.
	var cards := cards_list.get_children()
	for card in cards:
		card.modulate.a = 0.0
	cards_list.queue_sort()
	await get_tree().process_frame

	# Bottom card first, so a card never slides across one that already landed.
	cards.reverse()
	var tween := create_tween().set_parallel(true)
	for i in cards.size():
		var card: Control = cards[i]
		var rest_y := card.position.y
		card.position.y = rest_y - _distance_above(card) # start above the banner
		card.modulate.a = 1.0
		tween.tween_property(card, "position:y", rest_y, card_slide_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) \
			.set_delay(i * card_stagger)
	await tween.finished

	_locked = false
	cards_list.get_child(0).grab_focus() # keyboard / gamepad can start right away


## Slides the cards down and out of the banner, one by one.
func slide_out() -> void:
	var cards := cards_list.get_children()
	cards.reverse() # bottom card leaves first
	var tween := create_tween().set_parallel(true)
	for i in cards.size():
		var card: Control = cards[i]
		tween.tween_property(card, "position:y", card.position.y + _distance_below(card), card_slide_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN) \
			.set_delay(i * card_stagger)
	await tween.finished


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
			create_tween().tween_property(other, "modulate:a", 0.25, 0.25)

	await get_tree().create_timer(0.6).timeout
	await slide_out()
	card_picked.emit(card.get_index())
