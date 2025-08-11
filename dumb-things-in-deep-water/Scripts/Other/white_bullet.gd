extends Sprite2D

var turn_speed :float = 0
var velocity :Vector2 = Vector2.ZERO

func _ready() -> void:
	turn_speed = randf_range(0.2,0.5) * (-1**randi_range(1,2))
	velocity.x = randf_range(-0.25,-0.75)
	velocity.y = randf_range(-2.5,-3)
	
func _physics_process(delta: float) -> void:
	position += velocity
	velocity.y += 9.8 * delta
	rotation += turn_speed
	modulate.a -= delta
	if modulate.a < 0:
		queue_free()
