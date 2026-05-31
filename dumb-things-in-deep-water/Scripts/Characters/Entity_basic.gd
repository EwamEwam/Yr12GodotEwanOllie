extends entity

func _on_entity_dead() -> void:
	queue_free()
