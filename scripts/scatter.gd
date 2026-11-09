extends Node

@export var enemy_scene: PackedScene
@export var player_scene: Node3D
@export var enemy_count: int = 20
@export var plane_size: Vector2 = Vector2(50, 50)
@export var sky_spawn_interval := Vector2(4.0, 9.0)
@export var sky_spawn_height: float = 12.0

var _spawn_timer := 0.0

func _ready() -> void:
	for i in range(enemy_count):
		_spawn_enemy(1.0)
	_spawn_timer = randf_range(sky_spawn_interval.x, sky_spawn_interval.y)

func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	_spawn_enemy(sky_spawn_height)
	_spawn_timer = randf_range(sky_spawn_interval.x, sky_spawn_interval.y)

func _spawn_enemy(height: float) -> void:
	var enemy = enemy_scene.instantiate() as Node3D
	enemy.player = player_scene
	var random_x = randf_range(-plane_size.x / 2, plane_size.x / 2)
	var random_z = randf_range(-plane_size.y / 2, plane_size.y / 2)
	add_child(enemy)
	enemy.global_position = Vector3(random_x, height, random_z)
