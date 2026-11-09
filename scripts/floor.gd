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
const DEBRIS_PER_FRAME: int = 8
const BREAK_SPAWN_RATIO: float = 0.8
const GROUND_DESTROY_CHANCE: float = 0.75
signal debris_break_threshold_reached

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
func break_floor(grid_divisions: int = 14) -> void:
	if is_broken or Engine.is_editor_hint():
		return
	is_broken = true

	_spawn_debris(grid_divisions)
	await debris_break_threshold_reached

	# Disable the intact floor after most debris has been created.
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if mesh_instance:
		mesh_instance.visible = false

	# Clean up the floor node after debris finishes falling.
	get_tree().create_timer(3.0).timeout.connect(queue_free)


func _spawn_debris(divisions: int) -> void:
	var total_size_x: float = scale.x * 2.0
	var total_size_z: float = scale.z * 2.0
	var piece_w: float = total_size_x / float(divisions)
	var piece_d: float = total_size_z / float(divisions)

	var base_mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
	var base_uv_scale: Vector3 = base_mat.uv1_scale if base_mat else Vector3.ONE

	var chunk_uv_scale: Vector3 = Vector3(
		base_uv_scale.x / float(divisions),
		base_uv_scale.y / float(divisions),
		1.0
	)
	var spawned_this_frame := 0
	var total_pieces := divisions * divisions
	var break_threshold := ceili(float(total_pieces) * BREAK_SPAWN_RATIO)
	var spawned_pieces := 0
	var threshold_emitted := false
	for x in range(divisions):
		for z in range(divisions):
			var rb: RigidBody3D = RigidBody3D.new()
			var chunk_height: float = randf_range(0.10, 0.20)
			var corner_count: int = randi_range(3, 10)
			var size_multiplier: float = randf_range(1.35, 2.0) if randf() < 0.2 else randf_range(0.85, 1.1)
			var polygon_points := _create_debris_polygon(
				piece_w * 0.9 * size_multiplier,
				piece_d * 0.9 * size_multiplier,
				chunk_height,
				corner_count
			)

			# Physics setup:
			# Layer 8 (Debris = value 128)
			# Mask 1 (Only collide with Layer 1 'World' floors, ignore other debris and player)
			rb.collision_layer = 128
			rb.collision_mask = 1
			rb.contact_monitor = true
			rb.max_contacts_reported = 1

			# Give it bounciness and friction so it skids on lower floors
			var phys_mat: PhysicsMaterial = PhysicsMaterial.new()
			phys_mat.bounce = 0.35
			phys_mat.friction = 0.6
			rb.physics_material_override = phys_mat

			# Add CollisionShape3D
			var col: CollisionShape3D = CollisionShape3D.new()
			var chunk_shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
			chunk_shape.points = polygon_points
			col.shape = chunk_shape
			rb.add_child(col)

			# UV slice material
			var chunk_mat: StandardMaterial3D = StandardMaterial3D.new()
			chunk_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			chunk_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			chunk_mat.albedo_texture = floor_texture
			chunk_mat.uv1_scale = chunk_uv_scale
			chunk_mat.uv1_offset = Vector3(
				chunk_uv_scale.x * float(x),
				chunk_uv_scale.y * float(z),
				0.0
			)

			# Mesh setup
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = _create_debris_mesh(polygon_points)
			mi.material_override = chunk_mat
			rb.add_child(mi)

			# Position chunk in the world
			var local_x: float = -total_size_x * 0.5 + piece_w * (x + 0.5)
			var local_z: float = -total_size_z * 0.5 + piece_d * (z + 0.5)
			rb.global_position = global_position + Vector3(local_x, 0.0, local_z)

			get_parent().add_child(rb)
			var tower := get_parent().get_parent()
			rb.body_entered.connect(_on_debris_body_entered.bind(rb, tower))
			if tower.has_method("register_debris"):
				tower.register_debris(rb)

			# Apply initial explosion impulse
			var push_dir: Vector3 = Vector3(local_x, randf_range(1.0, 3.0), local_z).normalized()
			var impulse: Vector3 = push_dir * randf_range(2.0, 5.0)
			rb.apply_central_impulse(impulse)
			rb.apply_torque_impulse(Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)))

			# Let debris fall and settle on lower floors, then shrink and vanish
			var tween: Tween = create_tween()
			tween.tween_interval(3.0) # Time spent resting on lower floor before disappearing
			tween.tween_property(mi, "scale", Vector3.ZERO, 0.4)
			tween.tween_callback(func():
				if tower.has_method("schedule_debris_removal"):
					tower.schedule_debris_removal(rb)
				else:
					rb.queue_free()
			)

			spawned_this_frame += 1
			spawned_pieces += 1
			if not threshold_emitted and spawned_pieces >= break_threshold:
				threshold_emitted = true
				debris_break_threshold_reached.emit()
			if spawned_this_frame >= DEBRIS_PER_FRAME:
				spawned_this_frame = 0
				await get_tree().process_frame

func _on_debris_body_entered(body: Node3D, piece: RigidBody3D, tower: Node) -> void:
	if not is_instance_valid(piece) or piece.get_meta("ground_hit", false):
		return
	if (body.collision_layer & 1) == 0:
		return

	piece.set_meta("ground_hit", true)
	if randf() < GROUND_DESTROY_CHANCE and tower.has_method("schedule_debris_removal"):
		tower.schedule_debris_removal(piece)

func _create_debris_polygon(width: float, depth: float, height: float, corner_count: int) -> PackedVector3Array:
	var points_2d: Array[Vector2] = []
	for i in range(corner_count):
		var angle := TAU * float(i) / float(corner_count) + randf_range(-0.4, 0.4)
		var radius := randf_range(0.35, 1.15)
		points_2d.append(Vector2(cos(angle) * width * 0.5 * radius, sin(angle) * depth * 0.5 * radius))

	points_2d.sort_custom(func(a: Vector2, b: Vector2): return atan2(a.y, a.x) < atan2(b.y, b.x))

	var points := PackedVector3Array()
	for y in [-height * 0.5, height * 0.5]:
		for point in points_2d:
			points.append(Vector3(point.x, y, point.y))
	return points

func _create_debris_mesh(points: PackedVector3Array) -> ArrayMesh:
	var count: int = points.size() / 2
	var polygon := PackedVector2Array()
	for i in range(count):
		polygon.append(Vector2(points[i].x, points[i].z))
	var triangles := Geometry2D.triangulate_polygon(polygon)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for point in points:
		vertices.append(point)
		uvs.append(Vector2(point.x, point.z))

	for i in range(0, triangles.size(), 3):
		indices.append_array(PackedInt32Array([
			count + triangles[i],
			count + triangles[i + 1],
			count + triangles[i + 2]
		]))
		indices.append_array(PackedInt32Array([
			triangles[i + 2],
			triangles[i + 1],
			triangles[i]
		]))

	for i in range(count):
		var next := (i + 1) % count
		var base := vertices.size()
		vertices.append(points[i])
		vertices.append(points[next])
		vertices.append(points[count + next])
		vertices.append(points[count + i])
		uvs.append_array(PackedVector2Array([
			Vector2(points[i].x, points[i].z),
			Vector2(points[next].x, points[next].z),
			Vector2(points[next].x, points[next].z),
			Vector2(points[i].x, points[i].z)
		]))
		indices.append_array(PackedInt32Array([
			base, base + 1, base + 2,
			base, base + 2, base + 3
		]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh