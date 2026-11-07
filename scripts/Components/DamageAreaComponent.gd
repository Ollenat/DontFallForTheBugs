class_name DamageAreaComponent
extends Area3D

@export var damage: int = 10
## Seconds before the same target can be damaged again.
@export var cooldown: float = 0.5

# HealthComponent -> time (in seconds) when it can be hit again
var _next_hit: Dictionary = {}

func _ready() -> void:
	monitorable = false

func _physics_process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0

# Drop expired entries and freed targets so the dictionary doesn't grow
	for target in _next_hit.keys():
		if not is_instance_valid(target) or _next_hit[target] <= now:
			_next_hit.erase(target)
			
	for area in get_overlapping_areas():
		if area is HealthComponent and not _next_hit.has(area):
			area.damage(damage)
			print("damaging")
			_next_hit[area] = now + cooldown
