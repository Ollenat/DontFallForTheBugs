extends CharacterBody3D

@export var move_speed: float = 7.0
@export var acceleration: float = 14.0
@export var friction: float = 10.0

@export var camera: Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	# 1. Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Get directional input vector (-1 to 1 on X and Y)
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# 3. Extract the camera's basis vectors and flatten them to the XZ plane
	var cam_forward: Vector3 = -camera.global_transform.basis.z
	var cam_right: Vector3 = camera.global_transform.basis.x

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
	var current_velocity_xz: Vector3 = Vector3(velocity.x, 0.0, velocity.z)

	var rate: float = acceleration if target_direction.length_squared() > 0.0 else friction
	var blend: Vector3 = current_velocity_xz.move_toward(target_velocity_xz, rate * delta)

	velocity.x = blend.x
	velocity.z = blend.z

	# 6. Execute motion and collisions
	move_and_slide()
