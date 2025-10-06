extends Node
class_name CandyManager

const OFFENSIVE_CANDIES = ["CandyCorn", "Warhead", "PopRock", "RedHot", "Jawbreaker"]
const DEFENSIVE_CANDIES = ["Gum", "Apple", "Taffy", "CandyNecklace"]
const MOBILITY_CANDIES = ["PixieStick", "FunDip", "Soda"]
const UTILITY_CANDIES = ["CandyBar"]

const DROP_CHANCE = 0.2
const SPAWN_Y = 1.5
const SPAWN_SCALE = 0.75
const DROP_COOLDOWN_DURATION = 5.0  # Time for drop chance to recover to full

# Reference to audio manager
var audio_manager
# Cooldown timer for candy drops
var drop_cooldown_timer: float = 0.0

func _ready():
	# Get reference to audio manager (sibling node)
	audio_manager = get_node("../AudioManager")

	GameState.item_collected.connect(_on_item_collected)
	GameState.enemy_died.connect(_on_enemy_died)

func _process(delta: float):
	# Update drop cooldown timer
	if drop_cooldown_timer > 0.0:
		drop_cooldown_timer -= delta

func _on_item_collected(item_key: String):
	if audio_manager:
		audio_manager.play_item_get()
	if not GameState.candy_inventory.has(item_key):
		GameState.candy_inventory[item_key] = 0
	GameState.candy_inventory[item_key] += 1
	if item_key == "Apple":
		var player = get_tree().get_first_node_in_group("player")
		if player and player.health:
			player.health.apple_heal()

func _on_enemy_died(_enemy_type: String, death_position: Vector3):
	# Red Hot explosion
	if GameState.get_candy_count("RedHot") > 0:
		trigger_explosion(death_position)
	
	# Calculate drop chance based on cooldown
	# Scales from 0 (when cooldown is full) to full drop chance (when cooldown is 0)
	var cooldown_multiplier = 1.0 - clamp(drop_cooldown_timer / DROP_COOLDOWN_DURATION, 0.0, 1.0)
	var current_drop_chance = (DROP_CHANCE + GameState.get_candy_bar_percent()) * cooldown_multiplier
	
	# Check if candy should drop
	if randf() > current_drop_chance:
		return
	
	var candy_name = select_random_candy()
	if candy_name == null:
		return
	
	spawn_candy(candy_name, death_position)
	
	# Reset cooldown timer when candy spawns
	drop_cooldown_timer = DROP_COOLDOWN_DURATION

func select_random_candy():
	var roll = randf()
	var category_candies = []
	
	if roll < 0.32:
		category_candies = OFFENSIVE_CANDIES
	elif roll < 0.64:
		category_candies = DEFENSIVE_CANDIES
	elif roll < 0.98:
		category_candies = MOBILITY_CANDIES
	else:
		category_candies = UTILITY_CANDIES
	
	if category_candies.is_empty():
		return null
	
	return category_candies[randi() % category_candies.size()]

func trigger_explosion(death_position: Vector3):
	var explosion_radius = GameState.get_red_hot_radius()
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		var distance = enemy.global_position.distance_to(death_position)
		if distance <= explosion_radius:
			if enemy.has_method("start_burning"):
				enemy.start_burning()

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
	
