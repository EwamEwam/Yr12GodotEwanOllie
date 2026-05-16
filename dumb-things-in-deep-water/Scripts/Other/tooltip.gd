extends NinePatchRect

@onready var timer :Timer = $Timer
var tool_text :Array
var types = ItemData.text_type
var position_of_text :Vector2 = Vector2(4,4)

func set_text(data :Array) -> void:
	tool_text = data

func _ready() -> void:
	@warning_ignore("narrowing_conversion")
	decode()
	@warning_ignore("narrowing_conversion")
	size = Vector2i((position_of_text.x/2)+9, 7 + (position_of_text.y/2) + floor(position_of_text.y/39))
	var mouse_postion :Vector2 = get_global_mouse_position()
	@warning_ignore("narrowing_conversion")
	position = Vector2i(clamp(mouse_postion.x + 5,0,640 - 2 * size.x),clamp(mouse_postion.y,0,480 - 2 * size.y))
	visible = true

func _process(_delta: float) -> void:
	@warning_ignore("narrowing_conversion")
	size = Vector2i((position_of_text.x/2)+9, 7 + (position_of_text.y/2) + floor(position_of_text.y/39))
	var mouse_postion :Vector2 = get_global_mouse_position()
	@warning_ignore("narrowing_conversion")
	position = Vector2i(clampf(mouse_postion.x + 5,0,640 - 2 * size.x),clampf(mouse_postion.y,0,480 - 2 * size.y))
	visible = true

func decode() -> void:
	for item in tool_text:
		match item[0]:
			types.STANDARD:
				var new_label = Label.new()
				new_label.scale = Vector2(0.5,0.5)
				new_label.position = Vector2(4,4)
				new_label.modulate = item[1]
				new_label.text = item[2]
				add_child(new_label)
				position_of_text.x = max(new_label.size.x,position_of_text.x)
				position_of_text.y = max(new_label.size.y,position_of_text.y)
			types.TIMER:
				timer.start(item[1])
				await timer.timeout
			types.TYPE_OUT:
				var instant :int = 0
				if item.size() == 5:
					instant = item[4]
				var new_label = Label.new()
				new_label.scale = Vector2(0.5,0.5)
				new_label.position = Vector2(4,4)
				new_label.modulate = item[1]
				var text_buffer :String = ""
				add_child(new_label)
				for character in item[2]:
					text_buffer += character
					new_label.text = text_buffer
					position_of_text.x = max(new_label.size.x,position_of_text.x)
					position_of_text.y = max(new_label.size.y,position_of_text.y)
					if instant == 0:
						await get_tree().create_timer(item[3]).timeout
					else:
						instant -= 1
			types.RESET:
				for child in get_children():
					child.queue_free()
				position_of_text = Vector2(4,4)
