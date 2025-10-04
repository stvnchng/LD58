extends CharacterBody3D
class_name EnemyFloater

@export var speed: float = 4.0
@export var min_distance: float = 8.0  # Minimum distance from player
@export var max_distance: float = 12.0  # Maximum distance from player
@export var preferred_distance: float = 4.5  # Sweet spot distance
@export var orbit_speed: float = 3.0  # How fast to circle around player
@export var rotation_speed: float = 8.0  # How fast to rotate to face player

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var player: Player = null
var orbit_angle: float = 0.0  # Current angle around the player
var orbit_direction: float = 1.0  # 1 for clockwise, -1 for counter-clockwise
var oscillation_time: float = 0.0  # Timer for distance oscillation
var oscillation_speed: float = 3.0  # How fast to oscillate in/out
var oscillation_amplitude: float = 2.0  # How much to oscillate (distance variance)

func _ready():
	player = get_tree().get_first_node_in_group("player")
	call_deferred("actor_setup")
	# Randomize initial orbit direction
	orbit_direction = 1.0 if randf() > 0.5 else -1.0

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
	
	# Update oscillation timer
	oscillation_time += delta * oscillation_speed
	
	# Determine behavior based on distance
	if distance_to_player > max_distance:
		# Too far - move toward player using navigation
		approach_player(delta)
	elif distance_to_player < min_distance:
		# Too close - back away from player
		retreat_from_player(delta)
	else:
		# In range - orbit around player with oscillation
		orbit_player(delta, distance_to_player)
	
	# Always rotate to face the player
	var direction_to_player = (player.global_position - global_position)
	direction_to_player.y = 0
	if direction_to_player.length() > 0.1:
		var target_rotation = atan2(direction_to_player.x, direction_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	velocity.y = 0
	move_and_slide()

func approach_player(delta):
	set_movement_target(player.global_position)
	
	if navigation_agent.is_navigation_finished():
		return
	
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	var direction = (next_path_position - current_agent_position).normalized()
	
	# Fluctuating speed - oscillates between 0.4 and 1.0 (never backwards)
	var speed_multiplier = 0.7 + sin(oscillation_time * 1.2) * 0.3
	var current_speed = speed * speed_multiplier
	
	# Add side-to-side swaying motion
	var sway_direction = Vector3(-direction.z, 0, direction.x)  # Perpendicular to movement
	var sway_amount = sin(oscillation_time * 2.0) * 1.5  # Sway side to side
	
	var target_velocity = direction * current_speed + sway_direction * sway_amount
	
	velocity.x = lerp(velocity.x, target_velocity.x, 8.0 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 8.0 * delta)

func retreat_from_player(delta):
	# Move directly away from player
	var direction_away = (global_position - player.global_position).normalized()
	direction_away.y = 0
	
	velocity.x = lerp(velocity.x, direction_away.x * speed, 8.0 * delta)
	velocity.z = lerp(velocity.z, direction_away.z * speed, 8.0 * delta)

func orbit_player(delta, distance_to_player):
	# Calculate tangent direction for orbiting
	var to_player = player.global_position - global_position
	to_player.y = 0
	to_player = to_player.normalized()
	
	# Perpendicular vector for orbiting (tangent)
	var tangent = Vector3(-to_player.z, 0, to_player.x) * orbit_direction
	
	# Natural oscillating radial velocity (in/out breathing motion)
	var oscillation_velocity = cos(oscillation_time) * oscillation_amplitude * oscillation_speed
	var radial_velocity = -to_player * oscillation_velocity
	
	# Only correct if getting too close or too far
	var correction = Vector3.ZERO
	if distance_to_player < min_distance + 0.5:
		# Too close, gently push away
		var push_strength = (min_distance + 0.5 - distance_to_player) * 0.3
		correction = -to_player * push_strength
	elif distance_to_player > max_distance - 0.5:
		# Too far, gently pull in
		var pull_strength = (distance_to_player - (max_distance - 0.5)) * 0.3
		correction = to_player * pull_strength
	
	# Combine tangent (orbit) with natural oscillation and optional correction
	var desired_direction = (tangent * orbit_speed + radial_velocity + correction).normalized()
	
	velocity.x = lerp(velocity.x, desired_direction.x * speed, 2.0 * delta)
	velocity.z = lerp(velocity.z, desired_direction.z * speed, 2.0 * delta)
	
	# Update orbit angle for visual/gameplay variety
	orbit_angle += orbit_speed * orbit_direction * delta
	
	# Occasionally switch orbit direction for unpredictability
	if randf() < 0.3 * delta:  # Small chance each frame
		orbit_direction *= -1.0

