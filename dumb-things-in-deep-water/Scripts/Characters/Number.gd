extends Label3D

var starting_position :Vector3
var number_type :String

func _ready() -> void:
	global_position = starting_position
	global_position = Vector3(global_position.x + randf_range(-0.2,0.2),global_position.y + randf_range(0.5,0.75),global_position.z + randf_range(-0.2,0.2))
	var tween :Tween = get_tree().create_tween()
	tween.tween_property(self,"global_position",Vector3(global_position.x + (randf_range(-1,1)),global_position.y + 2, global_position.z + (randf_range(-1,1))),1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"modulate",Color(1,1,1,0),0.5).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	queue_free()

func create(type :String, amt :String, creation_position :Vector3) -> void:
	match type:
		"Player_Damage":
			font = load("res://Assets/Sprites/Red_Numbers.png")
			text = str(amt)
		"Enemy_Damage":
			font = load("res://Assets/Sprites/Orange_Numbers.png")
			text = str(amt)
		"Heal":
			font = load("res://Assets/Sprites/Green_Numbers.png")
			text = str(amt)
	number_type = type
	starting_position = creation_position
