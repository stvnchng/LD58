extends Node

# Enemy scene references
var enemy_scenes = {
	"basic": preload("res://entities/enemies/enemy.tscn"),
	"lurcher": preload("res://entities/enemies/enemy_lurcher.tscn"),
	"floater": preload("res://entities/enemies/enemy_floater.tscn")
}

# Enemy data with costs and weights
const ENEMY_DATA = {
	"lurcher": {"cost": 10, "weight": 45},
	"basic": {"cost": 12, "weight": 35},
	"floater": {"cost": 15, "weight": 20}
}

const budget_growth = 6.0
# Randomly select a spawn point, avoiding the most recent one
var last_spawn_point = null
var spawn_points = []

var spender_budget = 0.0
var saver_budget = 0.0

var spawn_check_timer = 0.0
const SPAWN_CHECK_INTERVAL = 1.0  # Check once per second


func _ready():
	# Import spawn points from the Spawns node
	var spawns_node = get_node("../Spawns")
	if spawns_node:
		for child in spawns_node.get_children():
			if child is Node3D:
				spawn_points.append(child)
	
	if spawn_points.is_empty():
		push_warning("No spawn points found in scene")
	
	print("Spawn Director initialized with %d spawn points" % spawn_points.size())
	await get_tree().create_timer(3.0).timeout

func _process(delta):
	# Grow budgets
	spender_budget += budget_growth * delta
	saver_budget += budget_growth * delta
	
	# Check for spawns once per second
	spawn_check_timer += delta
	if spawn_check_timer >= SPAWN_CHECK_INTERVAL:
		spawn_check_timer -= SPAWN_CHECK_INTERVAL
		try_spawn_event()


func try_spawn_event():
	if saver_spend_likelihood():
		saver_spawn_event()
	elif spender_spend_likelihood():
		spender_spawn_event()

func saver_spawn_event():
	# Calculate how many of each enemy type we can afford
	var affordable_enemies = {}
	
	for enemy_type in ENEMY_DATA.keys():
		var cost = ENEMY_DATA[enemy_type]["cost"]
		var max_count = int(saver_budget / cost)
		if max_count >= 1:
			affordable_enemies[enemy_type] = max_count
	
	# If we can't afford anything, do nothing
	if affordable_enemies.is_empty():
		return
	
	# Pick one enemy type based on weights (only from affordable ones)
	var selected_type = weighted_random_from_dict(affordable_enemies)
	if selected_type == null:
		return
	
	# Calculate spawn details
	var count = affordable_enemies[selected_type]
	var cost = ENEMY_DATA[selected_type]["cost"]
	var total_cost = count * cost
	var budget_before = saver_budget
	
	# Spawn enemies
	spawn_enemies("SAVER", selected_type, count, total_cost, budget_before)
	
	# Deduct from budget
	saver_budget -= total_cost

func spender_spawn_event():
	# Calculate how many of each enemy type we can afford
	var affordable_enemies = {}
	
	for enemy_type in ENEMY_DATA.keys():
		var cost = ENEMY_DATA[enemy_type]["cost"]
		var max_count = int(spender_budget / cost)
		if max_count >= 1:
			affordable_enemies[enemy_type] = max_count
	
	# If we can't afford anything, do nothing
	if affordable_enemies.is_empty():
		return
	
	# Pick one enemy type based on weights (only from affordable ones)
	var selected_type = weighted_random_from_dict(affordable_enemies)
	if selected_type == null:
		return
	
	# Calculate spawn details
	var count = affordable_enemies[selected_type]
	var cost = ENEMY_DATA[selected_type]["cost"]
	var total_cost = count * cost
	var budget_before = spender_budget
	
	# Spawn enemies
	spawn_enemies("SPENDER", selected_type, count, total_cost, budget_before)
	
	# Deduct from budget
	spender_budget -= total_cost

func spender_spend_likelihood() -> bool:
	# Exponential probability function
	# 50% chance after 8 seconds (budget = 16)
	# Formula: P = 1 - e^(-λ * budget), where λ = ln(2)/16 ≈ 0.0433
	var lambda = 0.0433
	var probability = 1.0 - exp(-lambda * spender_budget)
	return randf() < probability

func saver_spend_likelihood() -> bool:
	# Exponential probability function
	# 50% chance after 30 calls (30 seconds, budget = 60)
	# Formula: P = 1 - e^(-λ * budget), where λ = ln(2)/60 ≈ 0.01155
	# This gives exactly 50% at budget 60
	var lambda = 0.01155
	var probability = 1.0 - exp(-lambda * saver_budget)
	return randf() < probability


func weighted_random_from_dict(affordable_enemies: Dictionary) -> String:
	# Pick an enemy type based on weights, only from affordable ones
	var total_weight = 0
	for enemy_type in affordable_enemies.keys():
		total_weight += ENEMY_DATA[enemy_type]["weight"]
	
	var random_value = randf() * total_weight
	var cumulative_weight = 0
	for enemy_type in affordable_enemies.keys():
		cumulative_weight += ENEMY_DATA[enemy_type]["weight"]
		if random_value <= cumulative_weight:
			return enemy_type
	
	# Fallback - return first affordable type
	return affordable_enemies.keys()[0] if not affordable_enemies.is_empty() else null

func spawn_enemies(director: String, enemy_type: String, count: int, total_cost: float, budget_before: float):
	# Get a spawn point
	var spawn_point = get_random_spawn_point()
	if spawn_point == null:
		print("[%s] No spawn points available!" % director)
		return
	
	var spawn_position = spawn_point.global_position
	var remaining_budget = budget_before - total_cost
	
	# Detailed logging
	# print("═══════════════════════════════════════════════════════")
	# print("[%s] SPAWN EVENT" % director)
	# print("  Enemy Type: %s" % enemy_type)
	# print("  Count: %d" % count)
	# print("  Cost per Enemy: %d" % ENEMY_DATA[enemy_type]["cost"])
	# print("  Total Cost: %.1f" % total_cost)
	# print("  Budget Before: %.1f" % budget_before)
	# print("  Remaining Budget: %.1f" % remaining_budget)
	# print("  Spawn Point: %s" % spawn_point.name)
	# print("═══════════════════════════════════════════════════════")
	
	# Spawn enemies in a circle around the spawn point
	const SPAWN_RADIUS = 12.0
	for i in range(count):
		# Random position within SPAWN_RADIUS
		var angle = randf() * TAU
		var distance = randf() * SPAWN_RADIUS
		var offset = Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)
		
		# Create enemy instance
		var enemy_scene = enemy_scenes.get(enemy_type)
		if enemy_scene:
			var enemy = enemy_scene.instantiate()
			enemy.global_position = spawn_position + offset
			get_tree().root.add_child(enemy)


func get_random_spawn_point() -> Node:
	if spawn_points.is_empty():
		return null
	
	if spawn_points.size() == 1:
		return spawn_points[0]
	
	var available_points = spawn_points.duplicate()
	if last_spawn_point != null and last_spawn_point in available_points:
		available_points.erase(last_spawn_point)
	
	var selected = available_points[randi() % available_points.size()]
	last_spawn_point = selected
	return selected
