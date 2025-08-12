extends Control



func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0,value)


func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_volume_db(0,toggled_on)


func _on_resolution_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600,900))
		2:
			DisplayServer.window_set_size(Vector2i(1280,720))



func _on_button_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and get_tree().current_scene.scene_file_path == "res://Scenes/Misc/Settings.tscn":
		get_tree().change_scene_to_file("res://Scenes/Misc/World.tscn")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		
