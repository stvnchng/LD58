extends PanelContainer

@onready var text_label: Label = $MarginContainer/Text

func _ready():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7) # dark translucent
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2

	style.border_color = Color(1, 1, 1)
	add_theme_stylebox_override("panel", style)

	text_label.clip_text = false

func show_tooltip(description: String):
	text_label.text = description
	text_label.size = text_label.get_minimum_size()
	size = text_label.size + Vector2(8, 8)
	visible = true

func hide_tooltip():
	visible = false

func _process(_delta):
	if visible:
		global_position = get_viewport().get_mouse_position() + Vector2(16, -16)
