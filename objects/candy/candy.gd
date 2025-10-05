extends Node3D
class_name Candy

# Bob and rotation parameters
@export var bob_height: float = 0.3
@export var bob_speed: float = 2.0
@export var rotation_speed: float = 1.0

var time_elapsed: float = 0.0
var initial_y: float = 0.0

@onready var mesh_node = $Mesh
@onready var area = $Area3D

func _ready():
	initial_y = mesh_node.position.y
	area.body_entered.connect(_on_body_entered)

func _process(delta):
	time_elapsed += delta
	
	# Bob up and down
	mesh_node.position.y = initial_y + sin(time_elapsed * bob_speed) * bob_height
	
	# Rotate around Y axis
	mesh_node.rotation.y += rotation_speed * delta

func _on_body_entered(body):
	# Check if it's the player
	if body is Player:
		# Emit global signal using this node's name as the item key
		Globals.item_collected.emit(self.name)
		# Remove this item from the scene
		queue_free()
