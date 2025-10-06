extends CharacterBody3D
class_name Enemy

@export var speed: float = 3.0
@export var acceleration: float = 10.0
@export var ideal_radius: float = 8.0  # Distance at which to stop chasing
@export var max_radius: float = 12.0  # Maximum distance before returning to chase
@export var wander_speed: float = 0.75  # Speed when wandering

var nav_update_timer: float = 0.0
var nav_update_interval: float = 0.1

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: HealthComponent = $HealthComponent
@onready var shooting: ShootingComponent = $ShootingComponent

var is_taffied: bool = false

var burning: bool = false
var burning_timer: float = 0.0
var burning_tick_timer: float = 0.0

var bleeding: bool = false
var bleeding_timer: float = 0.0
var bleeding_tick_timer: float = 0.0

# Targeting modes for more natural pathfinding
enum TargetMode { PREDICT, CURRENT, PAST }

var player: Player = null
var is_chasing: bool = true
var wander_target: Vector3 = Vector3.ZERO
var wander_radius: float = 0.0

var target_mode: TargetMode = TargetMode.CURRENT
var mode_switch_timer: float = 0.0
var next_mode_switch_time: float = 0.0

var history_size: int = 60          # Max number of samples (1 second at 60 FPS)
var player_history: Array = []      # Preallocated ring buffer
var history_index: int = 0          # Current write index

func move_speed() -> float:
	if GameState.get_candy_count("Taffy") == 0 or not is_taffied:
		return speed
	return speed * GameState.get_taffy_slow_percent()

func get_wander_speed() -> float:
	if GameState.get_candy_count("Taffy") == 0 or not is_taffied:
		return wander_speed
	return wander_speed * GameState.get_taffy_slow_percent()

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	wander_radius = max_radius - ideal_radius
	call_deferred("actor_setup")
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

	if bleeding:
		bleeding_timer -= delta
		bleeding_tick_timer -= delta
		
		if bleeding_timer <= 0.0:
			bleeding = false
		
		# Deal damage once per second
		if bleeding_tick_timer <= 0.0:
			health.take_percent_damage(Globals.bleeding_damage)
			bleeding_tick_timer = Globals.bleeding_interval
	
	if burning:
		burning_timer -= delta
		burning_tick_timer -= delta
		
		if burning_timer <= 0.0:
			burning = false
		
		# Deal damage once per second
		if burning_tick_timer <= 0.0:
			health.take_percent_damage(Globals.burning_damage)
			burning_tick_timer = Globals.burning_interval

	var player_pos = player.global_position
	var enemy_pos = global_position

	history_index = (history_index + 1) % history_size
	player_history[history_index] = player_pos
	
	mode_switch_timer += delta
	if mode_switch_timer >= next_mode_switch_time:
		pick_random_target_mode()
		mode_switch_timer = 0.0
		next_mode_switch_time = randf_range(5.0, 10.0)

	var target_position = get_target_position()
	var to_target = target_position - enemy_pos
	to_target.y = 0
	var distance_sq = to_target.length_squared()

	# face player
	var to_player = player_pos - enemy_pos
	to_player.y = 0
	if to_player.length_squared() > 0.01:
		var target_rotation = atan2(to_player.x, to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)

	if distance_sq > max_radius * max_radius:
		is_chasing = true
	
	if is_chasing:
		if distance_sq <= ideal_radius * ideal_radius:
			is_chasing = false
			pick_new_wander_target()
		else:
			# Continue chasing - use smart target
			nav_update_timer += delta
			if nav_update_timer >= nav_update_interval:
				set_movement_target(target_position)
				nav_update_timer = 0.0

		if not navigation_agent.is_navigation_finished():
			var next_path_pos = navigation_agent.get_next_path_position()
			var move_dir = (next_path_pos - enemy_pos)
			move_dir.y = 0
			var target_velocity = Vector3.ZERO
			if move_dir.length_squared() > 0.0001:
				move_dir = move_dir.normalized()
				target_velocity = move_dir * move_speed()
			velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
			velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)

	else:		
		if enemy_pos.distance_squared_to(wander_target) < 0.25:
			pick_new_wander_target()
		else:
			var wander_dir = (wander_target - enemy_pos)
			wander_dir.y = 0
			if wander_dir.length_squared() > 0.0001:
				wander_dir = wander_dir.normalized()
				velocity.x = lerp(velocity.x, wander_dir.x * get_wander_speed(), acceleration * delta)
				velocity.z = lerp(velocity.z, wander_dir.z * get_wander_speed(), acceleration * delta)

	# Shooting logic - works in both chase and wander states
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d() if viewport else null
	var on_screen = false
	
	if camera:
		var screen_pos = camera.unproject_position(global_position)
		on_screen = screen_pos.x >= 0 and screen_pos.x <= viewport.size.x \
			and screen_pos.y >= 0 and screen_pos.y <= viewport.size.y

	if on_screen:
		# Always shoot towards the player
		shooting.shoot_direction = to_player.normalized()
		shooting.try_shoot()

	velocity.y = 0
	move_and_slide()

func pick_new_wander_target():
	# Pick a random point within wander_radius from current position
	var random_angle = randf() * TAU
	var random_distance = randf() * wander_radius
	
	var offset = Vector3(cos(random_angle) * random_distance, 0, sin(random_angle) * random_distance)
	wander_target = global_position + offset
	wander_target.y = global_position.y  # Keep on same Y level

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
			var oldest_index = (history_index + 1) % history_size
			return player_history[oldest_index]
		_:
			return player.global_position

func pick_random_target_mode():
	var modes = [TargetMode.PREDICT, TargetMode.CURRENT, TargetMode.PAST]
	target_mode = modes[randi() % modes.size()]

func _on_died():
	Globals.spawn_death_effect(global_position, get_tree().root)
	GameState.enemy_died.emit("basic", global_position)
	queue_free()

func _on_health_changed(_new_health: int, _max_health: int):
	pass

func got_taffied():
	is_taffied = true

func bleed():
	bleeding = true
	bleeding_timer = Globals.bleeding_duration
	bleeding_tick_timer = Globals.bleeding_interval

func start_burning():
	burning = true
	burning_timer = Globals.burning_duration
	burning_tick_timer = Globals.burning_interval