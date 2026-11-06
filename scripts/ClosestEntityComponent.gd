class_name ClosestEntityComponent
extends Area3D

@export var closest_target: Node3D

#Updates closest target every 0.2 seconds
@export var interval: float = 0.2:
    set(i):
        interval = abs(i)
        timer.wait_time = i


@onready var targets: Array[Node3D]
@onready var timer: Timer

func _ready() -> void:
    body_entered.connect(func(body): targets.append(body))
    body_exited.connect(func(body): targets.erase(body))
    
    
    timer.wait_time = interval
    timer.timeout.connect(fire)
    timer.start()


func get_nearest() -> Node3D:
    var best: Node3D = null
    var best_dist := INF
    for t in targets:
        var d := global_position.distance_squared_to(t.global_position)
        if d < best_dist:
            best_dist = d
        best = t
    return best


func fire() -> void:
    targets = targets.filter(func(t): return is_instance_valid(t))
    closest_target = get_nearest()
