extends Node

# Enemy death signal - emitted when any enemy dies
# enemy_type: String - "basic", "lurcher", or "floater"
# death_position: Vector3 - global position where enemy died
signal enemy_died(enemy_type: String, death_position: Vector3)

# Item collected signal - emitted when player collects an item
# item_key: String - identifier for the item type (e.g., "APPLE")
signal item_collected(item_key: String)

const BASIC_ENEMY := preload("res://entities/enemies/EnemyBasic.tscn")
const LURCH_ENEMY := preload("res://entities/enemies/EnemyLurcher.tscn")
const FLOAT_ENEMY := preload("res://entities/enemies/enemy_floater.tscn")
