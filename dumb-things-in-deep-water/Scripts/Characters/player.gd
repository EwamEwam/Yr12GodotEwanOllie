extends CharacterBody3D
#The main player's script, holds a lot of the game's and player's basic logic, kind of a mess though.
var speed :float = 7.5
var acceleration :float = 45.0
var gravity :float = 20.0
var jump_strength : float = 9.0

var calculated_velocity :Vector3 = Vector3.ZERO
var last_velocity_grounded :Vector3 = Vector3.ZERO

var camera_speed :float = 0.5
var yaw :float = 0.0
var pitch :float = 0.0
var last_direction_facing :Vector3 = Vector3.ZERO

@onready var camera_yaw :Node3D = $Camera_Pivot/Yaw
@onready var camera_pitch :Node3D = $Camera_Pivot/Yaw/Pitch
@onready var pivot :Node3D = $Camera_Pivot
@onready var camera_spring :SpringArm3D = $Camera_Pivot/Yaw/Pitch/Camera_Spring
@onready var camera :Camera3D = $Camera_Pivot/Yaw/Pitch/Camera_Spring/Camera3D

func _physics_process(delta: float) -> void:
	set_speed()
	var current_direction_held :Vector2
	
	if Playerstats.current_state == Playerstats.game_states.PLAYING and Playerstats.current_camera == Playerstats.camera_states.THIRD:
		var camera_offset :Basis = set_camera()
		current_direction_held = Input.get_vector("Left","Right","Up","Down").normalized()
		var direction :Vector3 = (camera_offset * Vector3(current_direction_held.x, 0, current_direction_held.y)).normalized()
		
		if is_on_floor():
			if not current_direction_held == Vector2.ZERO:
				last_direction_facing.x = move_toward(last_direction_facing.x,direction.x, 6 * delta)
				last_direction_facing.z = move_toward(last_direction_facing.z,direction.z, 6 * delta)
			calculated_velocity.x = move_toward(calculated_velocity.x, speed * direction.x, acceleration * delta)
			calculated_velocity.z = move_toward(calculated_velocity.z, speed * direction.z, acceleration * delta)
			last_velocity_grounded = Vector3(calculated_velocity.x, 0, calculated_velocity.z)
			calculated_velocity.y = 0
			if Input.is_action_just_pressed("Space"):
				calculated_velocity.y = jump_strength
		else:
			calculated_velocity.x = move_toward(calculated_velocity.x, (speed * direction.x)/3 + last_velocity_grounded.x/1.5, acceleration/2 * delta)
			calculated_velocity.z = move_toward(calculated_velocity.z, (speed * direction.z)/3 + last_velocity_grounded.z/1.5, acceleration/2 * delta)
		
	if not is_on_floor():
		calculated_velocity.y -= gravity * delta
		
	velocity = calculated_velocity
	move_and_slide()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Playerstats.current_state == Playerstats.game_states.PLAYING:
		yaw += -event.relative.x * Playerstats.sensitivity * Playerstats.screen_factor
		pitch += -event.relative.y * Playerstats.sensitivity * Playerstats.screen_factor
		pitch = clamp(pitch, -60,65)
		
	if event.is_action("Escape"):
		get_tree().quit()
		
	if event.is_action("E"):
		pass

func set_speed() -> void:
	if Input.is_action_pressed("Shift"):
		speed = 11
	else:
		speed = 7.5

func set_camera() -> Basis:
	var camera_offset
	if Playerstats.current_state == Playerstats.game_states.PLAYING:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			var screen_size : Vector2 = get_viewport().get_texture().get_size()
			get_viewport().warp_mouse(screen_size/2)
			camera_yaw.rotation_degrees.y = lerp(camera_yaw.rotation_degrees.y, yaw, camera_speed)
			camera_pitch.rotation_degrees.x = lerp(camera_pitch.rotation_degrees.x, pitch, camera_speed)
			pivot.position.x = move_toward(pivot.position.x, 0, 0.025)
			pivot.position.z = move_toward(pivot.position.z, 0, 0.025)
			pivot.position.y = move_toward(pivot.position.y, 3 - (pitch + 45)/45 ,0.1)
			camera_spring.spring_length = lerp(camera_spring.spring_length, abs(velocity.length())/7.5 + 6.5, 0.05)
			camera_spring.spring_length = clamp(camera_spring.spring_length,2,8)
			camera.fov = move_toward(camera.fov,80 + abs(velocity.length()/3), 1.5)
			
	camera_offset = camera_yaw.transform.basis
	return camera_offset
	
