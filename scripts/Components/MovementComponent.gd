extends Node
class_name MovementComponent

@export var body: CharacterBody3D
@export var health: HealthComponent

@export var move_speed: float = 5.5
@export var acceleration: float = 18.0
@export var friction: float = 24.0
@export var dash_speed: float = 10.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.7

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _dash_time_remaining: float = 0.0
var _dash_available_at_msec: int = 0
var _dash_direction: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if _dash_time_remaining > 0.0:
		_dash_time_remaining -= delta
		body.velocity.x = _dash_direction.x * dash_speed
		body.velocity.z = _dash_direction.z * dash_speed
		body.move_and_slide()
		return

	if Input.is_action_just_pressed("dash") and Time.get_ticks_msec() >= _dash_available_at_msec:
		_start_dash()
		body.velocity.x = _dash_direction.x * dash_speed
		body.velocity.z = _dash_direction.z * dash_speed
		body.move_and_slide()
		return

	# 1. Apply gravity
	if not body.is_on_floor():
		body.velocity.y -= gravity * delta

	# 2. Get directional input vector (-1 to 1 on X and Y)
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# 3. Extract the camera's basis vectors and flatten them to the XZ plane
	var camera := get_viewport().get_camera_3d()
	var basis := camera.global_basis if camera else body.global_basis
	var cam_forward: Vector3 = - basis.z
	var cam_right: Vector3 = basis.x

	# Zero out pitch/vertical tilt
	cam_forward.y = 0.0
	cam_right.y = 0.0

	# Re-normalize to prevent slow movement when looking steep up or down
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	# 4. Compute target ground direction
	var target_direction: Vector3 = (cam_right * input_dir.x + cam_forward * -input_dir.y).normalized()

	# 5. Smoothly apply horizontal acceleration/friction
	var target_velocity_xz: Vector3 = target_direction * move_speed
	var current_velocity_xz: Vector3 = Vector3(body.velocity.x, 0.0, body.velocity.z)

	var rate: float = acceleration if target_direction.length_squared() > 0.0 else friction
	var blend: Vector3 = current_velocity_xz.move_toward(target_velocity_xz, rate * delta)

	body.velocity.x = blend.x
	body.velocity.z = blend.z

	# 6. Execute motion and collisions
	body.move_and_slide()

func _start_dash() -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var camera := get_viewport().get_camera_3d()
	var basis: Basis = camera.global_basis if camera else body.global_basis
	var forward: Vector3 = -basis.z
	var right: Vector3 = basis.x
	forward.y = 0.0
	right.y = 0.0
	var direction: Vector3 = right.normalized() * input_dir.x + forward.normalized() * -input_dir.y
	if direction.length_squared() <= 0.0:
		direction = -body.global_basis.z
		direction.y = 0.0
	_dash_direction = direction.normalized()
	_dash_time_remaining = dash_duration
	_dash_available_at_msec = Time.get_ticks_msec() + roundi(dash_cooldown * 1000.0)
	if health:
		health.grant_invincibility(dash_duration + 0.05)
