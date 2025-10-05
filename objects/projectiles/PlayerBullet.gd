extends Node3D

@export var speed: float = 50.0
@export var lifetime: float = 5.0
@export var acceleration: float = 250.0
@export var max_speed: float = 500.0
@export var damage: int = 10

@onready var hitbox: Area3D = $Area3D

var direction: Vector3 = Vector3.FORWARD
var lifetime_timer: float = 0.0
var current_speed: float = 5.0

func _ready():
	lifetime_timer = lifetime
	hitbox.body_entered.connect(_on_body_entered)

func _process(delta):
	current_speed = min(current_speed + acceleration * delta, max_speed)
	global_position += direction * current_speed * delta

	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		queue_free()

func set_direction(new_direction: Vector3):
	direction = new_direction.normalized()

func _on_body_entered(body: Node):
	if body.has_node("HealthComponent"):
		var health: HealthComponent = body.get_node("HealthComponent")
		health.take_damage(damage)
	queue_free()
