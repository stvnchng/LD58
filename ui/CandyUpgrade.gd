extends Panel
class_name CandyUpgrade

@onready var model_holder: Node3D = $Container/SubViewport/PreviewNode/ModelHolder
@onready var count_lbl: Label = $Label

func _ready():	
	$Container/SubViewport.world_3d = World3D.new()

func set_model(candy_name: String):
	for child in model_holder.get_children():
		child.queue_free()

	var scene = GameState.candy_name_to_scn[candy_name]
	var candy: Candy = scene.instantiate()
	model_holder.add_child(candy)
	candy.bob_height = 0
	candy.bob_speed = 0
	candy.transform = Transform3D.IDENTITY
	candy.scale = Vector3.ONE * 0.6
	update_count(candy_name)

func update_count(candy_name: String):
	count_lbl.text = "x" + str(GameState.get_candy_count(candy_name))
