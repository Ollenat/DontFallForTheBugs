extends CharacterBody3D

@export var player: Node3D
@export var max_speed := 4.0
## Hur snabbt fienden når målhastigheten (enhet/s²)
@export var acceleration := 40.0
@export var separation_radius := 1.0
@export var separation_strength := 1.5
@export var gravity := 20.0

@onready var sprite: MeshInstance3D = $Sprite
@onready var shadow: MeshInstance3D = $Shadow
@onready var health: HealthComponent = $HealthComponent

var _separation := Vector2.ZERO
var _tick := 0
var _sprite_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemies")
	_tick = randi() % 4  # sprider ut separationsberäkningen mellan fiender
	_sprite_material = sprite.get_active_material(0) as StandardMaterial3D
	if _sprite_material:
		_sprite_material = _sprite_material.duplicate()
		_sprite_material.resource_local_to_scene = true
		sprite.material_override = _sprite_material
	health.died.connect(_on_died)
	if player == null:
		push_error("Player was not assigned on enemy")

func _on_died() -> void:
	if _sprite_material:
		_sprite_material.albedo_color = Color(1.0, 0.1, 0.1, 1.0)

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
	shadow.visible = is_on_floor()
	_update_sprite_facing()

func _update_sprite_facing() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera or not sprite:
		return

	var camera_right := camera.global_basis.x
	var enemy_to_player := player.global_position - global_position
	var screen_horizontal := enemy_to_player.dot(camera_right)
	if _sprite_material:
		if screen_horizontal > 0.0:
			_sprite_material.uv1_scale.x = -1.0
			_sprite_material.uv1_offset.x = 1.0
		else:
			_sprite_material.uv1_scale.x = 1.0
			_sprite_material.uv1_offset.x = 0.0

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
