extends Node

# Shoot sound signal - emitted when any entity shoots
# entity_type: String - "player", "floater", or "basic"
signal shoot_sound(entity_type: String)

# Player hurt signal - emitted when player takes damage
signal player_hurt

# Player dash signal - emitted when player dashes
signal player_dash

var burning_duration: float = 4.0
var burning_damage: float = 0.08
var burning_interval: float = 1.0

var bleeding_duration: float = 8.0
var bleeding_damage: float = 0.05
var bleeding_interval: float = 1.0

const BASIC_ENEMY := preload("res://entities/enemies/EnemyBasic.tscn")
const LURCH_ENEMY := preload("res://entities/enemies/EnemyLurcher.tscn")
const FLOAT_ENEMY := preload("res://entities/enemies/enemy_floater.tscn")

const enemy_name_to_scn = {
	"basic": BASIC_ENEMY,
	"lurcher": LURCH_ENEMY,
	"floater": FLOAT_ENEMY
}
