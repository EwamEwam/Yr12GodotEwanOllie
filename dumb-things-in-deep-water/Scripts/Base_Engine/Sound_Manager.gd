extends Node

var captions :Dictionary[String, float] = {}

func create_sound(Audio :StringName, Volume :float, Pitch :float, Unit_size :float, Position: Vector3, Caption :String = "", Caption_lifetime :float = 2.0) -> void:
	var Audio_node :AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	Audio_node.stream = load(Audio)
	Audio_node.unit_size = Unit_size
	Audio_node.volume_db = Volume
	Audio_node.pitch_scale = Pitch
	get_node("/root/World/SubViewportContainer/SubViewport").add_child(Audio_node)
	Audio_node.global_position = Position
	Audio_node.play()
	add_caption(Caption, Caption_lifetime)
	await Audio_node.finished
	Audio_node.call_deferred("queue_free")
	#print("Audio node at " + str(Position) + " was successfully deleted")
	
func create_nonlocal_sound(Audio :StringName, Volume :float, Pitch :float, Caption :String = "", Caption_lifetime :float = 2.0) -> void:
	var Audio_node :AudioStreamPlayer = AudioStreamPlayer.new()
	Audio_node.stream = load(Audio)
	Audio_node.volume_db = Volume
	Audio_node.pitch_scale = Pitch
	get_node("/root").add_child(Audio_node)
	add_caption(Caption, Caption_lifetime)
	await Audio_node.finished
	Audio_node.call_deferred("queue_free")
	
func add_caption(caption :String, caption_lifetime :float = 4.0) -> void:
	if caption != "":
		captions[caption] = caption_lifetime
		
func _process(delta: float) -> void:
	if captions.size() > 0:
		for caption :String in captions.keys():
			if captions[caption] <= 0:
				captions.erase(caption)
			else:
				captions[caption] -= delta
