extends Node2D

func _ready() -> void:
	Playerstats.clear_stat()

func _on__pressed() -> void:
	SceneLoader.load_scene("res://Scenes/Level/Test_map_2.tscn")

func _on_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level/Level_1.tscn")
