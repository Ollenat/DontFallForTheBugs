extends Area3D
class_name HealthComponent

@export var max_health: int = 100
@export var death_delay: float = 0.0
@export var auto_free_on_death: bool = true
@export var invincibility_duration: float = 0.0
@export var passive_regen_per_second: float = 0.0
@export var damage_number_color: Color = Color.WHITE
var current_health: int
var _invincible_until: int = 0
var _regen_remainder := 0.0

signal died()
signal damaged(old_health: int, new_health: int) # Emits everytime
signal healed(old_health: int, new_health: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health;
	monitoring = false
	monitorable = true

func _process(delta: float) -> void:
	if passive_regen_per_second <= 0.0 or current_health <= 0 or current_health >= max_health:
		return
	_regen_remainder += passive_regen_per_second * delta
	if _regen_remainder < 1.0:
		return
	var amount := floori(_regen_remainder)
	_regen_remainder -= amount
	heal(amount)

func damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return
	var now := Time.get_ticks_msec()
	if now < _invincible_until:
		return
	_invincible_until = now + roundi(invincibility_duration * 1000.0)
	var old := current_health
	current_health = max(0, current_health - amount)
	DamageNumbers.spawn(amount, global_position + Vector3.UP * 1.1, damage_number_color)
	damaged.emit(old, current_health)
	if current_health == 0:
		died.emit()
		if not auto_free_on_death:
			return
		if death_delay > 0.0:
			get_tree().create_timer(death_delay).timeout.connect(get_parent().queue_free)
		else:
			get_parent().queue_free() # temp

func grant_invincibility(duration: float) -> void:
	var now: int = Time.get_ticks_msec()
	_invincible_until = maxi(_invincible_until, now + roundi(duration * 1000.0))
			

func heal(amount: int) -> void:
	var old := current_health
	current_health = min(max_health, current_health + amount)
	if amount != 0:
		healed.emit(old, current_health)
