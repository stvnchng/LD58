extends Node

# Candy categories with their items
const OFFENSIVE_CANDIES = ["CandyCorn", "Warhead", "PopRock", "RedHot", "Jawbreaker"]
const DEFENSIVE_CANDIES = ["Gum", "Apple", "Taffy", "CandyNecklace"]
const MOBILITY_CANDIES = ["PixieStick", "FunDip", "Soda"]
const UTILITY_CANDIES = ["Licorice", "CandyBar"]

# Candy scene references (preloaded for performance)
var candy_scenes = {
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

# Track collected candies
var candy_inventory = {}

# Spawn settings
const DROP_CHANCE = 0.25  # 25% chance to spawn candy on enemy death
const SPAWN_Y = 1.5
const SPAWN_SCALE = 0.75

# Reference to audio manager
var audio_manager

func _ready():
	# Initialize inventory with all candy types at 0
	for candy_name in candy_scenes.keys():
		candy_inventory[candy_name] = 0
	
	# Connect to global signals
	Globals.item_collected.connect(_on_item_collected)
	Globals.enemy_died.connect(_on_enemy_died)
	
	# Get reference to audio manager (sibling node)
	audio_manager = get_node("../AudioManager")
	
	print("Candy Manager initialized with %d candy types" % candy_scenes.size())

func _on_item_collected(item_key: String):
	# Play pickup sound
	if audio_manager:
		audio_manager.play_item_get()
	
	# Increment the candy count
	if candy_inventory.has(item_key):
		candy_inventory[item_key] += 1
		print("Collected %s! Total: %d" % [item_key, candy_inventory[item_key]])
	else:
		push_warning("Unknown candy type collected: %s" % item_key)

func _on_enemy_died(enemy_type: String, death_position: Vector3):
	# 25% chance to spawn candy
	if randf() > DROP_CHANCE:
		return
	
	# Select random candy based on weighted categories
	var candy_name = select_random_candy()
	if candy_name == null:
		return
	
	# Spawn the candy
	spawn_candy(candy_name, death_position)

func select_random_candy():
	# Category weights: Offensive 30%, Defensive 30%, Mobility 30%, Utility 10%
	var roll = randf()
	var category_candies = []
	
	if roll < 0.30:
		# Offensive (0.0 - 0.30)
		category_candies = OFFENSIVE_CANDIES
	elif roll < 0.60:
		# Defensive (0.30 - 0.60)
		category_candies = DEFENSIVE_CANDIES
	elif roll < 0.90:
		# Mobility (0.60 - 0.90)
		category_candies = MOBILITY_CANDIES
	else:
		# Utility (0.90 - 1.0)
		category_candies = UTILITY_CANDIES
	
	# Select random candy from the chosen category
	if category_candies.is_empty():
		return null
	
	return category_candies[randi() % category_candies.size()]

func spawn_candy(candy_name: String, position: Vector3):
	var candy_scene = candy_scenes.get(candy_name)
	if candy_scene == null:
		push_warning("Candy scene not found: %s" % candy_name)
		return
	
	# Play drop sound
	if audio_manager:
		audio_manager.play_item_drop()
	
	var candy_instance = candy_scene.instantiate()
	
	# Set position (keep XZ, set Y to 1.5)
	candy_instance.position = Vector3(position.x, SPAWN_Y, position.z)
	
	# Set scale to 0.75 on all axes
	candy_instance.scale = Vector3(SPAWN_SCALE, SPAWN_SCALE, SPAWN_SCALE)
	
	# Add to the scene (assuming this manager is a child of the level/game node)
	get_parent().add_child(candy_instance)
	
	print("Spawned %s at position %s" % [candy_name, candy_instance.global_position])

# Getter for candy counts (useful for UI or other systems)
func get_candy_count(candy_name: String) -> int:
	return candy_inventory.get(candy_name, 0)

# Get total count of all candies
func get_total_candy_count() -> int:
	var total = 0
	for count in candy_inventory.values():
		total += count
	return total

# Get count by category
func get_category_count(category: String) -> int:
	var total = 0
	var candies = []
	
	match category.to_lower():
		"offensive":
			candies = OFFENSIVE_CANDIES
		"defensive":
			candies = DEFENSIVE_CANDIES
		"mobility":
			candies = MOBILITY_CANDIES
		"utility":
			candies = UTILITY_CANDIES
	
	for candy_name in candies:
		total += get_candy_count(candy_name)
	
	return total
