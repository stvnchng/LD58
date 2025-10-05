extends CanvasLayer

@onready var timer_lbl: Label = $MarginContainer/VBoxContainer/Timer
@onready var upgrades_container: HBoxContainer = $Bottom/Upgrades

var candy_upgrade_scn := preload("res://ui/CandyUpgrade.tscn")
var timer_accumulator: float = 0.0

var candy_name_to_upgrade : Dictionary[String, CandyUpgrade] = {}

func _ready():
	#GameState.enemy_died.connect(update_kill_count_label)
	GameState.item_collected.connect(update_inventory)
	for child in upgrades_container.get_children():
		child.queue_free()

func _process(delta: float) -> void:
	timer_accumulator += delta
	if timer_accumulator >= 1.0:
		timer_accumulator = 0.0
		var time_arr = GameState.get_minutes_seconds()
		timer_lbl.text = "%02d:%02d" % [time_arr[0], time_arr[1]]

func update_inventory(candy_name: String):
	if candy_name not in candy_name_to_upgrade:
		var candy_upgrade: CandyUpgrade = candy_upgrade_scn.instantiate()
		upgrades_container.add_child(candy_upgrade)
		candy_upgrade.set_model(candy_name)
		candy_name_to_upgrade[candy_name] = candy_upgrade
	else:
		var existing_upgrade: CandyUpgrade = candy_name_to_upgrade[candy_name]
		existing_upgrade.update_count(candy_name)
