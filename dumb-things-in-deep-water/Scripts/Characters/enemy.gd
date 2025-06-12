extends CharacterBody3D

@onready var nav_agent :NavigationAgent3D = $NavigationAgent3D

@export var SPEED :float = 4.0
@export var ACCEL :float = 1.0

@export var DETECTION_DISTANCE :float = 50.0

func _physics_process(delta :float) -> void:
	if not is_on_floor():
		velocity.y -= 0.9
	else:
		velocity.y = 0
			
	if (global_position - Playerstats.player.global_position).length() < DETECTION_DISTANCE:
		var direction = Vector3()
		
		var current_location :Vector3 = global_transform.origin
		direction = (nav_agent.get_next_path_position() - current_location).normalized()	
	
		velocity = velocity.lerp(direction * SPEED, ACCEL * delta)
	else:
		velocity = velocity.lerp(Vector3.ZERO, ACCEL*delta)

	move_and_slide()
func update_target_location(target_location :Vector3) -> void:
	nav_agent.target_position = target_location
