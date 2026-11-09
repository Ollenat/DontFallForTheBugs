extends Node3D

const FRAME_DURATION := 0.08
const FRAMES: Array[Texture2D] = [
	preload("res://textures/PNG/Fly Swatter/Fly swatter1.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter2.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter3.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter4.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter5.png"),
	preload("res://textures/PNG/Fly Swatter/Fly swatter6.png"),
]

@onready var mesh_instance: MeshInstance3D = $DamageAreaComponent/CollisionShape3D/MeshInstance3D

var elapsed := 0.0
var frame_index := 0

func _ready() -> void:
	mesh_instance.scale = Vector3(2.0, 2.0, 2.0)
	var source_material := mesh_instance.get_active_material(0) as StandardMaterial3D
	if not source_material:
		push_error("Sawblade visual requires a StandardMaterial3D on its mesh.")
		set_process(false)
		return

	var material := source_material.duplicate()
	material.resource_local_to_scene = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mesh_instance.material_override = material
	material.albedo_texture = FRAMES[0]

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < FRAME_DURATION:
		return

	elapsed = fmod(elapsed, FRAME_DURATION)
	frame_index = (frame_index + 1) % FRAMES.size()
	(mesh_instance.material_override as StandardMaterial3D).albedo_texture = FRAMES[frame_index]
