extends CharacterBody3D

@export var player: Node3D
@export var max_speed := 4.0
## Hur snabbt fienden når målhastigheten (enhet/s²)
@export var acceleration := 40.0
@export var separation_radius := 1.0
@export var separation_strength := 1.5
@export var gravity := 20.0

var _separation := Vector2.ZERO
var _tick := 0

func _ready() -> void:
	add_to_group("enemies")
	_tick = randi() % 4  # sprider ut separationsberäkningen mellan fiender
	if player == null:
		push_error("Player was not assigned on enemy")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var pos := Vector2(global_position.x, global_position.z)
	var player_pos := Vector2(player.global_position.x, player.global_position.z)
	var dir := pos.direction_to(player_pos)

	# Separation räknas var 4:e tick och återanvänds mellan tickarna
	_tick += 1
	if _tick % 4 == 0:
		_separation = _calc_separation(pos)

	# Blanda riktning mot spelaren med separation
	var target := (dir + _separation * separation_strength).limit_length(1.0) * max_speed

	# move_toward ger konstant acceleration mot målhastigheten
	var horizontal := Vector2(velocity.x, velocity.z)
	horizontal = horizontal.move_toward(target, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y

	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

func _calc_separation(pos: Vector2) -> Vector2:
	var result := Vector2.ZERO
	var r2 := separation_radius * separation_radius
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var diff := pos - Vector2(other.global_position.x, other.global_position.z)
		var d2 := diff.length_squared()
		if d2 < r2 and d2 > 0.0001:
			result += diff / maxf(d2, 0.01)
	return result