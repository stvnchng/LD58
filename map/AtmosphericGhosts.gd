extends Node3D

# Light references
@onready var purple_light: OmniLight3D = $PurpleLight
@onready var yellow_light: OmniLight3D = $YellowLight
@onready var blue_light: OmniLight3D = $BlueLight

# Purple Light Settings (Clockwise)
@export var purple_speed: float = 1.0
@export var purple_radius: float = 8.0
@export var purple_amplitude: float = 3.0
@export var purple_wavelength: float = 2.0

# Yellow Light Settings (Clockwise)
@export var yellow_speed: float = 1.5
@export var yellow_radius: float = 12.0
@export var yellow_amplitude: float = 2.5
@export var yellow_wavelength: float = 1.5

# Blue Light Settings (Counter-clockwise)
@export var blue_speed: float = 0.8
@export var blue_radius: float = 6.0
@export var blue_amplitude: float = 4.0
@export var blue_wavelength: float = 3.0

# Time tracking
var time: float = 0.0

func _ready():
	# Initialize light positions
	update_light_positions()

func _process(delta):
	time += delta
	update_light_positions()

func update_light_positions():
	# Purple Light - Clockwise
	var purple_angle = time * purple_speed
	purple_light.position.x = cos(purple_angle) * purple_radius
	purple_light.position.z = sin(purple_angle) * purple_radius
	purple_light.position.y = sin(time * purple_wavelength) * purple_amplitude
	
	# Yellow Light - Clockwise
	var yellow_angle = time * yellow_speed
	yellow_light.position.x = cos(yellow_angle) * yellow_radius
	yellow_light.position.z = sin(yellow_angle) * yellow_radius
	yellow_light.position.y = sin(time * yellow_wavelength) * yellow_amplitude
	
	# Blue Light - Counter-clockwise
	var blue_angle = -time * blue_speed  # Negative for counter-clockwise
	blue_light.position.x = cos(blue_angle) * blue_radius
	blue_light.position.z = sin(blue_angle) * blue_radius
	blue_light.position.y = sin(time * blue_wavelength) * blue_amplitude
