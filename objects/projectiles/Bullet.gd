extends Node3D
class_name Bullet

@export var speed: float = 50.0
@export var lifetime: float = 2.0
@export var damage: int = 10

@onready var hitbox: Area3D = $Area3D

var direction: Vector3 = Vector3.FORWARD
var lifetime_timer: float = 0.0

var piercing: int = 0

func _ready():
	lifetime_timer = lifetime
	piercing = GameState.get_jawbreaker_pierce()
	hitbox.body_entered.connect(_on_body_entered)

func _process(delta):
	global_position += direction * speed * delta

	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		queue_free()

func set_direction(new_direction: Vector3, new_speed: float = -1.0):
	direction = new_direction.normalized()
	if new_speed > 0.0:
		speed = new_speed

func _on_body_entered(body: Node):
	if body.has_node("HealthComponent"):
		var health: HealthComponent = body.get_node("HealthComponent")
		health.take_damage(damage)
		piercing -= 1
	if body.has_method("got_taffied") and GameState.get_candy_count("Taffy") > 0:
		body.got_taffied()
	if piercing < 0 or body.name == "Player":
		queue_free()
