extends Node3D

@onready var parent :Node3D = get_parent()

var max_health :float
var health :float

func _ready() -> void:
	max_health = parent.max_health
	health = parent.health

func _physics_process(_delta: float) -> void:
	look_at(Playerstats.player.camera.global_position,Vector3.UP)
	health = parent.health
	if health == max_health:
		visible = false
	elif health > 0:
		$Bar.scale.x = health/max_health
		visible = true
	else:
		$Bar.visible = false
