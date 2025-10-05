extends CharacterBody3D
class_name EnemyFloater

@export var speed: float = 4.0
@export var min_distance: float = 8.0  # Minimum distance from player
@export var max_distance: float = 12.0  # Maximum distance from player
@export var preferred_distance: float = 4.5  # Sweet spot distance
@export var orbit_speed: float = 5.0  # How fast to circle around player
@export var rotation_speed: float = 8.0  # How fast to rotate to face player

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: HealthComponent = $HealthComponent
@onready var shooting: ShootingComponent = $ShootingComponent

var player: Player = null
var orbit_angle: float = 0.0  # Current angle around the player
var orbit_direction: float = 1.0  # 1 for clockwise, -1 for counter-clockwise
var oscillation_time: float = 0.0  # Timer for distance oscillation
var oscillation_speed: float = 3.0  # How fast to oscillate in/out
var oscillation_amplitude: float = 2.0  # How much to oscillate (distance variance)

enum TargetMode { PREDICT, CURRENT, PAST }
var target_mode: TargetMode = TargetMode.CURRENT
var mode_switch_timer: float = 0.0
var next_mode_switch_time: float = 0.0

var history_size: int = 60
var player_history: Array = []
var history_index: int = 0

var nav_update_timer: float = 0.0
var nav_update_interval: float = 0.1


func _ready():
	player = get_tree().get_first_node_in_group("player")
	call_deferred("actor_setup")
	# Randomize initial orbit direction
	orbit_direction = 1.0 if randf() > 0.5 else -1.0
	# Initialize targeting mode
	pick_random_target_mode()
	next_mode_switch_time = randf_range(5.0, 10.0)
	
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	
	player_history.resize(history_size)
	for i in range(history_size):
		player_history[i] = Vector3.ZERO

func actor_setup():
	await get_tree().physics_frame
	if player:
		set_movement_target(player.global_position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.target_position = movement_target

func _physics_process(delta):
	if not player:
		return
	
	history_index = (history_index + 1) % history_size
	player_history[history_index] = player.global_position
	
	mode_switch_timer += delta
	if mode_switch_timer >= next_mode_switch_time:
		pick_random_target_mode()
		mode_switch_timer = 0.0
		next_mode_switch_time = randf_range(5.0, 10.0)

	var target_position = get_target_position()

	var distance_to_player = global_position.distance_to(target_position)
	
	oscillation_time += delta * oscillation_speed
	if distance_to_player > max_distance:
		approach_player(delta, target_position)
	elif distance_to_player < min_distance:
		retreat_from_player(delta)
	else:
		orbit_player(delta, distance_to_player)
	
	# Always rotate to face the player
	var direction_to_player = (player.global_position - global_position)
	direction_to_player.y = 0
	if direction_to_player.length() > 0.1:
		var target_rotation = atan2(direction_to_player.x, direction_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
	
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d() if viewport else null
	var on_screen = false
	
	if camera:
		var screen_pos = camera.unproject_position(global_position)
		on_screen = screen_pos.x >= 0 and screen_pos.x <= viewport.size.x \
			and screen_pos.y >= 0 and screen_pos.y <= viewport.size.y

	var fire_chance = 0.5
	if on_screen and distance_to_player >= min_distance and distance_to_player <= max_distance:
			if randf() < fire_chance:
				shooting.shoot_direction = direction_to_player.normalized()
				shooting.try_shoot()
	
	velocity.y = 0
	move_and_slide()

func approach_player(delta, target_pos: Vector3):
	nav_update_timer += delta
	if nav_update_timer >= nav_update_interval:
		set_movement_target(target_pos)
		nav_update_timer = 0.0
	
	if navigation_agent.is_navigation_finished():
		return
	
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	var direction = (next_path_position - current_agent_position).normalized()
	
	# Fluctuating speed - oscillates between 0.4 and 1.0 (never backwards)
	var speed_multiplier = 0.7 + sin(oscillation_time * 1.2) * 0.3
	var current_speed = speed * speed_multiplier
	
	var sway_direction = Vector3(-direction.z, 0, direction.x)  # Perpendicular to movement
	var sway_amount = sin(oscillation_time * 2.0) * 1.5  # Sway side to side
	
	var target_velocity = direction * current_speed + sway_direction * sway_amount
	
	velocity.x = lerp(velocity.x, target_velocity.x, 8.0 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 8.0 * delta)

func retreat_from_player(delta):
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

func get_target_position() -> Vector3:
	if not player:
		return global_position
	
	match target_mode:
		TargetMode.PREDICT:
			var prediction_time = 0.5
			var predicted_pos = player.global_position + player.velocity * prediction_time
			predicted_pos.y = player.global_position.y  # Keep on ground level
			return predicted_pos
		
		TargetMode.CURRENT:
			return player.global_position
		
		TargetMode.PAST:
			var oldest_index = (history_index + 1) % history_size
			return player_history[oldest_index]
		
		_:
			return player.global_position

func pick_random_target_mode():
	var modes = [TargetMode.PREDICT, TargetMode.CURRENT, TargetMode.PAST]
	target_mode = modes[randi() % modes.size()]

func _on_died():
	Globals.enemy_died.emit("floater", global_position)
	queue_free()

func _on_health_changed(_new_health: int, _max_health: int):
	pass
