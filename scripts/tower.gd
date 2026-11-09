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
@export var pick_three_scene: PackedScene = preload("res://scenes/pick_three.tscn")
const MAIN_MENU_THEME: Theme = preload("res://themes/Text_theme.tres")

@onready var top_floor_pos: Node3D = $TopFloorPos
@onready var floors_container: Node3D = $Floors

var active_floors: Array[TowerFloor] = []
var debris: Array[RigidBody3D] = []
var next_floor_y: float = 0.0
var wall_height: float = 300.0
var upgrade_levels: Dictionary = {}
var _pick_shown_for_floor := false
var _progress_bar: ProgressBar
var _progress_label: Label
var _upgrade_transition := ""
var _upgrade_transition_started_msec := 0
const UPGRADE_SLOW_TIME_SCALE := 0.08
const UPGRADE_TRANSITION_SECONDS := 0.45
const CHEAT_SEQUENCE: Array[Key] = [KEY_X, KEY_Y, KEY_Z, KEY_4, KEY_5, KEY_6]
var _cheat_sequence_index: int = 0
var _upgrade_cheat_unlocked: bool = false

func _ready() -> void:
	if player == null:
		player = get_parent().get_node_or_null("Player") as CharacterBody3D
	if not floors_container:
		floors_container = Node3D.new()
		floors_container.name = "Floors"
		add_child(floors_container)

	_sync_walls_geometry()

	if Engine.is_editor_hint():
		_spawn_editor_preview_floors()
	else:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_create_progress_display()
		add_to_group("tower")
		next_floor_y = 0.0
		for i in range(floors_buffer):
			_spawn_next_floor()
		_update_facade()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _upgrade_transition != "":
		_update_upgrade_transition()
		if _upgrade_transition != "":
			return

	if player and (player.global_position.y - next_floor_y < floors_buffer * floor_spacing * 0.75):
		_spawn_next_floor()

	var top_floor := _highest_unbroken_floor()
	if top_floor and top_floor.progress >= 1.0:
		break_highest_floor()
	_update_progress_display()

func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if not key_event or not key_event.pressed or key_event.echo:
		return
	if _upgrade_cheat_unlocked and key_event.keycode == KEY_M:
		if not _pick_shown_for_floor and _upgrade_transition == "":
			_show_pick_three()
		return
	if key_event.keycode == CHEAT_SEQUENCE[_cheat_sequence_index]:
		_cheat_sequence_index += 1
		if _cheat_sequence_index == CHEAT_SEQUENCE.size():
			_cheat_sequence_index = 0
			_upgrade_cheat_unlocked = true
			if not _pick_shown_for_floor and _upgrade_transition == "":
				_show_pick_three()
	else:
		_cheat_sequence_index = 1 if key_event.keycode == CHEAT_SEQUENCE[0] else 0

func register_enemy_kill() -> void:
	var floor_node := _highest_unbroken_floor()
	if not floor_node:
		return
	floor_node.points += 1
	floor_node.progress = minf(
		1.0,
		float(floor_node.points) / float(floor_node.points_required)
	)

func register_special_kill() -> void:
	if _pick_shown_for_floor:
		return
	_pick_shown_for_floor = true
	_show_pick_three()

func break_highest_floor() -> void:
	var unbroken = active_floors.filter(func(f): return is_instance_valid(f) and not f.is_broken)
	if unbroken.is_empty():
		return

	unbroken.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)
	var floor_to_break: TowerFloor = unbroken[0]
	var reached_floor: int = roundi(-floor_to_break.global_position.y / floor_spacing) + 1
	floor_to_break.break_floor()
	_pick_shown_for_floor = false
	_wake_debris()
	if reached_floor % 10 == 0:
		var music_player: Node = get_parent().get_node_or_null("MusicPlayer")
		if music_player and music_player.has_method("play_milestone_sound"):
			music_player.play_milestone_sound()
	# Keep the tower extending downward whenever a floor is consumed.
	_spawn_next_floor()
	_update_facade()

func _highest_unbroken_floor() -> TowerFloor:
	var unbroken = active_floors.filter(func(f): return is_instance_valid(f) and not f.is_broken)
	if unbroken.is_empty():
		return null
	unbroken.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)
	return unbroken[0]

func get_score_floor_number() -> int:
	var floor_node := _highest_unbroken_floor()
	if not floor_node:
		return 1
	return maxi(1, roundi(-floor_node.global_position.y / floor_spacing) + 1)

