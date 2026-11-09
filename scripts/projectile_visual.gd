extends Node
class_name ProjectileVisual

const SMACK_DURATION := 0.1
const FRAMES: Array[Texture2D] = [
	preload("res://textures/PNG/Fly Swatter/Fly swatter1.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter2.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter3.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter4.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter5.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter6.png"),
]

signal smack_finished

@onready var mesh_instance: MeshInstance3D = $"../MeshInstance3D"

func _ready() -> void:
	mesh_instance.scale = Vector3(2.0, 2.0, 2.0)
	var source_material := mesh_instance.get_active_material(0) as StandardMaterial3D
	if not source_material:
		push_error("Projectile visual requires a StandardMaterial3D on its mesh.")
		set_process(false)
		return

	var material := source_material.duplicate()
	material.resource_local_to_scene = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.render_priority = 10
	material.no_depth_test = true
	mesh_instance.material_override = material
	material.albedo_texture = FRAMES[3]

func _process(_delta: float) -> void:
	var projectile := get_parent() as StraightProjectileComponent
	var camera := get_viewport().get_camera_3d()
	var material := mesh_instance.material_override as StandardMaterial3D
	if not projectile or not camera or not material:
		return

	var horizontal_direction := Vector3(projectile.direction.x, 0.0, projectile.direction.z)
	if horizontal_direction.length_squared() <= 0.01:
		return

	var moving_right := horizontal_direction.dot(camera.global_basis.x) < 0.0
	if moving_right:
		material.uv1_scale.x = 1.0
		material.uv1_offset.x = 0.0
	else:
		material.uv1_scale.x = -1.0
		material.uv1_offset.x = 1.0

func play_smack() -> void:
	var material := mesh_instance.material_override as StandardMaterial3D
	material.albedo_texture = FRAMES[4]
	await get_tree().create_timer(SMACK_DURATION).timeout
	smack_finished.emit()
