extends Node3D

@export var speed: float = 20.0
@export var lifetime: float = 5.0  # How long before auto-despawn
@export var acceleration: float = 40.0  # How quickly speed increases
@export var max_speed: float = 60.0  # Maximum speed

var direction: Vector3 = Vector3.FORWARD
var lifetime_timer: float = 0.0
var current_speed: float = 5.0  # Start slow

func _ready():
	lifetime_timer = lifetime

func _process(delta):
	# Accelerate speed up to max
	current_speed = min(current_speed + acceleration * delta, max_speed)
	
	# Move in the direction with current speed
	global_position += direction * current_speed * delta
	
	# Count down lifetime
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		queue_free()

func set_direction(new_direction: Vector3):
	direction = new_direction.normalized()

