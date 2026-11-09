class_name PlayerUpgradeComponent
extends Node

var upgrade_levels: Dictionary = {}
var damage_multiplier := 1.0
var cooldown_multiplier := 1.0
var _player: CharacterBody3D
var _health: HealthComponent
var _movement: MovementComponent
var _auto_fire: AutoFireComponent

func configure(player: CharacterBody3D, health: HealthComponent, movement: MovementComponent, auto_fire: AutoFireComponent) -> void:
	_player = player
	_health = health
	_movement = movement
	_auto_fire = auto_fire

func apply_upgrade(upgrade: Dictionary) -> void:
	var id: String = upgrade.id
	upgrade_levels[id] = int(upgrade_levels.get(id, 0)) + 1
	var effect: String = upgrade.effect
	var amount: float = float(upgrade.amount)

	match effect:
		"movement_speed":
			_movement.move_speed *= 1.0 + amount
		"acceleration":
			_movement.acceleration *= 1.0 + amount
		"max_health":
			_health.max_health += int(amount)
			_health.current_health += int(amount)
		"heal":
			_health.heal(int(amount))
		"passive_regen":
			_health.passive_regen_per_second = minf(
				_health.passive_regen_per_second + amount,
				6.0
			)
		"damage":
			damage_multiplier *= 1.0 + amount
			_apply_sawblade_damage()
		"cooldown":
			cooldown_multiplier *= 1.0 - amount
			_apply_sawblade_cooldown()
		"fire_rate":
			_auto_fire.firing_rate = maxi(1, roundi(float(_auto_fire.firing_rate) * (1.0 + amount)))
			_auto_fire.refresh_rate()
		"throw_aoe":
			_auto_fire.explosion_radius += amount
		"target_range":
			var target_area := _player.get_node_or_null("ClosestEntityComponent") as Area3D
			if target_area:
				target_area.scale *= 1.0 + amount
		"sawblade_unlock":
			var sawblade := _player.get_node_or_null("SawbladeAttack")
			if sawblade and sawblade.has_method("unlock"):
				sawblade.unlock()
		"sawblade_size":
			_apply_sawblade_stat("size", amount)
		"sawblade_speed":
			_apply_sawblade_stat("speed", amount)
		"sawblade_radius":
			_apply_sawblade_stat("radius", amount)
		"sawblade_count":
			var sawblade := _player.get_node_or_null("SawbladeAttack")
			if sawblade and sawblade.has_method("increase_blades"):
				sawblade.increase_blades()
		"sawblade_level":
			var sawblade := _player.get_node_or_null("SawbladeAttack")
			if sawblade and sawblade.has_method("set_level"):
				sawblade.set_level(sawblade.current_level + 1)
		"combat_training":
			_movement.move_speed *= 1.0 + amount
			damage_multiplier *= 1.0 + amount
			_apply_sawblade_damage()
		"blade_dancer":
			_apply_sawblade_stat("speed", amount)
			_apply_sawblade_stat("radius", amount)

func _apply_sawblade_damage() -> void:
	var sawblade := _player.get_node_or_null("SawbladeAttack")
	if not sawblade:
		return
	for blade in sawblade.orbiting_component.orbiters:
		var damage_area := blade.get_node_or_null("DamageAreaComponent") as DamageAreaComponent
		if damage_area:
			damage_area.damage = roundi(10.0 * damage_multiplier)

func _apply_sawblade_cooldown() -> void:
	var sawblade := _player.get_node_or_null("SawbladeAttack")
	if not sawblade:
		return
	for blade in sawblade.orbiting_component.orbiters:
		var damage_area := blade.get_node_or_null("DamageAreaComponent") as DamageAreaComponent
		if damage_area:
			damage_area.cooldown = maxf(0.05, 0.5 * cooldown_multiplier)

func _apply_sawblade_stat(stat: String, percent: float) -> void:
	var sawblade := _player.get_node_or_null("SawbladeAttack")
	if sawblade and sawblade.has_method("multiply_stat"):
		sawblade.multiply_stat(stat, 1.0 + percent)
