extends CharacterBody3D

@export var speed: float = 5.0
@export var rotation_speed: float = 10.0

@onready var camera_rig = $CameraRig


func _physics_process(delta):
	var input = Vector3.ZERO

	if Input.is_action_pressed("ui_up"):
		input.z -= 1
	if Input.is_action_pressed("ui_down"):
		input.z += 1
	if Input.is_action_pressed("ui_left"):
		input.x -= 1
	if Input.is_action_pressed("ui_right"):
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

	if input.length() > 0:
		var target_rotation = atan2(input.x, input.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
		
		if camera_rig:
			camera_rig.global_rotation.y = 0

	move_and_slide()
