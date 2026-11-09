extends Node

@export var enemy_scene: PackedScene
@export var player_scene: Node3D
@export var enemy_count: int = 0
@export var max_enemies: int = 100
@export var plane_size: Vector2 = Vector2(50, 50)
@export var sky_spawn_height: float = 12.0
@export var special_spawn_interval: float = 10.0

var _spawn_timer := 0.0
var _special_spawn_timer := special_spawn_interval
@onready var tower: Node3D = get_node_or_null("Tower")

func _ready() -> void:
	for i in range(mini(enemy_count, max_enemies)):
		_spawn_enemy(1.0, _get_current_floor_y(), false)
	_schedule_next_spawn()

func _process(delta: float) -> void:
	_spawn_timer -= delta
	_special_spawn_timer -= delta

	if _spawn_timer <= 0.0:
		if _get_active_enemy_count() < max_enemies:
			var floor_y: float = _get_current_floor_y()
			_spawn_enemy(sky_spawn_height, floor_y, false)
		_schedule_next_spawn()

	if _special_spawn_timer <= 0.0:
		if _get_active_enemy_count() < max_enemies:
			var floor_y: float = _get_current_floor_y()
			_spawn_enemy(sky_spawn_height, floor_y, true)
		_special_spawn_timer = special_spawn_interval

func _get_active_enemy_count() -> int:
	var active_count := 0
	for child in get_children():
		if child.is_in_group("enemies"):
			active_count += 1
	return active_count

func _schedule_next_spawn() -> void:
	var floor_number := _get_current_floor_number()
	var spawn_rate: float = 1.0 * pow(1.2, floor_number - 1)
	_spawn_timer = 1.0 / spawn_rate

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

func _spawn_enemy(height: float, floor_y: float, special: bool) -> void:
	if _get_active_enemy_count() >= max_enemies:
		return

	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	enemy.player = player_scene
	enemy.is_special = special
	var arena_half_size := _get_arena_half_size()
	var random_x = randf_range(-arena_half_size.x, arena_half_size.x)
	var random_z = randf_range(-arena_half_size.y, arena_half_size.y)
	add_child(enemy)
	enemy.global_position = Vector3(random_x, floor_y + height, random_z)
