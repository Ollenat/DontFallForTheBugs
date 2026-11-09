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
@export var explosion_radius: float = 0.0
@export var damage: int = 100
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
	area.damage(damage)
	if explosion_radius > 0.0:
		_damage_nearby_enemies(area)
	set_process(false)
	var visual := get_node_or_null("ProjectileVisual") as ProjectileVisual
	if visual:
		visual.smack_finished.connect(queue_free, CONNECT_ONE_SHOT)
		visual.play_smack()
	else:
		queue_free()

func _damage_nearby_enemies(primary: HealthComponent) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy_node: Node in enemies:
		var enemy: Node3D = enemy_node as Node3D
		if not enemy or enemy.global_position.distance_to(global_position) > explosion_radius:
			continue
		var enemy_health := enemy.get_node_or_null("HealthComponent") as HealthComponent
		if enemy_health and enemy_health != primary:
			enemy_health.damage(damage)

func _process(delta: float) -> void:
	global_position += direction * speed * delta
