extends Node

const ENEMY_DATA = {
	"lurcher": {"cost": 10, "weight": 45},
	"basic": {"cost": 12, "weight": 35},
	"floater": {"cost": 15, "weight": 20}
}

const budget_growth = 5.0
func get_budget_growth() -> float:
	return budget_growth * GameState.current_difficulty()

@export var min_spawn_distance: float = 20.0  # Minimum distance from player
@export var max_spawn_distance: float = 40.0  # Maximum distance from player
@export var spawn_validation_attempts: int = 10  # How many times to try finding valid position

var player: Player = null
var navigation_region: NavigationRegion3D = null

var spender_budget = 0.0
var saver_budget = 0.0

var spawn_check_timer = 0.0
const SPAWN_CHECK_INTERVAL = 1.0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("Spawn Director: Player not found!")
	
	navigation_region = _find_navigation_region(get_parent())
	if navigation_region:
		print("Spawn Director: Found navigation region for spawn validation")
	else:
		push_warning("Spawn Director: No navigation region found - spawn validation will be limited")
	
	print("Spawn Director initialized with dynamic spawning (%.1f - %.1f units from player)" % [min_spawn_distance, max_spawn_distance])
	await get_tree().create_timer(2.0).timeout

func _find_navigation_region(node: Node) -> NavigationRegion3D:
	# Recursively search for NavigationRegion3D
	if node is NavigationRegion3D:
		return node
	for child in node.get_children():
		var result = _find_navigation_region(child)
		if result:
			return result
	return null

func _process(delta):
	spender_budget += get_budget_growth() * delta
	saver_budget += get_budget_growth() * delta
	
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
	var affordable_enemies = {}
	
	for enemy_type in ENEMY_DATA.keys():
		var enemy_cost = ENEMY_DATA[enemy_type]["cost"]
		var max_count = int(saver_budget / enemy_cost)
		if max_count >= 1:
			affordable_enemies[enemy_type] = max_count
	
	if affordable_enemies.is_empty():
		return
	
	# Pick one enemy type based on weights (only from affordable ones)
	var selected_type = weighted_random_from_dict(affordable_enemies)
	if selected_type == null:
		return
	
	var count = affordable_enemies[selected_type]
	var cost = ENEMY_DATA[selected_type]["cost"]
	var total_cost = count * cost
	var budget_before = saver_budget
	
	spawn_enemies("SAVER", selected_type, count, total_cost, budget_before)
	
	# Deduct from budget
	saver_budget -= total_cost

func spender_spawn_event():
	# Calculate how many of each enemy type we can afford
	var affordable_enemies = {}
	
	for enemy_type in ENEMY_DATA.keys():
		var enemy_cost = ENEMY_DATA[enemy_type]["cost"]
		var max_count = int(spender_budget / enemy_cost)
		if max_count >= 1:
			affordable_enemies[enemy_type] = max_count
	
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
	
	spawn_enemies("SPENDER", selected_type, count, total_cost, budget_before)

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
	if not player:
		push_warning("[%s] Cannot spawn - player not found!" % director)
		return
	
	# Get a valid spawn position in the donut around player
	var spawn_center = get_valid_spawn_position()
	if spawn_center == null:
		push_warning("[%s] Could not find valid spawn position!" % director)
		return
	
	# Spawn enemies in a circle around the spawn center
	const HORDE_RADIUS = 6.0
	var spawned_count = 0
	
	for i in range(count):
		# Try to find a valid position within the horde circle
		var enemy_position = null
		
		for attempt in range(spawn_validation_attempts):
			# Random position within HORDE_RADIUS
			var angle = randf() * TAU
			var distance = randf() * HORDE_RADIUS
			var offset = Vector3(
				cos(angle) * distance,
				0,
				sin(angle) * distance
			)
			var test_position = spawn_center + offset
			
			# Validate this position
			if is_position_valid(test_position):
				enemy_position = test_position
				break
		
		# If we found a valid position, spawn the enemy
		if enemy_position:
			var enemy_scene = Globals.enemy_name_to_scn.get(enemy_type)
			if enemy_scene:
				var enemy = enemy_scene.instantiate()
				get_parent().add_child(enemy)
				enemy.global_position = enemy_position
				spawned_count += 1
	
	if spawned_count < count:
		push_warning("[%s] Only spawned %d/%d enemies due to validation failures" % [director, spawned_count, count])

func get_valid_spawn_position() -> Vector3:
	if not player:
		return Vector3.ZERO
	
	# Try multiple times to find a valid position in the donut
	for attempt in range(spawn_validation_attempts):
		# Generate random position in donut around player
		var angle = randf() * TAU
		var distance = randf_range(min_spawn_distance, max_spawn_distance)
		
		var offset = Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)
		
		var test_position = player.global_position + offset
		
		# Validate the position
		if is_position_valid(test_position):
			return test_position
	
	# If all attempts failed, return a position anyway (fallback)
	var fallback_angle = randf() * TAU
	var fallback_distance = (min_spawn_distance + max_spawn_distance) / 2.0
	return player.global_position + Vector3(
		cos(fallback_angle) * fallback_distance,
		0,
		sin(fallback_angle) * fallback_distance
	)

func is_position_valid(position: Vector3) -> bool:
	# Use NavigationServer to check if position is on navigation mesh
	if navigation_region and navigation_region.navigation_mesh:
		var map_rid = navigation_region.get_navigation_map()
		
		# Get the closest point on the navigation mesh
		var closest_point = NavigationServer3D.map_get_closest_point(map_rid, position)
		
		# Check if the position is close enough to the nav mesh (within 2 units)
		var distance_to_navmesh = position.distance_to(closest_point)
		if distance_to_navmesh > 2.0:
			return false
		
		return true
	
	# If no navigation mesh, just check basic bounds (fallback)
	return true
