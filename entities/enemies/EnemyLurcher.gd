extends CharacterBody3D
class_name EnemyLurcher

@export var lurch_speed: float = 6.0  # Speed during lurch movement
@export var lurch_duration: float = 0.3  # How long each lurch lasts
@export var lurch_pause: float = 0.8  # Pause between lurches
@export var lurch_distance: float = 1.5  # Distance covered per lurch
@export var circle_radius: float = 1.75  # Distance at which to start circling
@export var circle_speed: float = 0.3  # Speed when circling player

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health: HealthComponent = $HealthComponent

var player: Player = null
var is_lurching: bool = false
var is_circling: bool = false
var lurch_timer: float = 0.0
var pause_timer: float = 0.0
var lurch_direction: Vector3 = Vector3.ZERO
var circle_direction: float = 1.0  # 1 for clockwise, -1 for counter-clockwise

var nav_update_timer: float = 0.0
var nav_update_interval: float = 0.1

func _ready():
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

	var pos = global_position
	var player_pos = player.global_position
	var dist_sq = pos.distance_squared_to(player_pos)

	# Check if we should be circling
	var circle_radius_sq = circle_radius * circle_radius
	if dist_sq <= circle_radius_sq:
		is_circling = true
	elif dist_sq > (circle_radius + 0.5) * (circle_radius + 0.5):
		is_circling = false
	
	if is_circling:
		var to_player = player_pos - pos
		to_player.y = 0
		if to_player.length_squared() > 0.0001:
			to_player = to_player.normalized()
			var tangent = Vector3(-to_player.z, 0, to_player.x) * circle_direction
			velocity.x = lerp(velocity.x, tangent.x * circle_speed, 5.0 * delta)
			velocity.z = lerp(velocity.z, tangent.z * circle_speed, 5.0 * delta)

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
			velocity.x = lurch_direction.x * lurch_speed
			velocity.z = lurch_direction.z * lurch_speed
			if lurch_direction.length_squared() > 0.0001:
				rotation.y = lerp_angle(rotation.y, atan2(lurch_direction.x, lurch_direction.z), 8.0 * delta)
			if lurch_timer <= 0.0:
				end_lurch()
	
	velocity.y = 0
	move_and_slide()

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
	queue_free()

func _on_health_changed(new_health: int, max_health: int):
	pass	
