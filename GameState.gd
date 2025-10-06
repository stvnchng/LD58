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
var game_over = false

func current_difficulty() -> float:
	return pow(Globals.difficulty_multiplier, survival_time)

var candy_inventory: Dictionary[String, int] = {}
func get_attack_speed_multiplier() -> float:
	return 1.0 + 0.05 * candy_inventory.get("CandyCorn", 0)
func get_move_speed_multiplier() -> float:
	return 1.0 + 0.05 * candy_inventory.get("PixieStick", 0)
func get_red_hot_radius() -> float:
	return 3 + candy_inventory.get("RedHot", 0)
func get_pop_rock_percent() -> float:
	return min(1.0, 0.0 + 0.05 * candy_inventory.get("PopRock", 0))
func get_warhead_percent() -> float:
	return min(1.0, 0.0 + 0.05 * candy_inventory.get("Warhead", 0))
func get_jawbreaker_pierce() -> int:
	return 0 + candy_inventory.get("Jawbreaker", 0)
func get_gum_armor() -> float:
	return pow(0.95, candy_inventory.get("Gum", 0))
func get_apple_healing_percent() -> float:
	return log(candy_inventory.get("Apple", 0) + 1) / (2.0 * 2.71828)
func get_taffy_slow_percent() -> float:
	return pow(0.95, candy_inventory.get("Taffy", 0))
func get_candy_necklace_cooldown() -> float:
	return 8.0 * pow(0.95, candy_inventory.get("CandyNecklace", 0))
func get_fun_dip_max_speed() -> float:
	return 1.0 + 0.1 * candy_inventory.get("FunDip", 0)
func get_soda_move_speed() -> float:
	return 1.0 + 0.05 * candy_inventory.get("Soda", 0)
func get_licorice_pull_number() -> int:
	return 0 + candy_inventory.get("Licorice", 0)
func get_candy_bar_percent() -> float:
	return log(candy_inventory.get("CandyBar", 0) + 1) / (2.0 * 2.71828)

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

const candy_name_to_desc := {
	# Offensive
	"CandyCorn": "Increases attack speed by 5% per corn",
	"Warhead": "Increases burn chance by 5% per candy",
	"PopRock": "Increases explosion chance by 5% per packet",
	"RedHot": "Enemies explode on death, applying burn to nearby enemies. Increases radius by 1m per candy.",
	"Jawbreaker": "Attacks will hit +1 more enemy per candy.",
	# Defensive
	"Gum": "Reduces damage by 5% per roll.",
	"Apple": "Restores a bit of health.",
	"Taffy": "Reduces enemy speed by 5% per taffy",
	"CandyNecklace": "Creates a temporary shield to block the next attack. Reduces cooldown by 5% per necklace.",
	# Mobility
	"PixieStick": "Increases movement speed by 5% per stick",
	"FunDip": "Gives a brief speed burst after kills. Increases max speed by 10% per packet.",
	"Soda": "Increases movement speed by 5% out of combat per can",
	# Utility
	"Licorice": "Roots enemies in place. +1 enemy per licorice.",
	"CandyBar": "Increases drop rate per candy bar"
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

func get_total_kills() -> int:
	var total = 0
	for count in kill_counts.values():
		total += count
	return total

func restart_game():
	game_over = false
	candy_inventory.clear()
	for enemy in kill_counts.keys():
		kill_counts[enemy] = 0
	get_tree().reload_current_scene()
