extends Node3D
class_name ShootingComponent

@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.3
@export var projectile_speed: float = 20.0
@export var entity_type: String = ""  # "player", "floater", "basic", etc.


var fire_cooldown: float = 0.0
var shoot_direction: Vector3 = Vector3.FORWARD

func _process(delta):
	if fire_cooldown > 0.0:
		fire_cooldown -= delta

func try_shoot():
	if entity_type == "player":
		player_shoot()
	else:
		enemy_shoot()

func player_shoot():
	if fire_cooldown > 0.0 or projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = global_position + Vector3(0, 0.5, 0) + shoot_direction * 0.5
	if projectile.has_method("set_direction"):
		projectile.set_direction(shoot_direction, projectile_speed)
	
	# Emit shoot sound signal
	if entity_type != "":
		Globals.shoot_sound.emit(entity_type)
	
	fire_cooldown = fire_rate * (1 / GameState.get_attack_speed_multiplier())

func enemy_shoot():
	if fire_cooldown > 0.0 or projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = global_position + Vector3(0, 0.5, 0) + shoot_direction * 0.5
	if projectile.has_method("set_direction"):
		projectile.set_direction(shoot_direction, projectile_speed)
	
	# Emit shoot sound signal
	if entity_type != "":
		Globals.shoot_sound.emit(entity_type)
	
	fire_cooldown = fire_rate