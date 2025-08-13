extends Node

@onready var player :Object = $SubViewportContainer/SubViewport/Player
@onready var shader :ShaderMaterial = $SubViewportContainer/SubViewport/ColorRect.material

var time_in_level :float = 0.0

func _physics_process(delta: float) -> void:
	get_tree().call_group("Enemy", "update_target_location", player.global_position)
	check_below_map()
	time_in_level += delta
	shader.set_shader_parameter("time",time_in_level)
	if Playerstats.allow_water_effects:
		shader.set_shader_parameter("wave_amplitude",0.003)
	else:
		shader.set_shader_parameter("wave_amplitude",0)
	
func check_below_map() -> void:
	var detected :Array[Node3D] = $SubViewportContainer/SubViewport/NavigationRegion3D/Environment/Death_Barrier.get_overlapping_bodies()
	for object in detected:
		if object.is_in_group("Player"):
			object.position = Vector3(0,100,0)
		if object.is_in_group("Prop"):
			object.position = Vector3.ZERO
			object.linear_velocity = Vector3.ZERO
			object.get_parent().true_velocity = Vector3.ZERO

func _on_timer_timeout() -> void:
	$HUD.format_time()
