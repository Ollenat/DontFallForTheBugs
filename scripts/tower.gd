@tool
extends Node3D

@export var floor_scene: PackedScene = preload("res://scenes/Floor.tscn")
@export var player: CharacterBody3D

@export var tower_size: float = 20.0:  ## Total width and depth (Square)
	set(value):
		tower_size = max(value, 2.0)
		_sync_walls_geometry()

@export var floor_spacing: float = 8.0
@export var floors_buffer: int = 5
@export_range(0, 20, 1) var editor_floor_count: int = 5
@export_range(1, 100000, 1) var max_debris: int = 800
@export var texture_density: float = 0.5
@export var floor_texture_pool: Array[Texture2D] = []

@onready var top_floor_pos: Node3D = $TopFloorPos
@onready var floors_container: Node3D = $Floors

var active_floors: Array[Node3D] = []
var debris: Array[RigidBody3D] = []
var next_floor_y: float = 0.0
var wall_height: float = 300.0

func _ready() -> void:
	if not floors_container:
		floors_container = Node3D.new()
		floors_container.name = "Floors"
		add_child(floors_container)

	_sync_walls_geometry()

	if Engine.is_editor_hint():
		_spawn_editor_preview_floors()
	else:
		next_floor_y = 0.0
		for i in range(floors_buffer):
			_spawn_next_floor()
		_update_facade()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if player and (player.global_position.y - next_floor_y < floors_buffer * floor_spacing * 0.75):
		_spawn_next_floor()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			break_highest_floor()

func break_highest_floor() -> void:
	var unbroken = active_floors.filter(func(f): return is_instance_valid(f) and not f.is_broken)
	if unbroken.is_empty():
		return

	unbroken.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)
	unbroken[0].break_floor()
	_wake_debris()
	# Keep the tower extending downward whenever a floor is consumed.
	_spawn_next_floor()
	_update_facade()

func register_debris(piece: RigidBody3D) -> void:
	debris.append(piece)
	_prune_debris()

	while debris.size() > max_debris:
		var random_index := randi_range(0, debris.size() - 1)
		var random_piece = debris.pop_at(random_index)
		if is_instance_valid(random_piece):
			schedule_debris_removal(random_piece)

func _prune_debris() -> void:
	debris = debris.filter(func(piece): return is_instance_valid(piece))

func schedule_debris_removal(piece: RigidBody3D) -> void:
	if not is_instance_valid(piece) or piece.get_meta("removal_scheduled", false):
		return

	piece.set_meta("removal_scheduled", true)
	get_tree().create_timer(randf_range(0.0, 5.0)).timeout.connect(
		func(): _remove_debris(piece)
	)

func _remove_debris(piece: RigidBody3D) -> void:
	if not is_instance_valid(piece):
		return

	_emit_debris_particles(piece.global_position)
	piece.queue_free()

func _emit_debris_particles(world_position: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 12
	particles.lifetime = 0.45
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.local_coords = false
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 2.5
	particles.gravity = Vector3(0.0, -4.0, 0.0)
	particles.scale_amount_min = 0.03
	particles.scale_amount_max = 0.08

	var particle_material := StandardMaterial3D.new()
	particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_material.albedo_color = Color(0.75, 0.75, 0.75)
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.04
	particle_mesh.height = 0.08
	particle_mesh.material = particle_material
	particles.mesh = particle_mesh

	add_child(particles)
	particles.global_position = world_position
	particles.emitting = true
	get_tree().create_timer(particles.lifetime).timeout.connect(particles.queue_free)

func _wake_debris() -> void:
	_prune_debris()
	for piece in debris:
		piece.sleeping = false
		piece.apply_central_impulse(Vector3.DOWN * 0.1)
		piece.apply_torque_impulse(Vector3(
			randf_range(-0.2, 0.2),
			randf_range(-0.2, 0.2),
			randf_range(-0.2, 0.2)
		))

func _spawn_next_floor() -> void:
	var new_floor = floor_scene.instantiate() as StaticBody3D
	floors_container.add_child(new_floor)

	new_floor.scale = Vector3(tower_size * 0.5, 1.0, tower_size * 0.5)
	new_floor.global_position = Vector3(0.0, next_floor_y, 0.0)

	if "texture_density" in new_floor:
		new_floor.texture_density = texture_density

	if not floor_texture_pool.is_empty():
		new_floor.floor_texture = floor_texture_pool.pick_random()

	active_floors.append(new_floor)
	next_floor_y -= floor_spacing

func _spawn_editor_preview_floors() -> void:
	for child in floors_container.get_children():
		child.free()

	active_floors.clear()
	next_floor_y = 0.0
	for i in range(editor_floor_count):
		_spawn_next_floor()

func _sync_walls_geometry() -> void:
	var h: float = tower_size * 0.5
	var top_floor_node := get_node_or_null("TopFloorPos") as Node3D
	if not top_floor_node:
		return

	# Back walls (interior backdrop)
	_configure_wall(top_floor_node.get_node_or_null("BackWallN"), Vector3(0.0, 0.0, -h), Vector3(0.0, 0.0, 0.0))
	_configure_wall(top_floor_node.get_node_or_null("BackWallW"), Vector3(-h, 0.0, 0.0), Vector3(0.0, 90.0, 0.0))

	# Front facade walls (covering lower tiers toward camera)
	_configure_wall(top_floor_node.get_node_or_null("FrontWallS"), Vector3(0.0, 0.0, h), Vector3(0.0, 0.0, 0.0))
	_configure_wall(top_floor_node.get_node_or_null("FrontWallE"), Vector3(h, 0.0, 0.0), Vector3(0.0, 90.0, 0.0))

func _configure_wall(wall: MeshInstance3D, pos: Vector3, rot_deg: Vector3) -> void:
	if not wall:
		return
	wall.position.x = pos.x
	wall.position.z = pos.z
	wall.rotation_degrees = rot_deg

	var qm = wall.mesh as QuadMesh
	if not qm:
		qm = QuadMesh.new()
		wall.mesh = qm
	qm.size = Vector2(tower_size, wall_height)

func _update_facade() -> void:
	if not top_floor_pos:
		return

	var unbroken = active_floors.filter(func(f): return is_instance_valid(f) and not f.is_broken)
	if unbroken.is_empty():
		return

	unbroken.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)
	var top_floor_y: float = unbroken[0].global_position.y
	top_floor_pos.position.y = top_floor_y
