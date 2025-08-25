extends Node3D

@export var sign_text :String = ""

func _ready() -> void:
	$Text.text = sign_text
