extends CharacterBody3D
class_name Player

@export var speed: float = 5.0
@export var rotation_speed: float = 10.0

@export var dash_speed: float = 20.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

@onready var camera_rig = $CameraRig
@onready var camera = $CameraRig/Camera3D
@onready var health: HealthComponent = $HealthComponent
@onready var shooting : ShootingComponent = $ShootingComponent
@onready var dash_trail: Trail3D = $Trail3D

var last_mouse_direction: Vector3

func _ready():
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

func _physics_process(delta):
	if dash_timer > 0.0:
		dash_timer -= delta
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

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
		input.x * cos(angle) - input.z * sin(angle), 0, input.x * sin(angle) + input.z * cos(angle)
	)
	input = rotated_input
	
	if Input.is_action_just_pressed("dash") and dash_timer <= 0.0 and dash_cooldown_timer <= 0.0:
		start_dash(input)

	dash_trail.enabled = (dash_timer > 0.0)
	if dash_timer > 0.0:
		velocity = dash_direction * dash_speed
	else:
		velocity.x = input.x * speed
		velocity.z = input.z * speed
		velocity.y = 0

	# Raycast from mouse to ground plane to get target position
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var plane = Plane(Vector3.UP, global_position.y)
	var intersection = plane.intersects_ray(from, to - from)

	if intersection:
		var direction = intersection - global_position
		direction.y = 0  # Keep rotation on horizontal plane

		if direction.length() > 0.1:  # Add deadzone to prevent jittering
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
			last_mouse_direction = direction.normalized()
			shooting.shoot_direction = last_mouse_direction

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shooting.try_shoot()

	if camera_rig:
		camera_rig.global_rotation.y = 0

	move_and_slide()


func start_dash(input: Vector3):
	if input.length() > 0.1:
		dash_direction = input.normalized()
	else:
		dash_direction = last_mouse_direction.normalized()

	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

func is_invincible() -> bool:
	return dash_timer > 0.0

func _on_died():
	print('u died bro')
	queue_free()

func _on_health_changed(new_health: int, max_health: int):
	pass
