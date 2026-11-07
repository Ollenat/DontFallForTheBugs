extends CharacterBody3D

@export var health: HealthComponent
@export var auto_fire: AutoFireComponent
@export var movement: MovementComponent


func _unhandled_input(event: InputEvent) -> void:
	# Using Godot's built-in "ui_accept" (mapped to Space/Enter by default)
	# or checking the physical key directly:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			break_highest_floor()

func break_highest_floor() -> void:
	var floors = get_tree().get_nodes_in_group("floors")
	
	# Only consider active, unbroken floors
	var unbroken_floors = floors.filter(func(f): return not f.is_broken)
	if unbroken_floors.is_empty():
		print("No more floors left to break!")
		return

	# Sort descending by Y (highest position at index 0)
	unbroken_floors.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)

	# Shatter the highest floor
	unbroken_floors[0].break_floor()