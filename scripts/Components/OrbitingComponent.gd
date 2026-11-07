class_name OrbitingComponent
extends Node3D

@export var radius := 2.5
@export var rotation_speed := 3.0

@export var orbiters: Array[Node3D] = []
var _angle := 0.0

func add_orbiter(node: Node3D) -> void:
    orbiters.append(node)
    add_child(node)

func remove_last() -> void:
    if orbiters.is_empty():
        return
    orbiters.pop_back().queue_free()

func _physics_process(delta: float) -> void:
    _angle = wrapf(_angle + rotation_speed * delta, 0.0, TAU)
    var n := orbiters.size()
    for i in n:
        var a := _angle + TAU * i / n
        orbiters[i].position = Vector3(cos(a), position.y, sin(a)) * radius