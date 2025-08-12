extends Node2D


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level/World.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Misc/Settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
