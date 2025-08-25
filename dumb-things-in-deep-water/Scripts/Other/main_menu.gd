extends Node2D

var enabled :bool = false

func _on_start_pressed() -> void:
	if enabled:
		get_tree().change_scene_to_file("res://Scenes/Level/Tutorial.tscn")

func _on_quit_pressed() -> void:
	if enabled:
		get_tree().quit()
