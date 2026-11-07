extends Area3D
class_name HealthComponent

@export var max_health: int = 100
var current_health: int

signal died()
signal damaged(old_health: int, new_health: int) # Emits everytime
signal healed(old_health: int, new_health: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health;
	monitoring = false
	monitorable = true

func damage(amount: int) -> void:
	var old := current_health
	current_health = max(0, current_health - amount)
	if current_health == 0:
		died.emit()
		get_parent().queue_free() #temp
	elif amount != 0:
			damaged.emit(old, current_health)

func heal(amount: int) -> void:
	var old := current_health
	current_health = min(max_health, current_health + amount)
	if amount != 0:
		healed.emit(old, current_health)
