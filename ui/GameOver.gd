extends CanvasLayer
class_name GameOver

@onready var overlay: ColorRect = $Overlay
@onready var enemies_slain_lbl: Label = $Overlay/MarginContainer/VBoxContainer/EnemiesSlain
@onready var upgrade_rows: VBoxContainer = $Overlay/MarginContainer/VBoxContainer/UpgradeRows
@onready var restart_button: Button = $Overlay/MarginContainer/VBoxContainer/Button

var candy_upgrade_scn := preload("res://ui/CandyUpgrade.tscn")
const MAX_PER_ROW := 7

func _ready():
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)

func show_game_over():
	visible = true
	layer = 100
	_populate_labels()
	_populate_upgrades()

func hide_game_over():
	visible = false
	layer = -100
	_clear_upgrades()

func _populate_labels():
	enemies_slain_lbl.text = "Enemies Defeated: %d" % GameState.get_total_kills()

func _populate_upgrades():
	_clear_upgrades()
	var current_row: HBoxContainer = null
	
	for candy_name in GameState.candy_inventory.keys():
		if current_row == null or current_row.get_child_count() >= MAX_PER_ROW:
			current_row = HBoxContainer.new()
			current_row.theme = upgrade_rows.theme
			current_row.add_theme_constant_override("separation", 12)
			upgrade_rows.add_child(current_row)

		var candy_upgrade: CandyUpgrade = candy_upgrade_scn.instantiate()
		current_row.add_child(candy_upgrade)
		candy_upgrade.set_model(candy_name)
		candy_upgrade.update_count(candy_name)

func _clear_upgrades():
	for row in upgrade_rows.get_children():
		row.queue_free()

func _on_restart_pressed():
	GameState.restart_game()
	hide_game_over()
