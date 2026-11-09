extends Area3D
class_name StraightProjectileComponent

## todo:
	# damage
	# speed
	# properties in a resource

var direction: Vector3:
	set(d):
		direction = d.normalized()
@export var speed: float = 100
var has_hit := false

func _ready() -> void:
	print(direction)
	monitorable = false # ingen behöver känna av projektilen
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _on_area_entered(area: Area3D) -> void:
	if has_hit or not area is HealthComponent:
		return

	has_hit = true
	area.damage(100)
	set_process(false)
	var visual := get_node_or_null("ProjectileVisual") as ProjectileVisual
	if visual:
		visual.smack_finished.connect(queue_free, CONNECT_ONE_SHOT)
		visual.play_smack()
	else:
		queue_free()

func _process(delta: float) -> void:
	global_position += direction * speed * delta
