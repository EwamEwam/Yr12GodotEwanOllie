extends Node

@onready var player :Object = $SubViewportContainer/SubViewport/Player

func _physics_process(_delta: float) -> void:
	get_tree().call_group("enemies", "update_target_location", player.global_position)
	check_below_map()
	
func check_below_map() -> void:
	var detected :Array[Node3D] = $SubViewportContainer/SubViewport/NavigationRegion3D/Environment/Death_Barrier.get_overlapping_bodies()
	for object in detected:
		if object.is_in_group("Player"):
			object.position = Vector3(0,100,0)
		if object.is_in_group("Prop"):
			object.position = Vector3.ZERO
			object.linear_velocity = Vector3.ZERO

func _on_timer_timeout() -> void:
	$HUD.format_time()
	#$SubViewportContainer/SubViewport/NavigationRegion3D.bake_navigation_mesh()
