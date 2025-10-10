extends Node2D

func _ready() -> void:
	Playerstats.clear_stat()

func _on__pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level/Tutorial.tscn")

func _on_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level/Tutorial.tscn")
