extends NavigationRegion3D

@onready var player = get_node('/root/Test/SubViewportContainer/SubViewport/Player')

func _physics_process(delta):
	get_tree().call_group("enemies", "update_target_location", player.global_transform.origin)


func _on_timer_timeout() -> void:
	bake_navigation_mesh()
