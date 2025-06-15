extends CharacterBody3D

@onready var nav_agent :NavigationAgent3D = $NavigationAgent3D

@export var SPEED :float = 40
@export var ACCEL :float = 1.0

@export var DETECTION_DISTANCE :float = 50.0
@export var MIN_DETECTION_DIST :float = 2.0

func _physics_process(delta :float) -> void:
	if not is_on_floor():
		velocity.y -= 0.9
	else:
		velocity.y = 0
			
	var distance :float = (global_position - Playerstats.player.global_position).length()
	if distance < DETECTION_DISTANCE and distance > MIN_DETECTION_DIST:
		
		var direction = Vector3()
		direction = (nav_agent.get_next_path_position() - global_position).normalized()
		velocity = velocity.lerp(direction * SPEED, ACCEL * delta)
	
	elif distance < MIN_DETECTION_DIST:
		
		var direction = Vector3()
		direction = (nav_agent.get_next_path_position() - global_position).normalized()
		velocity = velocity.lerp(Vector3.ZERO, delta*10)
		
	else:
		velocity = velocity.lerp(Vector3.ZERO, ACCEL*delta)

	move_and_slide()
	
func update_target_location(target_location :Vector3) -> void:
	nav_agent.target_position = target_location

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		await get_tree().create_timer(1).timeout
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		OS.alert("On Grand Bibby, you are dead.")
		get_tree().quit()
