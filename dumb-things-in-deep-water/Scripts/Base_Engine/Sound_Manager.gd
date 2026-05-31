extends Node

func create_sound(Audio :StringName, Volume: float, Pitch: float, Unit_size :float, Position: Vector3) -> void:
	var Audio_node :AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	Audio_node.stream = load(Audio)
	Audio_node.unit_size = Unit_size
	Audio_node.volume_db = Volume
	Audio_node.pitch_scale = Pitch
	get_node("/root/World/SubViewportContainer/SubViewport").add_child(Audio_node)
	Audio_node.global_position = Position
	Audio_node.play()
	await Audio_node.finished
	Audio_node.call_deferred("queue_free")
	#print("Audio node at " + str(Position) + " was successfully deleted")
