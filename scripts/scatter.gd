extends Node

@export var enemy_scene: PackedScene
@export var player_scene: Node3D
@export var enemy_count: int = 20
@export var plane_size: Vector2 = Vector2(50, 50)
@export var sky_spawn_height: float = 12.0

var _spawn_timer := 0.0
@onready var tower: Node3D = get_node_or_null("Tower")

func _ready() -> void:
	for i in range(enemy_count):
		_spawn_enemy(1.0, _get_current_floor_y())
	_schedule_next_spawn()

func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	var floor_y := _get_current_floor_y()
	_spawn_enemy(sky_spawn_height, floor_y)
	_schedule_next_spawn()

func _schedule_next_spawn() -> void:
	var floor_number := _get_current_floor_number()
	var spawn_rate := float(floor_number)
	_spawn_timer = -log(maxf(randf(), 0.0001)) / spawn_rate

func _get_current_floor_number() -> int:
	if not player_scene or not tower:
		return 1

	var floor_spacing: float = tower.get("floor_spacing")
	if floor_spacing <= 0.0:
		return 1

	return maxi(1, roundi(-player_scene.global_position.y / floor_spacing) + 1)

func _get_current_floor_y() -> float:
	var floor_spacing := 8.0
	if tower:
		floor_spacing = tower.get("floor_spacing")
	if floor_spacing <= 0.0:
		floor_spacing = 8.0

	return -float(_get_current_floor_number() - 1) * floor_spacing

func _get_arena_half_size() -> Vector2:
	if tower:
		var tower_size: float = tower.get("tower_size")
		if tower_size > 0.0:
			return Vector2.ONE * maxf(tower_size * 0.5 - 0.75, 0.5)

	return plane_size * 0.5

func _spawn_enemy(height: float, floor_y: float) -> void:
	var enemy = enemy_scene.instantiate() as Node3D
	enemy.player = player_scene
	var arena_half_size := _get_arena_half_size()
	var random_x = randf_range(-arena_half_size.x, arena_half_size.x)
	var random_z = randf_range(-arena_half_size.y, arena_half_size.y)
	add_child(enemy)
	enemy.global_position = Vector3(random_x, floor_y + height, random_z)
