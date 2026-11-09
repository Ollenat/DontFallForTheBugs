class_name AutoFireComponent
extends Node3D

#todo:
	# derivable projectiles e.g homing projectile component, orbiting projectile component


@export var projectile_scene: PackedScene
@export var closest_entity_component: ClosestEntityComponent
## projectiles per second
@export var firing_rate: int = 1
var timer: Timer

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)

	timer.wait_time = 1.0 / firing_rate
	timer.timeout.connect(fire)
	timer.start()

func fire():
	if closest_entity_component.closest_target != null:
		var p := projectile_scene.instantiate() as StraightProjectileComponent
		if p == null:
				push_error("projectile_scene root must be a Projectile")
				return
		
		var dir = global_position.direction_to(closest_entity_component.closest_target.global_position)
		print(dir)
		get_tree().root.add_child(p)
		p.direction = dir
		p.global_position = self.global_position
