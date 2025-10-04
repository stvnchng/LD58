extends CharacterBody3D
class_name EnemyLurcher

@export var lurch_speed: float = 6.0  # Speed during lurch movement
@export var lurch_duration: float = 0.3  # How long each lurch lasts
@export var lurch_pause: float = 0.8  # Pause between lurches
@export var lurch_distance: float = 1.5  # Distance covered per lurch
@export var circle_radius: float = 1.75  # Distance at which to start circling
@export var circle_speed: float = 0.3  # Speed when circling player

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var player: Player = null
var is_lurching: bool = false
var is_circling: bool = false
var lurch_timer: float = 0.0
var pause_timer: float = 0.0
var lurch_direction: Vector3 = Vector3.ZERO
var circle_direction: float = 1.0  # 1 for clockwise, -1 for counter-clockwise

func _ready():
	player = get_tree().get_first_node_in_group("player")
	call_deferred("actor_setup")
	pause_timer = lurch_pause  # Start with a pause
	circle_direction = 1.0 if randf() > 0.5 else -1.0  # Random initial circle direction

func actor_setup():
	await get_tree().physics_frame
	if player:
		set_movement_target(player.global_position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.target_position = movement_target

func _physics_process(delta):
	if not player:
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if we should be circling
	if distance_to_player <= circle_radius:
		is_circling = true
	elif distance_to_player > circle_radius + 0.5:  # Add hysteresis
		is_circling = false
	
	if is_circling:
		# Circle around the player
		var to_player = player.global_position - global_position
		to_player.y = 0
		to_player = to_player.normalized()
		
		# Get tangent direction for circling
		var tangent = Vector3(-to_player.z, 0, to_player.x) * circle_direction
		
		# Move in circle
		velocity.x = lerp(velocity.x, tangent.x * circle_speed, 5.0 * delta)
		velocity.z = lerp(velocity.z, tangent.z * circle_speed, 5.0 * delta)
		
		# Face the player while circling
		if to_player.length() > 0.1:
			var target_rotation = atan2(to_player.x, to_player.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, 8.0 * delta)
	else:
		# Normal lurching behavior
		set_movement_target(player.global_position)

		if navigation_agent.is_navigation_finished():
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 8.0 * delta)
		else:
			# Handle pause between lurches
			if not is_lurching:
				pause_timer -= delta
				if pause_timer <= 0.0:
					# Start a new lurch
					start_lurch()
				else:
					# During pause, gradually slow down
					velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
					velocity.z = lerp(velocity.z, 0.0, 8.0 * delta)
			else:
				# Actively lurching
				lurch_timer -= delta
				
				# Move in the lurch direction
				velocity.x = lurch_direction.x * lurch_speed
				velocity.z = lurch_direction.z * lurch_speed
				
				# Rotate toward the player during the lurch
				if lurch_direction.length() > 0.1:
					var target_rotation = atan2(lurch_direction.x, lurch_direction.z)
					rotation.y = lerp_angle(rotation.y, target_rotation, 8.0 * delta)
				
				if lurch_timer <= 0.0:
					# End lurch, start pause
					end_lurch()
	
	velocity.y = 0
	move_and_slide()

func start_lurch():
	is_lurching = true
	lurch_timer = lurch_duration
	
	# Get direction from navigation
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	lurch_direction = (next_path_position - current_agent_position).normalized()

func end_lurch():
	is_lurching = false
	pause_timer = lurch_pause
