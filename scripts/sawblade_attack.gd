extends Node3D

@export var level_list: Array[SawbladeStats]
@export var orbiting_component: OrbitingComponent
@export var sawblade_scene: PackedScene

@export var starting_level = 1
@export var locked := true
var current_level = 1


func _ready() -> void:
	if locked:
		return
	set_level(starting_level)

func set_level(level: int) -> void:
	if locked or level_list.is_empty():
		return
	current_level = level

	var index = clamp(level-1, 0, len(level_list)-1)
	var stats: SawbladeStats = level_list[index]

	orbiting_component.rotation_speed = stats.speed
	orbiting_component.radius = stats.radius
	
	var list = orbiting_component.orbiters
	var target_amount := mini(12, stats.amount + maxi(0, level - level_list.size()))
	var n_diff = target_amount - list.size()
	if n_diff < 0:
		for i in range(-n_diff):
			orbiting_component.remove_last()
	else:
		for i in range(n_diff):
			var new_sawblade = sawblade_scene.instantiate()
			orbiting_component.add_orbiter(new_sawblade)

	for orbiter: Node3D in orbiting_component.orbiters:
		orbiter.scale = Vector3.ONE * stats.size
		#todo: rehit interval

func increase_blades() -> void:
	set_level(current_level + 1)

func unlock() -> void:
	if not locked:
		return
	locked = false
	set_level(starting_level)

func multiply_stat(stat: String, multiplier: float) -> void:
	if level_list.is_empty():
		return
	var stats: SawbladeStats = level_list[clamp(current_level - 1, 0, level_list.size() - 1)]
	match stat:
		"size":
			stats.size *= multiplier
		"speed":
			stats.speed *= multiplier
		"radius":
			stats.radius *= multiplier
	set_level(current_level)
