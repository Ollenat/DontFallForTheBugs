extends Node3D

@export var player: Node3D
@export var speed: float = 5.0
@export var separation_radius: float = 0.8
@export var separation_strength: float = 1.2
@export var smoothness: float = 8.0

var _velocity: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Get the player's position
	var player_position = Vector2(player.global_position.x, player.global_position.z)
	var enemy_position = Vector2(global_position.x, global_position.z)

	# Get the direction from the enemy to the player
	var direction_to_player = (player_position - enemy_position).normalized()

	# Calculate separation from nearby enemies
	var separation = Vector2.ZERO
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child == self or not child is Node3D:
				continue
			var other_pos = Vector2(child.global_position.x, child.global_position.z)
			var diff = enemy_position - other_pos
			var dist = diff.length()
			if dist < separation_radius and dist > 0:
				separation += diff.normalized() / dist

	# Blend separation with direction to player
	var target_velocity = direction_to_player + separation * separation_strength
	target_velocity = target_velocity.normalized() * speed

	# Smoothly interpolate velocity toward target
	_velocity = _velocity.lerp(target_velocity, smoothness * delta)

	# Move the enemy using smoothed velocity
	global_position.x += _velocity.x * delta
	global_position.z += _velocity.y * delta
