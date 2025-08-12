extends NinePatchRect

@onready var label :Label = $Label
var tool_text :String

func _ready() -> void:
	label.text = tool_text
	@warning_ignore("narrowing_conversion")
	size = Vector2i((label.size.x/2)+9, 7 + (label.size.y/2) + floor(label.size.y/39))
	var mouse_postion :Vector2 = get_global_mouse_position()
	@warning_ignore("narrowing_conversion")
	position = Vector2i(clamp(mouse_postion.x + 5,0,640 - 2 * size.x),clamp(mouse_postion.y,0,480 - 2 * size.y))
	visible = true

func create_text(text :String) -> void:
	visible = false
	tool_text = text

func _process(_delta: float) -> void:
	label.text = tool_text
	@warning_ignore("narrowing_conversion")
	size = Vector2i((label.size.x/2)+9, 7 + (label.size.y/2) + floor(label.size.y/39))
	var mouse_postion :Vector2 = get_global_mouse_position()
	@warning_ignore("narrowing_conversion")
	position = Vector2i(clampf(mouse_postion.x + 5,0,640 - 2 * size.x),clampf(mouse_postion.y,0,480 - 2 * size.y))
	visible = true
