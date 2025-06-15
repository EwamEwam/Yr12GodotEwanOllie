extends Node2D

@onready var reticle :Sprite2D = $Reticule
@onready var throw_bar :ProgressBar = $Throw_Bar
@onready var player :CharacterBody3D = get_node('/root/Main/SubViewportContainer/SubViewport/Player')

func _process(_delta: float) -> void:
	reticle.modulate.a = 0.2
	if player.movement_state != player.movement_states.NORMAL:
		reticle.modulate.a = 1
