extends NavigationRegion3D

@onready var player = $"../Player"

func _process(_delta: float) -> void:
	get_tree().call_group("enemies","update_target_location",player.global_position)
	
func _on_timer_timeout() -> void:
	bake_navigation_mesh()
