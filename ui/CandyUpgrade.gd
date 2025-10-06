extends Panel
class_name CandyUpgrade

@onready var model_holder: Node3D = $Container/SubViewport/PreviewNode/ModelHolder
@onready var count_lbl: Label = $Label

var description: String
var tooltip_panel: Control

func _ready():
	tooltip_panel = get_tree().get_first_node_in_group("tooltip")
	if not tooltip_panel:
		push_error('hey')
	$Container/SubViewport.world_3d = World3D.new()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if description:
		tooltip_panel.show_tooltip(description)

func _on_mouse_exited():
	tooltip_panel.hide_tooltip()

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

	description = GameState.candy_name_to_desc[candy_name]

func update_count(candy_name: String):
	count_lbl.text = "x" + str(GameState.get_candy_count(candy_name))
