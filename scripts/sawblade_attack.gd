extends Node3D

@export var level_list: Array[SawbladeStats]
@export var orbiting_component: OrbitingComponent
@export var sawblade_scene: PackedScene

@export var starting_level = 1
var current_level = 1


func _ready() -> void:
	set_level(starting_level)

func set_level(level: int) -> void:
	if level_list.is_empty():
		return
	current_level = level

	var index = clamp(level-1, 0, len(level_list)-1)
	var stats = level_list[index]

	orbiting_component.rotation_speed = stats.speed
	orbiting_component.radius = stats.radius
	
	var list = orbiting_component.orbiters
	var n_orbiters = len(list)
	var n_diff = stats.amount - n_orbiters
	for i in range(0, n_diff):
		if n_diff < 0:
			orbiting_component.orbiters.pop_back()
		else:
			var new_sawblade = sawblade_scene.instantiate()
			orbiting_component.add_orbiter(new_sawblade)

	for orbiter: Node3D in list:
		orbiter.scale = Vector3.ONE * stats.size
		#todo: rehit interval
