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

func _ready() -> void:
    print(direction)
    monitorable = false # ingen behöver känna av projektilen
    area_entered.connect(_on_area_entered)
    get_tree().create_timer(3.0).timeout.connect(queue_free)

func _on_area_entered(area: Area3D) -> void:
    if area is HealthComponent:
        area.damage(100)
        queue_free()

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta