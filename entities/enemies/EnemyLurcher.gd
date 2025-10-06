extends CharacterBody3D
class_name EnemyLurcher

@export var lurch_speed: float = 6.0  # Speed during lurch movement
@export var lurch_duration: float = 0.3  # How long each lurch lasts
@export var lurch_pause: float = 0.8  # Pause between lurches
@export var lurch_distance: float = 1.5  # Distance covered per lurch
@export var circle_radius: float = 1.75  # Distance at which to start circling
@export var circle_speed: float = 0.3  # Speed when circling player
@export var contact_damage: int = 5  # Damage dealt on contact
@export var damage_cooldown: float = 1.0  # Cooldown between damage ticks
@export var attack_range: float = 2  # Range to check for player in front

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: HealthComponent = $HealthComponent

var bleeding: bool = false
var bleeding_timer: float = 0.0
var bleeding_tick_timer: float = 0.0

var burning: bool = false
var burning_timer: float = 0.0
var burning_tick_timer: float = 0.0

var player: Player = null
var is_lurching: bool = false
var is_circling: bool = false
var lurch_timer: float = 0.0
var pause_timer: float = 0.0
var lurch_direction: Vector3 = Vector3.ZERO
var circle_direction: float = 1.0  # 1 for clockwise, -1 for counter-clockwise
var is_taffied: bool = false
var nav_update_timer: float = 0.0
var nav_update_interval: float = 0.1
var damage_cooldown_timer: float = 0.0

func get_lurch_speed() -> float:
	if GameState.get_candy_count("Taffy") == 0 or not is_taffied:
		return lurch_speed
	return lurch_speed * GameState.get_taffy_slow_percent()

func get_circle_speed() -> float:
	if GameState.get_candy_count("Taffy") == 0 or not is_taffied:
		return circle_speed
	return circle_speed * GameState.get_taffy_slow_percent()

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	call_deferred("actor_setup")
	pause_timer = lurch_pause 
	circle_direction = 1.0 if randf() > 0.5 else -1.0  # Random initial circle direction

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

	# Update damage cooldown
	if damage_cooldown_timer > 0.0:
		damage_cooldown_timer -= delta

	var pos = global_position
	var player_pos = player.global_position
	var dist_sq = pos.distance_squared_to(player_pos)

	# Check if we should be circling
	var circle_radius_sq = circle_radius * circle_radius
	if dist_sq <= circle_radius_sq:
		is_circling = true
	elif dist_sq > (circle_radius + 0.5) * (circle_radius + 0.5):
		is_circling = false

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
	
	if is_circling:
		var to_player = player_pos - pos
		to_player.y = 0
		if to_player.length_squared() > 0.0001:
			to_player = to_player.normalized()
			var tangent = Vector3(-to_player.z, 0, to_player.x) * circle_direction
			velocity.x = lerp(velocity.x, tangent.x * get_circle_speed(), 5.0 * delta)
			velocity.z = lerp(velocity.z, tangent.z * get_circle_speed(), 5.0 * delta)

			var target_rotation = atan2(to_player.x, to_player.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, 8.0 * delta)
	else:
		nav_update_timer += delta
		if nav_update_timer >= nav_update_interval:
			set_movement_target(player_pos)
			nav_update_timer = 0.0

		if not is_lurching:
			pause_timer -= delta
			if pause_timer <= 0.0:
				start_lurch()
			else:
				velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
				velocity.z = lerp(velocity.z, 0.0, 8.0 * delta)
		else:
			lurch_timer -= delta
			velocity.x = lurch_direction.x * get_lurch_speed()
			velocity.z = lurch_direction.z * get_lurch_speed()
			if lurch_direction.length_squared() > 0.0001:
				rotation.y = lerp_angle(rotation.y, atan2(lurch_direction.x, lurch_direction.z), 8.0 * delta)
			if lurch_timer <= 0.0:
				end_lurch()
	
	velocity.y = 0
	move_and_slide()
	
	# Check for contact damage with player (collision-based)
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if we hit the player
		if collider and collider.has_method("is_player") and collider.is_player():
			# Deal damage if cooldown has expired
			if damage_cooldown_timer <= 0.0:
				if collider.has_node("HealthComponent"):
					var player_health = collider.get_node("HealthComponent")
					player_health.take_damage(contact_damage)
					damage_cooldown_timer = damage_cooldown
	
	# Check for player in front of lurcher (raycast-based)
	check_forward_attack()

func check_forward_attack():
	if damage_cooldown_timer > 0.0 or not player:
		return
	
	# Check if player is within attack range and in front of us
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	
	# Only attack if player is close enough
	if distance <= attack_range:
		# Check if player is generally in front (using dot product)
		var forward_dir = -global_transform.basis.z  # Forward direction
		to_player = to_player.normalized()
		var dot = forward_dir.dot(to_player)
		
		# If dot > 0.5, player is within ~60 degrees in front of us
		if dot > 0.5:
			if player.has_node("HealthComponent"):
				var player_health = player.get_node("HealthComponent")
				player_health.take_damage(contact_damage)
				damage_cooldown_timer = damage_cooldown

func start_lurch():
	is_lurching = true
	lurch_timer = lurch_duration
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	lurch_direction = (next_path_position - current_agent_position).normalized()

func end_lurch():
	is_lurching = false
	pause_timer = lurch_pause

func _on_died():
	Globals.spawn_death_effect(global_position, get_tree().root)
	GameState.enemy_died.emit("lurcher", global_position)
	queue_free()

func _on_health_changed(_new_health: int, _max_health: int):
	pass

func bleed():
	bleeding = true
	bleeding_timer = Globals.bleeding_duration
	bleeding_tick_timer = Globals.bleeding_interval

func start_burning():
	burning = true
	burning_timer = Globals.burning_duration
	burning_tick_timer = Globals.burning_interval

func got_taffied():
	is_taffied = true