func _create_progress_display() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "FloorProgress"
	add_child(canvas)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	center.position = Vector2(-220.0, 24.0)
	center.size = Vector2(440.0, 70.0)
	canvas.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440.0, 70.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#321d18")
	panel_style.border_color = Color("#8b542f")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.theme = MAIN_MENU_THEME
	center.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 3)
	panel.add_child(contents)
	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_color_override("font_color", Color("#ffe28a"))
	contents.add_child(_progress_label)
	_progress_bar = ProgressBar.new()
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(400.0, 24.0)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#4b2d21")
	background.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#f4c542")
	fill.set_corner_radius_all(5)
	_progress_bar.add_theme_stylebox_override("background", background)
	_progress_bar.add_theme_stylebox_override("fill", fill)
	contents.add_child(_progress_bar)

func _update_progress_display() -> void:
	if not _progress_bar or not _progress_label:
		return
	var floor_node := _highest_unbroken_floor()
	if not floor_node:
		_progress_bar.visible = false
		_progress_label.visible = false
		return
	_progress_bar.visible = true
	_progress_label.visible = true
	_progress_bar.value = floor_node.progress
	_progress_label.text = "FLOOR %d  •  %d / %d BUGS" % [
		roundi(-floor_node.global_position.y / floor_spacing) + 1,
		floor_node.points,
		floor_node.points_required,
	]

func _show_pick_three() -> void:
	if not pick_three_scene:
		push_error("Tower has no pick-three scene assigned.")
		_pick_shown_for_floor = false
		get_tree().paused = false
		return
	var picker := pick_three_scene.instantiate()
	picker.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(picker)
	var choices: Array[Dictionary] = UpgradeCatalog.choose(upgrade_levels)
	var cards := picker.get_node("Center/Banner/CardArea/Cards").get_children()
	for i in mini(cards.size(), choices.size()):
		var card: PickCard = cards[i]
		card.card_title = choices[i].title
		card.card_description = choices[i].description
		card.set_meta("upgrade", choices[i])
	picker.connect("card_picked", _on_upgrade_picked.bind(picker, choices))
	_start_upgrade_slowdown()

func _on_upgrade_picked(index: int, picker: Control, choices: Array[Dictionary]) -> void:
	if index < 0 or index >= choices.size():
		push_error("Pick-three returned an invalid card index.")
		_pick_shown_for_floor = false
		get_tree().paused = false
		picker.queue_free()
		return
	var upgrade: Dictionary = choices[index]
	upgrade_levels[upgrade.id] = int(upgrade_levels.get(upgrade.id, 0)) + 1
	if player and player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade)
	picker.queue_free()
	_pick_shown_for_floor = false
	_start_upgrade_resume()

func _start_upgrade_slowdown() -> void:
	_upgrade_transition = "slowing"
	_upgrade_transition_started_msec = Time.get_ticks_msec()
	get_tree().paused = false

func _start_upgrade_resume() -> void:
	Engine.time_scale = UPGRADE_SLOW_TIME_SCALE
	get_tree().paused = false
	_upgrade_transition = "resuming"
	_upgrade_transition_started_msec = Time.get_ticks_msec()

func _update_upgrade_transition() -> void:
	var elapsed := float(Time.get_ticks_msec() - _upgrade_transition_started_msec) / 1000.0
	var weight := clampf(elapsed / UPGRADE_TRANSITION_SECONDS, 0.0, 1.0)
	if _upgrade_transition == "slowing":
		Engine.time_scale = lerpf(1.0, UPGRADE_SLOW_TIME_SCALE, weight)
		if weight >= 1.0:
			Engine.time_scale = UPGRADE_SLOW_TIME_SCALE
			get_tree().paused = true
			_upgrade_transition = ""
	elif _upgrade_transition == "resuming":
		Engine.time_scale = lerpf(UPGRADE_SLOW_TIME_SCALE, 1.0, weight)
		if weight >= 1.0:
			Engine.time_scale = 1.0
			_upgrade_transition = ""

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
	var new_floor := floor_scene.instantiate() as TowerFloor
	floors_container.add_child(new_floor)

	new_floor.scale = Vector3(tower_size * 0.5, 1.0, tower_size * 0.5)
	new_floor.global_position = Vector3(0.0, next_floor_y, 0.0)

	if "texture_density" in new_floor:
		new_floor.texture_density = texture_density

	if not floor_texture_pool.is_empty():
		new_floor.floor_texture = floor_texture_pool.pick_random()

	active_floors.append(new_floor)
	var floor_number := roundi(-new_floor.global_position.y / floor_spacing) + 1
	new_floor.points_required = ceili(20.0 * pow(1.1, floor_number - 1))
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
