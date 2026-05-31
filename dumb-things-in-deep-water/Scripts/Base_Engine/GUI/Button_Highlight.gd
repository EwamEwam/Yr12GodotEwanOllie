extends Button

func _on_mouse_entered() -> void:
	modulate = Color(0.65,0.65,0.65,1)

func _on_mouse_exited() -> void:
	modulate = Color(1,1,1,1)
	
func _process(_delta: float) -> void:
	if disabled:
		modulate = Color(0.5,0.5,0.5,1)
