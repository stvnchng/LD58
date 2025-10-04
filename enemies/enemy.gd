extends CharacterBody3D
class_name Enemy

@export var speed: float = 3.0
@export var acceleration: float = 10.0
@export var ideal_radius: float = 8.0  # Distance at which to stop chasing
@export var max_radius: float = 12.0  # Maximum distance before returning to chase
@export var wander_speed: float = 0.75  # Speed when wandering

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var player: Player = null
var is_chasing: bool = true
var wander_target: Vector3 = Vector3.ZERO
var wander_radius: float = 0.0  # Calculated from max_radius - ideal_radius

func _ready():
	player = get_tree().get_first_node_in_group("player")
	wander_radius = max_radius - ideal_radius
	call_deferred("actor_setup")

func actor_setup():
	await get_tree().physics_frame
	if player:
		print(player.global_position)
		set_movement_target(player.global_position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.target_position = movement_target

func _physics_process(delta):
	if not player:
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Always face the player
	var direction_to_player = (player.global_position - global_position)
	direction_to_player.y = 0
	if direction_to_player.length() > 0.1:
		var target_rotation = atan2(direction_to_player.x, direction_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
	
	# Check if we need to return to chase state
	if distance_to_player > max_radius:
		is_chasing = true
	
	if is_chasing:
		# Chase state - move toward player
		if distance_to_player <= ideal_radius:
			# Reached ideal radius - switch to wander
			is_chasing = false
			pick_new_wander_target()
		else:
			# Continue chasing
			set_movement_target(player.global_position)
			
			if not navigation_agent.is_navigation_finished():
				var current_agent_position: Vector3 = global_position
				var next_path_position: Vector3 = navigation_agent.get_next_path_position()
				var direction = (next_path_position - current_agent_position).normalized()
				
				var target_velocity = direction * speed
				velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
				velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)
	else:
		# Wander state - move to wander target
		var distance_to_target = global_position.distance_to(wander_target)
		
		if distance_to_target < 0.5:
			# Reached wander target - pick new one
			pick_new_wander_target()
		else:
			# Move toward wander target
			var direction_to_target = (wander_target - global_position).normalized()
			direction_to_target.y = 0
			
			velocity.x = lerp(velocity.x, direction_to_target.x * wander_speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction_to_target.z * wander_speed, acceleration * delta)
	
	velocity.y = 0
	move_and_slide()

func pick_new_wander_target():
	# Pick a random point within wander_radius from current position
	var random_angle = randf() * TAU
	var random_distance = randf() * wander_radius
	
	var offset = Vector3(cos(random_angle) * random_distance, 0, sin(random_angle) * random_distance)
	wander_target = global_position + offset
	wander_target.y = global_position.y  # Keep on same Y level
