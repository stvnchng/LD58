extends Node
class_name HealthComponent

@export var max_health: int = 30
var current_health: int

signal died
signal health_changed(new_health: int, max_health: int)

func _ready():
	current_health = max_health

func take_damage(amount: int, ignore_invincibility: bool = false):
	if get_parent() and get_parent().has_method("is_invincible") and not ignore_invincibility:
		if get_parent().is_invincible():
			return
	
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
