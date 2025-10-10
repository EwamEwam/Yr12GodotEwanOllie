extends Node3D

func _physics_process(_delta: float) -> void:
	look_at(Playerstats.player.camera.global_position,Vector3.UP)
	
func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if Playerstats.inventory.has(20) or Playerstats.object_ID == 20:
			Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_VISIBLE)
			get_tree().change_scene_to_file("res://Scenes/Level/level_select.tscn")
			Playerstats.current_state = Playerstats.game_states.PAUSED
		else:
			$"../../../../HUD".alert("You don't have the package!")
