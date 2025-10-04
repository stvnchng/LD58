extends CharacterBody3D
class_name Enemy

@export var speed: float = 3.0
@export var acceleration: float = 10.0
@export var player: Player
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D


func _ready():
	call_deferred("actor_setup")

func actor_setup():
	await get_tree().physics_frame
	if player:
		set_movement_target(player.global_position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.target_position = movement_target

func _physics_process(delta):
	if not player:
		return

	set_movement_target(player.global_position)

	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	var direction = (next_path_position - current_agent_position).normalized()

	var target_velocity = direction * speed
	velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)
	velocity.y = 0

	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)

	move_and_slide()
