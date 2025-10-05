extends Node



# Shoot sound signal - emitted when any entity shoots
# entity_type: String - "player", "floater", or "basic"
signal shoot_sound(entity_type: String)

# Player hurt signal - emitted when player takes damage
signal player_hurt

# Player dash signal - emitted when player dashes
signal player_dash

const BASIC_ENEMY := preload("res://entities/enemies/EnemyBasic.tscn")
const LURCH_ENEMY := preload("res://entities/enemies/EnemyLurcher.tscn")
const FLOAT_ENEMY := preload("res://entities/enemies/enemy_floater.tscn")
