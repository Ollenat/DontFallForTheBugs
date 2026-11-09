extends CharacterBody3D
class_name Enemy

const GOLD_TEXTURE: Texture2D = preload("res://textures/PNG/Spider/Spider_gold.png")

@export var player: Node3D
@export var max_speed := 4.0
## Hur snabbt fienden når målhastigheten (enhet/s²)
@export var acceleration := 40.0
@export var separation_radius := 1.0
@export var separation_strength := 1.5
@export var gravity := 20.0
@export var contact_damage := 10
@export var is_special := false
@export var special_health_multiplier := 2.0
@export var special_speed_multiplier := 1.35
@export var special_damage_multiplier := 1.5

@onready var sprite: MeshInstance3D = $Sprite
@onready var shadow: MeshInstance3D = $Shadow
@onready var health: HealthComponent = $HealthComponent

var _separation := Vector2.ZERO
var _tick := 0
var _kill_reported := false
var _sprite_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemies")
	if is_special:
		max_speed *= special_speed_multiplier
		contact_damage = roundi(float(contact_damage) * special_damage_multiplier)
		health.max_health = roundi(float(maxi(health.max_health, 100)) * special_health_multiplier)
		health.current_health = health.max_health
	_tick = randi() % 4  # sprider ut separationsberäkningen mellan fiender
	_sprite_material = sprite.get_active_material(0) as StandardMaterial3D
	if _sprite_material:
		_sprite_material = _sprite_material.duplicate()
		_sprite_material.resource_local_to_scene = true
		sprite.material_override = _sprite_material
		if is_special:
			_sprite_material.albedo_texture = GOLD_TEXTURE
	health.died.connect(_on_died)
	if player == null:
		push_error("Player was not assigned on enemy")

func _on_died() -> void:
	if _kill_reported:
		return
	_kill_reported = true
	if _sprite_material:
		_sprite_material.albedo_color = Color(1.0, 0.1, 0.1, 1.0)
	var tower := get_tree().get_first_node_in_group("tower")
	if tower and tower.has_method("register_enemy_kill"):
		tower.register_enemy_kill()
	if is_special and tower and tower.has_method("register_special_kill"):
		tower.register_special_kill()

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
	_damage_player_on_contact()
	shadow.visible = is_on_floor()
	_update_sprite_facing()

func _damage_player_on_contact() -> void:
	for index in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider() as Node
		if not collider:
			continue
		var player_health := collider.get_node_or_null("HealthComponent") as HealthComponent
		if player_health:
			player_health.damage(contact_damage)

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
