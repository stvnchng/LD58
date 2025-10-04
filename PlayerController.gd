extends CharacterBody3D

@export var speed: float = 5.0
@export var rotation_speed: float = 10.0

@onready var camera_rig = $CameraRig
@onready var camera = $CameraRig/Camera3D


func _physics_process(delta):
	var input = Vector3.ZERO

	if Input.is_action_pressed("move_up"):
		input.z -= 1
	if Input.is_action_pressed("move_down"):
		input.z += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1

	input = input.normalized()
	
	var angle = deg_to_rad(45)
	var rotated_input = Vector3(
		input.x * cos(angle) - input.z * sin(angle),
		0,
		input.x * sin(angle) + input.z * cos(angle)
	)
	input = rotated_input
	velocity.x = input.x * speed
	velocity.z = input.z * speed
	velocity.y = 0

	# Raycast from mouse to ground plane to get target position
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	# Create a plane at the player's Y position
	var plane = Plane(Vector3.UP, global_position.y)
	var intersection = plane.intersects_ray(from, to - from)
	
	if intersection:
		# Calculate direction to mouse position
		var direction = intersection - global_position
		direction.y = 0  # Keep rotation on horizontal plane
		
		if direction.length() > 0.1:  # Add deadzone to prevent jittering
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	# Keep camera rig at zero rotation
	if camera_rig:
		camera_rig.global_rotation.y = 0

	move_and_slide()
