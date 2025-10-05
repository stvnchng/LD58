extends Node

# Enemy death signal - emitted when any enemy dies
# enemy_type: String - "basic", "lurcher", or "floater"
# death_position: Vector3 - global position where enemy died
signal enemy_died(enemy_type: String, death_position: Vector3)

# Item collected signal - emitted when player collects an item
# item_key: String - identifier for the item type (e.g., "APPLE")
signal item_collected(item_key: String)

var survival_time: float = 0.0
var timer_running: bool = false

var candy_inventory: Dictionary[String, int] = {}

const candy_name_to_scn: Dictionary[String, PackedScene] = {
	# Offensive
	"CandyCorn": preload("res://objects/candy/CandyCorn.tscn"),
	"Warhead": preload("res://objects/candy/Warhead.tscn"),
	"PopRock": preload("res://objects/candy/PopRock.tscn"),
	"RedHot": preload("res://objects/candy/RedHot.tscn"),
	"Jawbreaker": preload("res://objects/candy/Jawbreaker.tscn"),
	# Defensive
	"Gum": preload("res://objects/candy/Gum.tscn"),
	"Apple": preload("res://objects/candy/Apple.tscn"),
	"Taffy": preload("res://objects/candy/Taffy.tscn"),
	"CandyNecklace": preload("res://objects/candy/CandyNecklace.tscn"),
	# Mobility
	"PixieStick": preload("res://objects/candy/PixieStick.tscn"),
	"FunDip": preload("res://objects/candy/FunDip.tscn"),
	"Soda": preload("res://objects/candy/Soda.tscn"),
	# Utility
	"Licorice": preload("res://objects/candy/Licorice.tscn"),
	"CandyBar": preload("res://objects/candy/CandyBar.tscn")
}

var kill_counts: Dictionary = {
	"basic": 0,
	"lurcher": 0,
	"floater": 0
}

func _ready():
	enemy_died.connect(_update_kill_count)
	start_timer()

func _update_kill_count(enemy_type: String, _death_position: Vector3):
	kill_counts[enemy_type] += 1

func start_timer() -> void:
	survival_time = 0.0
	timer_running = true

func stop_timer() -> void:
	timer_running = false

func _process(delta: float) -> void:
	if timer_running:
		survival_time += delta
		

func get_minutes_seconds() -> Array:
	var minutes = int(survival_time) / 60
	var seconds = int(survival_time) % 60
	return [minutes, seconds]

func get_candy_count(candy_name: String) -> int:
	return candy_inventory.get(candy_name, 0)

func add_kill(enemy_name: String) -> void:
	if kill_counts.has(enemy_name):
		kill_counts[enemy_name] += 1

func get_kills(enemy_name: String) -> int:
	return kill_counts.get(enemy_name, 0)
