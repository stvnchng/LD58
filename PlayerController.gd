extends CharacterBody3D

@export var speed: float = 5.0


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
	velocity.x = input.x * speed
	velocity.z = input.z * speed
	velocity.y = 0  # keep on the ground

	move_and_slide()
