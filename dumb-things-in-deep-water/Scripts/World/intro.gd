extends Node

var time :float = 0
@onready var shader :ShaderMaterial = $SubViewportContainer/SubViewport/ColorRect.material

func _ready() -> void:
	$"Main menu".visible = false
	Playerstats.player = $SubViewportContainer/SubViewport/Camera
	await get_tree().create_timer(6).timeout
	var tween :Tween = get_tree().create_tween()
	$SubViewportContainer/SubViewport/Camera.global_position = Vector3(0.86,-1.638,-8.315)
	tween.tween_property($SubViewportContainer/SubViewport/Camera,"global_position",Vector3(0.719,-1.638,-6.016),6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	$"Main menu".visible = true
	var tween2 :Tween = get_tree().create_tween()
	tween2.tween_property($"Main menu","modulate",Color(1,1,1,1),1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	$"Main menu".enabled = true
	
func _process(delta: float) -> void:
	time += delta
	shader.set_shader_parameter("time",time)
