@tool
extends StaticBody3D

@export var floor_texture: Texture2D:
	set(value):
		floor_texture = value
		_update_visuals()

@export var texture_density: float = 1.0:
	set(value):
		texture_density = max(value, 0.01)
		_update_visuals()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_broken: bool = false

func _enter_tree() -> void:
	set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_visuals()

func _ready() -> void:
	_update_visuals()
	if not Engine.is_editor_hint():
		add_to_group("floors")

func _update_visuals() -> void:
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		return

	var mat = mesh_instance.material_override as StandardMaterial3D
	if not mat:
		return

	if not mat.resource_local_to_scene:
		mat = mat.duplicate()
		mat.resource_local_to_scene = true
		mesh_instance.material_override = mat

	mat.albedo_texture = floor_texture
	var sx: float = abs(scale.x) * texture_density
	var sz: float = abs(scale.z) * texture_density
	mat.uv1_scale = Vector3(sx, sz, 1.0)


## Call this function from your Player or GameManager when leveling up
func break_floor(grid_divisions: int = 20) -> void:
	if is_broken or Engine.is_editor_hint():
		return
	is_broken = true

	# 1. Disable collision instantly so the player falls through
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	# 2. Hide the intact floor
	if mesh_instance:
		mesh_instance.visible = false

	# 3. Spawn physics debris pieces
	_spawn_debris(grid_divisions)

	# 4. Clean up the floor node after debris finishes falling
	get_tree().create_timer(3.0).timeout.connect(queue_free)


func _spawn_debris(divisions: int) -> void:
	var total_size_x: float = scale.x * 2.0
	var total_size_z: float = scale.z * 2.0
	var piece_w: float = total_size_x / float(divisions)
	var piece_d: float = total_size_z / float(divisions)

	# Read the current intact UV scale from the floor material
	var base_mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
	var base_uv_scale: Vector3 = base_mat.uv1_scale if base_mat else Vector3.ONE

	# Each piece gets 1/divisions share of the total UV span
	var chunk_uv_scale: Vector3 = Vector3(
		base_uv_scale.x / float(divisions),
		base_uv_scale.y / float(divisions),
		1.0
	)

	for x in range(divisions):
		for z in range(divisions):
			var rb: RigidBody3D = RigidBody3D.new()
			rb.collision_layer = 0
			rb.collision_mask = 0

			# Create an independent material for each shard so UVs align correctly
			var chunk_mat: StandardMaterial3D = StandardMaterial3D.new()
			chunk_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			chunk_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			chunk_mat.albedo_texture = floor_texture
			chunk_mat.uv1_scale = chunk_uv_scale
			# Offset the UV window so this chunk displays its exact slice of the floor
			chunk_mat.uv1_offset = Vector3(
				chunk_uv_scale.x * float(x),
				chunk_uv_scale.y * float(z),
				0.0
			)

			var mi: MeshInstance3D = MeshInstance3D.new()
			var box_mesh: BoxMesh = BoxMesh.new()
			box_mesh.size = Vector3(piece_w * 0.95, 0.15, piece_d * 0.95)
			mi.mesh = box_mesh
			mi.material_override = chunk_mat

			rb.add_child(mi)

			# Position chunk in the world
			var local_x: float = -total_size_x * 0.5 + piece_w * (x + 0.5)
			var local_z: float = -total_size_z * 0.5 + piece_d * (z + 0.5)
			rb.global_position = global_position + Vector3(local_x, -0.05, local_z)

			get_parent().add_child(rb)

			# Impulse outwards and downwards
			var push_dir: Vector3 = Vector3(local_x, randf_range(-1.5, -0.5), local_z).normalized()
			var impulse: Vector3 = push_dir * randf_range(3.0, 7.0)
			rb.apply_central_impulse(impulse)
			rb.apply_torque_impulse(Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5)))

			# Fade out and clean up
			var tween: Tween = create_tween()
			tween.tween_interval(1.8)
			tween.tween_property(mi, "scale", Vector3.ZERO, 0.5)
			tween.tween_callback(rb.queue_free)