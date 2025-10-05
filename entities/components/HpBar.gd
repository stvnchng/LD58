extends Sprite3D
class_name HPBar

@onready var bar: ProgressBar = $SubViewport/ProgressBar
var health: HealthComponent

func _ready():
	health = get_parent().get_node_or_null("HealthComponent")
	if health == null:
		push_warning("HPBar: No HealthComponent found on parent")
		return
	bar.max_value = health.max_health
	bar.value = health.current_health
	health.health_changed.connect(_on_health_changed)

func _on_health_changed(new_health: int, max_health: int):
	bar.max_value = max_health
	bar.value = new_health
