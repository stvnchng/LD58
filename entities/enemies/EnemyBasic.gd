extends CharacterBody3D
class_name Enemy

@export var speed: float = 3.0
@export var acceleration: float = 10.0
@export var ideal_radius: float = 8.0  # Distance at which to stop chasing
@export var max_radius: float = 12.0  # Maximum distance before returning to chase
@export var wander_speed: float = 0.75  # Speed when wandering

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: HealthComponent = $HealthComponent

# Targeting modes for more natural pathfinding
enum TargetMode { PREDICT, CURRENT, PAST }

var player: Player = null
var is_chasing: bool = true
var wander_target: Vector3 = Vector3.ZERO
var wander_radius: float = 0.0

var target_mode: TargetMode = TargetMode.CURRENT
var mode_switch_timer: float = 0.0
var next_mode_switch_time: float = 0.0
var player_position_history: Array[Vector3] = []
var history_sample_time: float = 0.0
var history_duration: float = 1.0  # Track position from 1 second ago

func _ready():
	player = get_tree().get_first_node_in_group("player")
	wander_radius = max_radius - ideal_radius
	call_deferred("actor_setup")
	# Initialize targeting mode
	pick_random_target_mode()
	next_mode_switch_time = randf_range(5.0, 10.0)
	
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

func actor_setup():
	await get_tree().physics_frame
	if player:
		set_movement_target(player.global_position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.target_position = movement_target

func _physics_process(delta):
	if not player:
		return

	update_player_history(delta)
	
	# Update target mode switching timer
	mode_switch_timer += delta
	if mode_switch_timer >= next_mode_switch_time:
		pick_random_target_mode()
		mode_switch_timer = 0.0
		next_mode_switch_time = randf_range(5.0, 10.0)

	var target_position = get_target_position()

	var distance_to_player = global_position.distance_to(target_position)
	
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
			# Continue chasing - use smart target
			set_movement_target(target_position)
			
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

func update_player_history(delta: float):
	if not player:
		return
	
	# Sample player position every frame
	history_sample_time += delta
	player_position_history.append(player.global_position)
	
	# Keep only positions from the last second
	var samples_to_keep = int(history_duration / delta) if delta > 0 else 60
	if player_position_history.size() > samples_to_keep:
		player_position_history.pop_front()

func get_target_position() -> Vector3:
	if not player:
		return global_position
	
	match target_mode:
		TargetMode.PREDICT:
			var prediction_time = 0.5  # Predict 0.5 seconds ahead
			var predicted_pos = player.global_position + player.velocity * prediction_time
			predicted_pos.y = player.global_position.y  # Keep on ground level
			return predicted_pos
		
		TargetMode.CURRENT:
			return player.global_position
		
		TargetMode.PAST:
			# Target where player was 1 second ago
			if player_position_history.size() > 0:
				return player_position_history[0]
			return player.global_position
		_:
			return player.global_position

func pick_random_target_mode():
	var modes = [TargetMode.PREDICT, TargetMode.CURRENT, TargetMode.PAST]
	target_mode = modes[randi() % modes.size()]

func _on_died():
	queue_free()

func _on_health_changed(new_health: int, max_health: int):
	pass
