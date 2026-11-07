@tool
extends StaticBody3D

@export var floor_texture: Texture2D:
	set(value):
		floor_texture = value
		_update_visuals()

## How many times the texture repeats per unit of scale (default: 1.0)
@export var texture_density: float = 1.0:
	set(value):
		texture_density = max(value, 0.01)
		_update_visuals()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _enter_tree() -> void:
	# Enable notifications whenever the node is transformed/scaled in the editor
	set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_visuals()

func _ready() -> void:
	_update_visuals()

func _update_visuals() -> void:
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		return

	var mat = mesh_instance.material_override as StandardMaterial3D
	if not mat:
		return

	# Ensure the material is unique to this instance so scaling one doesn't affect others
	if not mat.resource_local_to_scene:
		mat = mat.duplicate()
		mat.resource_local_to_scene = true
		mesh_instance.material_override = mat

	# Assign texture
	mat.albedo_texture = floor_texture

	# Scale UVs proportional to the root node's X and Z transform scale
	var sx: float = abs(scale.x) * texture_density
	var sz: float = abs(scale.z) * texture_density
	mat.uv1_scale = Vector3(sx, sz, 1.0)