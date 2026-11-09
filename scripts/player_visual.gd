extends Node

const FRAME_DURATION := 0.12
const IDLE_FRAME: Texture2D = preload("res://textures/PNG/Player/Playerman_idle.png")
const WALK_FRAMES: Array[Texture2D] = [
	preload("res://textures/PNG/Player/Playerman_walk1.png"),
	preload("res://textures/PNG/Player/Playerman_walk2.png"),
	preload("res://textures/PNG/Player/Playerman_walk3.png"),
]

@onready var body: CharacterBody3D = get_parent() as CharacterBody3D
@onready var sprite: MeshInstance3D = body.get_node("Sprite")
@onready var shadow: MeshInstance3D = body.get_node("Shadow")

var elapsed := 0.0
var frame_index := 0
var material: StandardMaterial3D
var facing_right := true

func _ready() -> void:
	material = sprite.get_active_material(0) as StandardMaterial3D
	if not material:
		push_error("Player visual requires a StandardMaterial3D on the Sprite mesh.")
		set_process(false)
		return

	material = material.duplicate()
	material.resource_local_to_scene = true
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.material_override = material
	material.albedo_texture = IDLE_FRAME

func _process(delta: float) -> void:
	shadow.visible = body.is_on_floor()
	_update_facing()
	var is_moving := Vector2(body.velocity.x, body.velocity.z).length_squared() > 0.01
	if not is_moving:
		elapsed = 0.0
		frame_index = 0
		material.albedo_texture = IDLE_FRAME
		return

	elapsed += delta
	if elapsed < FRAME_DURATION:
		return

	elapsed = fmod(elapsed, FRAME_DURATION)
	frame_index = (frame_index + 1) % WALK_FRAMES.size()
	material.albedo_texture = WALK_FRAMES[frame_index]

func _update_facing() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return

	var horizontal_velocity := Vector3(body.velocity.x, 0.0, body.velocity.z)
	if horizontal_velocity.length_squared() <= 0.01:
		return

	facing_right = horizontal_velocity.dot(camera.global_basis.x) < 0.0
	if facing_right:
		material.uv1_scale.x = 1.0
		material.uv1_offset.x = 0.0
	else:
		material.uv1_scale.x = -1.0
		material.uv1_offset.x = 1.0
