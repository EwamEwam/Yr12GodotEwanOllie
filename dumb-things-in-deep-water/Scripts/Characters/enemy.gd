extends CharacterBody3D

@onready var nav_agent :NavigationAgent3D = $NavigationAgent3D

var SPEED :float = 3.0
var ACCEL :float = 10.0

func _physics_process(delta :float) -> void:
	
	var direction = Vector3()
	
	var current_location :Vector3 = global_transform.origin
	direction = (nav_agent.get_next_path_position() - current_location).normalized()

	velocity = velocity.lerp(direction * SPEED, ACCEL * delta)
	if not is_on_floor():
		velocity.y -= 0.9
	else:
		velocity.y = 0
	move_and_slide()

func update_target_location(target_location :Vector3) -> void:
	nav_agent.target_position = target_location
