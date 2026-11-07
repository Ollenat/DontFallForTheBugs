class_name SmoothFollowComponent
extends Node3D
## Följer efter ett Node3D med mjuk rörelse.
## Offseten tas från hur noden är placerad i editorn.

## Noden som ska följas. Lämnas tom används förälder-noden.
@export var target: Node3D
## Tid i sekunder för att komma ikapp. 0 = följer direkt, högre = mjukare/långsammare.
@export_range(0.0, 2.0, 0.01, "or_greater") var smoothness := 0.15
## Om true roterar offseten med målet. Annars hålls den fast i världen.
@export var offset_follows_rotation := false

var _world_offset: Vector3
var _local_offset: Vector3

func _ready() -> void:
	if target == null:
		target = get_parent() as Node3D
	if target == null:
		push_warning("SmoothFollowComponent: inget target hittades.")
		set_process(false)
		return

	# top_level gör att noden inte ärver förälderns transform,
	# så den kan ligga som barn till spelaren och ändå röra sig fritt.
	var start_transform := global_transform
	top_level = true
	global_transform = start_transform

	# Spara offseten som den ser ut i editorn
	_world_offset = start_transform.origin - target.global_position
	_local_offset = target.global_basis.orthonormalized().inverse() * _world_offset

func _physics_process(delta: float) -> void:
	var offset := _world_offset
	if offset_follows_rotation:
		offset = target.global_basis.orthonormalized() * _local_offset

	var desired := target.global_position + offset

	if smoothness <= 0.0:
		global_position = desired
	else:
		# Frame-rate oberoende smoothing
		global_position = global_position.lerp(desired, 1.0 - exp(-delta / smoothness))