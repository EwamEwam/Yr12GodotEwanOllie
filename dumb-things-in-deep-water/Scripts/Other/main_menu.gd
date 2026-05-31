extends Node2D

var enabled :bool = true

func _on_start_pressed() -> void:
	if enabled:
		SceneLoader.load_scene("res://Scenes/Level/level_select.tscn")

func _on_quit_pressed() -> void:
	if enabled:
		get_tree().quit()
