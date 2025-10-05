extends Panel
class_name EnemyCount

@export var enemy_name : String

@onready var model_holder: Node3D = $Container/SubViewport/PreviewNode/ModelHolder
@onready var count_lbl: Label = $Label

func _ready():
	$Container/SubViewport.world_3d = World3D.new()
	set_model()

func set_model():
	var scene = Globals.enemy_name_to_scn[enemy_name]
	var enemy: CharacterBody3D = scene.instantiate()
	model_holder.add_child(enemy)
	enemy.transform = Transform3D.IDENTITY
	enemy.set_physics_process(false)
	if enemy.has_node("HpBar"):
		enemy.get_node("HpBar").visible = false
	update_count(enemy_name)

func update_count(enemy: String):
	count_lbl.text = "x" + str(GameState.get_kills(enemy))
