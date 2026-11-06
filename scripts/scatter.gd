extends Node

@export var enemy_scene: PackedScene
@export var player_scene: Node3D
@export var enemy_count: int = 20
@export var plane_size: Vector2 = Vector2(50, 50)

func _ready() -> void:
	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate() as Node3D
		enemy.player = player_scene
		var random_x = randf_range(-plane_size.x / 2, plane_size.x / 2)
		var random_z = randf_range(-plane_size.y / 2, plane_size.y / 2)
		add_child(enemy)
		enemy.global_position = Vector3(random_x, 1, random_z)
