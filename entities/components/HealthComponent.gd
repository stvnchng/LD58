extends Node
class_name HealthComponent

@export var max_health: int = 30
var current_health: int

signal died
signal health_changed(new_health: int, max_health: int)

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health = clamp(current_health - amount, 0, max_health)
	emit_signal("health_changed", current_health, max_health)

	if current_health <= 0:
		emit_signal("died")

func heal(amount: int):
	current_health = clamp(current_health + amount, 0, max_health)
	emit_signal("health_changed", current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func reset_health():
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
