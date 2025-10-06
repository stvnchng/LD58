extends Node
class_name CandyManager

const OFFENSIVE_CANDIES = ["CandyCorn", "Warhead", "PopRock", "RedHot", "Jawbreaker"]
const DEFENSIVE_CANDIES = ["Gum", "Apple", "Taffy", "CandyNecklace"]
const MOBILITY_CANDIES = ["PixieStick", "FunDip", "Soda"]
const UTILITY_CANDIES = ["Licorice", "CandyBar"]

const DROP_CHANCE = 1
const SPAWN_Y = 1.5
const SPAWN_SCALE = 0.75

# Reference to audio manager
var audio_manager

func _ready():
	# Get reference to audio manager (sibling node)
	audio_manager = get_node("../AudioManager")

	GameState.item_collected.connect(_on_item_collected)
	GameState.enemy_died.connect(_on_enemy_died)

func _on_item_collected(item_key: String):
	if audio_manager:
		audio_manager.play_item_get()
	if not GameState.candy_inventory.has(item_key):
		GameState.candy_inventory[item_key] = 0
	GameState.candy_inventory[item_key] += 1
	if item_key == "Apple":
		print("Apple collected")
		var player = get_tree().get_first_node_in_group("player")
		if player and player.health:
			player.health.apple_heal()

func _on_enemy_died(enemy_type: String, death_position: Vector3):
	# 25% chance to spawn candy
	if randf() > DROP_CHANCE + GameState.get_candy_bar_percent():
		return
	
	# var candy_name = select_random_candy()
	var candy_name = "Apple"
	if candy_name == null:
		return
	
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
	
	if category_candies.is_empty():
		return null
	
	return category_candies[randi() % category_candies.size()]

func spawn_candy(candy_name: String, position: Vector3):
	var candy_scene = GameState.candy_name_to_scn.get(candy_name)
	if candy_scene == null:
		push_warning("Candy scene not found: %s" % candy_name)
		return
	
	# Play drop sound
	if audio_manager:
		audio_manager.play_item_drop()
	
	var candy_instance = candy_scene.instantiate()
	
	# Set position (keep XZ, set Y to 1.5)
	candy_instance.position = Vector3(position.x, SPAWN_Y, position.z)
	candy_instance.scale = Vector3(SPAWN_SCALE, SPAWN_SCALE, SPAWN_SCALE)
	add_child(candy_instance)
	
	print("Spawned %s at position %s" % [candy_name, candy_instance.global_position])
