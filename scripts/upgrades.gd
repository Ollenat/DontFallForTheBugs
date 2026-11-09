class_name UpgradeCatalog
extends RefCounted

const REPEATABLE: int = -1

static func all() -> Array[Dictionary]:
	return [
		_upgrade("swift_feet", "Swift Feet", "+5% movement speed", "movement_speed", 0.05, REPEATABLE),
		_upgrade("light_steps", "Light Steps", "+4% acceleration", "acceleration", 0.04, REPEATABLE),
		_upgrade("tough_skin", "Tough Skin", "+12 maximum health", "max_health", 12.0, REPEATABLE),
		_upgrade("quick_recovery", "Quick Recovery", "Recover 8 health", "heal", 8.0, REPEATABLE),
		_upgrade("steady_recovery", "Steady Recovery", "+0.5 health regenerated per second (up to 6)", "passive_regen", 0.5, 10),
		_upgrade("heavy_hitter", "Heavy Hitter", "+8% throw swatter and saw swatter damage", "damage", 0.08, REPEATABLE),
		_upgrade("rapid_fire", "Rapid Fire", "+8% throw swatter fire rate", "fire_rate", 0.08, REPEATABLE),
		_upgrade("throw_aoe", "Sweeping Throw", "+0.4m throw swatter impact area", "throw_aoe", 0.4, REPEATABLE),
		_upgrade("long_reach", "Long Reach", "+6% throw swatter targeting range", "target_range", 0.06, REPEATABLE),
		_upgrade("saw_swatter", "Saw Swatter", "Unlock a level 1 saw swatter", "sawblade_unlock", 1.0, 1),
		_upgrade("razor_edge", "Razor Edge", "+5% saw swatter size", "sawblade_size", 0.05, REPEATABLE),
		_upgrade("whirling_blades", "Whirling Blades", "+8% saw swatter orbit speed", "sawblade_speed", 0.08, REPEATABLE),
		_upgrade("wide_arc", "Wide Arc", "+6% saw swatter orbit radius", "sawblade_radius", 0.06, REPEATABLE),
		_upgrade("sturdy_frame", "Sturdy Frame", "+5% damage cooldown resistance", "cooldown", 0.05, REPEATABLE),
		_upgrade("sawblade", "Extra Saw Swatter", "Add another saw swatter (up to 12)", "sawblade_count", 1.0, 12),
		_upgrade("sawblade_mastery", "Saw Swatter Mastery", "Improve saw swatter handling (up to level 8)", "sawblade_level", 1.0, 8),
		_upgrade("magnetism", "Magnetism", "+10% throw swatter targeting range", "target_range", 0.10, REPEATABLE),
		_upgrade("overclock", "Overclock", "+12% throw swatter fire rate", "fire_rate", 0.12, REPEATABLE),
		_upgrade("berserker", "Berserker", "+10% damage", "damage", 0.10, REPEATABLE),
		_upgrade("vitality", "Vitality", "+25 maximum health", "max_health", 25.0, REPEATABLE),
		_upgrade("combat_training", "Combat Training", "+3% movement speed and damage", "combat_training", 0.03, REPEATABLE),
		_upgrade("blade_dancer", "Swatter Dancer", "+10% saw swatter speed and radius", "blade_dancer", 0.10, REPEATABLE),
	]

static func _upgrade(id: String, title: String, description: String, effect: String, amount: float, cap: int) -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"effect": effect,
		"amount": amount,
		"cap": cap,
	}

static func choose(levels: Dictionary, count: int = 3) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for upgrade in all():
		var level: int = int(levels.get(upgrade.id, 0))
		var requires_saw_swatter: bool = upgrade.effect in [
			"sawblade_size",
			"sawblade_speed",
			"sawblade_radius",
			"sawblade_count",
			"sawblade_level",
			"blade_dancer",
		]
		if requires_saw_swatter and int(levels.get("saw_swatter", 0)) == 0:
			continue
		if upgrade.cap == REPEATABLE or level < int(upgrade.cap):
			available.append(upgrade)

	var result: Array[Dictionary] = []
	while not available.is_empty() and result.size() < count:
		var total_weight: int = 0
		for upgrade in available:
			total_weight += _selection_weight(upgrade)
		var roll: int = randi_range(1, total_weight)
		var choice: Dictionary = available[0]
		for upgrade in available:
			roll -= _selection_weight(upgrade)
			if roll <= 0:
				choice = upgrade
				break
		result.append(choice)
		available.erase(choice)

	return result

static func _selection_weight(upgrade: Dictionary) -> int:
	if upgrade.id == "saw_swatter":
		return 6
	if upgrade.effect in [
		"damage",
		"fire_rate",
		"throw_aoe",
		"cooldown",
		"sawblade_size",
		"sawblade_speed",
		"sawblade_radius",
		"sawblade_count",
		"sawblade_level",
		"blade_dancer",
	]:
		return 4
	return 1
