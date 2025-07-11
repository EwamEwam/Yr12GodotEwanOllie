extends Node

func _physics_process(_delta: float) -> void:
#	get_tree().call_group("enemies", "update_target_location", player.global_transformation.origin)
	check_below_map()
	
func check_below_map() -> void:
	var detected :Array[Node3D] = $SubViewportContainer/SubViewport/Environment/Death_Barrier.get_overlapping_bodies()
	for object in detected:
		if object.is_in_group("Player"):
			object.global_position = Vector3(0,100,0)
		if object.is_in_group("Prop"):
			object.get_parent().global_position = Vector3(0,100,0)
			object.position = Vector3.ZERO

func _on_timer_timeout() -> void:
	$HUD.format_time()
