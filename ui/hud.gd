extends CanvasLayer

@export var audio_manager: Node

@onready var timer_lbl: Label = $MarginContainer/VBoxContainer/Timer
var MAX_PER_ROW := 7
@onready var upgrade_rows: VBoxContainer = $BottomLeft/UpgradeRows
@onready var dash_status: Panel = $BottomCenter/Cooldowns/DashStatus

@onready var mute_btn: Button = $TopRight/MuteButton

var candy_upgrade_scn := preload("res://ui/CandyUpgrade.tscn")
var timer_accumulator: float = 0.0

var candy_name_to_upgrade : Dictionary[String, CandyUpgrade] = {}
var enemy_name_to_counter : Dictionary[String, EnemyCount] = {}

func _ready():
	visible = true
	GameState.enemy_died.connect(update_kill_count_label)
	GameState.item_collected.connect(update_inventory)
	for child in upgrade_rows.get_children():
		child.queue_free()
	enemy_name_to_counter["basic"] = $BottomRight/KillCount/EnemyKillCounter
	enemy_name_to_counter["lurcher"] = $BottomRight/KillCount/EnemyKillCounter2
	enemy_name_to_counter["floater"] = $BottomRight/KillCount/EnemyKillCounter3
	mute_btn.pressed.connect(_on_mute_pressed)
	_update_mute_icon()

func _on_mute_pressed():
	audio_manager.toggle_mute()
	_update_mute_icon()

func _update_mute_icon():
	var sprite: Sprite2D = mute_btn.get_node("Sprite2D")
	if audio_manager.muted:
		sprite.frame = 1
	else:
		sprite.frame = 0

func _process(delta: float) -> void:
	if GameState.game_over:
		visible = false
		return
	timer_accumulator += delta
	if timer_accumulator >= 1.0:
		timer_accumulator = 0.0
		var time_arr = GameState.get_minutes_seconds()
		timer_lbl.text = "%02d:%02d" % [time_arr[0], time_arr[1]]

func update_inventory(candy_name: String):
	if candy_name not in candy_name_to_upgrade:
		var candy_upgrade: CandyUpgrade = candy_upgrade_scn.instantiate()
		add_upgrade_node(candy_upgrade)
		candy_upgrade.set_model(candy_name)
		candy_name_to_upgrade[candy_name] = candy_upgrade
	else:
		var existing_upgrade: CandyUpgrade = candy_name_to_upgrade[candy_name]
		existing_upgrade.update_count(candy_name)

func update_kill_count_label(enemy: String, _position: Vector3):
	var enemy_counter: EnemyCount = enemy_name_to_counter[enemy]
	enemy_counter.update_count(enemy)

func add_upgrade_node(upgrade_node: CandyUpgrade) -> void:
	var current_row: HBoxContainer
	if upgrade_rows.get_child_count() == 0:
		current_row = HBoxContainer.new()
		current_row.theme = upgrade_rows.theme
		current_row.add_theme_constant_override("separation", 12)
		upgrade_rows.add_child(current_row)
	else:
		current_row = upgrade_rows.get_child(upgrade_rows.get_child_count() - 1)

	if current_row.get_child_count() >= MAX_PER_ROW:
		current_row = HBoxContainer.new()
		current_row.theme = upgrade_rows.theme
		current_row.add_theme_constant_override("separation", 12)
		upgrade_rows.add_child(current_row)

	current_row.add_child(upgrade_node)
