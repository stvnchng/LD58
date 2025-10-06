extends CharacterBody3D
class_name Player

@export var speed: float = 5.0
@export var rotation_speed: float = 10.0

@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var footstep_interval: float = 0.35  # Time between footsteps
@export var walk_animation_speed: float = 3.0  # Speed multiplier for walk animation
@export var combat_duration: float = 3.0  # Time to stay in combat after shooting
@export var speed_boost_decay_rate: float = 2.0  # How quickly speed boost decays (higher = faster)

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var footstep_timer: float = 0.0
var combat_timer: float = 0.0
var necklace_cooldown_timer: float = 0.0
var necklace_active: bool = false

@onready var camera_rig = $CameraRig
@onready var camera = $CameraRig/Camera3D
@onready var health: HealthComponent = $HealthComponent
@onready var shooting : ShootingComponent = $ShootingComponent
@onready var dash_trail: Trail3D = $Trail3D
@onready var animation_player: AnimationPlayer = $wiz/AnimationPlayer
@onready var candy_necklace: Node3D = $CandyNecklace

var last_mouse_direction: Vector3
var footstep_sound = preload("res://assets/sounds/footstep.wav")
var footstep_player: AudioStreamPlayer
var previous_health: int
var walk_animation_name: String = ""
var in_combat: bool = false

var current_movespeed: float = 0.0

func move_speed() -> float:
	if in_combat:
		return speed * GameState.get_move_speed_multiplier()
	else:
		return speed * GameState.get_move_speed_multiplier() * GameState.get_soda_move_speed()

func dash_speed() -> float:
	return current_movespeed * 4



func _ready():
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	GameState.enemy_died.connect(_on_enemy_died)
	previous_health = health.current_health
	current_movespeed = move_speed()
	

	update_necklace_visibility()
	
	# Create footstep audio player
	footstep_player = AudioStreamPlayer.new()
	footstep_player.stream = footstep_sound
	footstep_player.volume_db = -4.0
	footstep_player.bus = "SFX"
	add_child(footstep_player)
	
	# Find walk animation name
	if animation_player:
		var anim_list = animation_player.get_animation_list()
		print("Available animations: ", anim_list)
		
		# Look for walk animation, or use the first available animation
		for anim in anim_list:
			var anim_lower = anim.to_lower()
			if "walk" in anim_lower or "action" in anim_lower:
				walk_animation_name = anim
				print("Using walk animation: %s" % walk_animation_name)
				break
		
		# If still not found, just use the first animation
		if walk_animation_name == "" and anim_list.size() > 0:
			walk_animation_name = anim_list[0]
			print("Using first animation as walk: %s" % walk_animation_name)
	else:
		print("Error: AnimationPlayer not found!")

func _on_enemy_died(_enemy_type: String, _death_position: Vector3):
	# Set to max speed boost, or keep current if already higher
	var boosted_speed = move_speed() * GameState.get_fun_dip_max_speed()
	current_movespeed = max(current_movespeed, boosted_speed)

func _physics_process(delta):
	if dash_timer > 0.0:
		dash_timer -= delta
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	
	# Handle combat timer
	if combat_timer > 0.0:
		combat_timer -= delta
		if combat_timer <= 0.0:
			in_combat = false

	# Decay speed boost proportionally to excess speed (exponential decay)
	if current_movespeed > move_speed():
		var excess_speed = current_movespeed - move_speed()
		current_movespeed -= excess_speed * speed_boost_decay_rate * delta
		# Clamp to prevent going below base speed
		current_movespeed = max(current_movespeed, move_speed())
	
	# Handle candy necklace cooldown
	if not necklace_active and GameState.get_candy_count("CandyNecklace") > 0:
		necklace_cooldown_timer -= delta
		if necklace_cooldown_timer <= 0.0:
			necklace_active = true
			update_necklace_visibility()

	var input = Vector3.ZERO
	if Input.is_action_pressed("move_up"):
		input.z -= 1
	if Input.is_action_pressed("move_down"):
		input.z += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1

	input = input.normalized()

	var angle = deg_to_rad(45)
	var rotated_input = Vector3(
		input.x * cos(angle) - input.z * sin(angle), 0, input.x * sin(angle) + input.z * cos(angle)
	)
	input = rotated_input
	
	if Input.is_action_just_pressed("dash") and dash_timer <= 0.0 and dash_cooldown_timer <= 0.0:
		start_dash(input)

	dash_trail.enabled = (dash_timer > 0.0)
	if dash_timer > 0.0:
		velocity = dash_direction * dash_speed()
	else:
		velocity.x = input.x * current_movespeed
		velocity.z = input.z * current_movespeed
		velocity.y = 0

	# Raycast from mouse to ground plane to get target position
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var plane = Plane(Vector3.UP, global_position.y)
	var intersection = plane.intersects_ray(from, to - from)

	if intersection:
		var direction = intersection - global_position
		direction.y = 0  # Keep rotation on horizontal plane

		if direction.length() > 0.1:  # Add deadzone to prevent jittering
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
			last_mouse_direction = direction.normalized()
			shooting.shoot_direction = last_mouse_direction

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shooting.try_shoot()
		# Enter combat mode and reset timer
		in_combat = true
		combat_timer = combat_duration

	if camera_rig:
		camera_rig.global_rotation.y = 0

	move_and_slide()
	
	# Handle footsteps
	var is_moving = velocity.length() > 0.1
	var is_dashing = dash_timer > 0.0
	
	if is_moving and not is_dashing:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			# Play footstep with pitch variation
			footstep_player.pitch_scale = randf_range(0.9, 1.1)
			footstep_player.play()
			footstep_timer = footstep_interval
	else:
		# Reset timer when not moving so first step plays immediately
		footstep_timer = 0.0
	
	# Handle walk animation
	if animation_player and walk_animation_name != "":
		if is_moving and not is_dashing:
			# Play walk animation if not already playing
			if not animation_player.is_playing() or animation_player.current_animation != walk_animation_name:
				animation_player.speed_scale = walk_animation_speed * GameState.get_move_speed_multiplier()
				animation_player.play(walk_animation_name)
		else:
			# Stop animation or play idle when not moving
			if animation_player.is_playing() and animation_player.current_animation == walk_animation_name:
				animation_player.stop()


func start_dash(input: Vector3):
	if input.length() > 0.1:
		dash_direction = input.normalized()
	else:
		dash_direction = last_mouse_direction.normalized()

	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Emit dash signal for sound
	Globals.player_dash.emit()

func is_invincible() -> bool:
	# Check dash invincibility
	if dash_timer > 0.0:
		return true
	
	# Check candy necklace shield
	if necklace_active:
		# Consume the necklace shield
		necklace_active = false
		necklace_cooldown_timer = GameState.get_candy_necklace_cooldown()
		update_necklace_visibility()
		print("Candy Necklace blocked damage! Cooldown: %.1f seconds" % necklace_cooldown_timer)
		return true
	
	return false

func update_necklace_visibility():
	if not candy_necklace:
		return

	if GameState.get_candy_count("CandyNecklace") == 0:
		candy_necklace.visible = false
	
	if necklace_active:
		candy_necklace.visible = true
	else:
		candy_necklace.visible = false
	
func is_player() -> bool:
	return true

func _on_died():
	print('u died bro')
	queue_free()

func _on_health_changed(new_health: int, _max_health: int):
	# Emit hurt signal if health decreased
	if new_health < previous_health:
		Globals.player_hurt.emit()
	previous_health = new_health
