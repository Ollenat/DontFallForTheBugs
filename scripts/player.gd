extends CharacterBody3D

@export var health: HealthComponent
@export var auto_fire: AutoFireComponent
@export var movement: MovementComponent
@export var upgrades: PlayerUpgradeComponent
@export var health_hud: PlayerHealthHud
@export var game_over: PlayerGameOver

func _ready() -> void:
	health = health if health else get_node_or_null("HealthComponent") as HealthComponent
	auto_fire = auto_fire if auto_fire else get_node_or_null("AutoFireComponent") as AutoFireComponent
	movement = movement if movement else get_node_or_null("MovementComponent") as MovementComponent
	upgrades = upgrades if upgrades else get_node_or_null("PlayerUpgradeComponent") as PlayerUpgradeComponent
	health_hud = health_hud if health_hud else get_node_or_null("PlayerHealthHud") as PlayerHealthHud
	game_over = game_over if game_over else get_node_or_null("PlayerGameOver") as PlayerGameOver

	if health == null:
		health = HealthComponent.new()
		health.max_health = 100
		add_child(health)
	health.auto_free_on_death = false
	if movement:
		movement.health = health

	if upgrades:
		upgrades.configure(self, health, movement, auto_fire)
	if health_hud:
		health_hud.health = health
	if game_over:
		game_over.configure(self, upgrades)

func apply_upgrade(upgrade: Dictionary) -> void:
	if upgrades:
		upgrades.apply_upgrade(upgrade)
