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

var camera_bob :Vector2 = Vector2.ZERO
var head_bob_timer :float = 0.0

enum movement_states {NORMAL,AIMING}
var movement_state :movement_states = movement_states.NORMAL

@onready var camera_yaw :Node3D = $Camera_Pivot/Yaw
@onready var camera_pitch :Node3D = $Camera_Pivot/Yaw/Pitch
@onready var pivot :Node3D = $Camera_Pivot
@onready var camera_spring :SpringArm3D = $Camera_Pivot/Yaw/Pitch/Camera_Spring
@onready var camera :Camera3D = $Camera_Pivot/Yaw/Pitch/Camera_Spring/Camera3D
@onready var item_detection :Area3D = $Mesh/Item_Detection
@onready var hand :Marker3D = $Mesh/Hand
@onready var mesh :MeshInstance3D = $Mesh

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
		
		if last_direction_facing != Vector3.ZERO and movement_state == movement_states.NORMAL:
			$Mesh.basis = Basis.looking_at(last_direction_facing)
		
	if not is_on_floor():
		calculated_velocity.y -= gravity * delta
		
	velocity = calculated_velocity
	move_and_slide()
	set_camera_bob(delta)
	set_movement_mode()
	Playerstats.object_detected = item_check()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Playerstats.current_state == Playerstats.game_states.PLAYING:
		yaw += -event.relative.x * Playerstats.sensitivity * Playerstats.screen_factor
		pitch += -event.relative.y * Playerstats.sensitivity * Playerstats.screen_factor
		pitch = clamp(pitch, -60,65)
		
	if event.is_action("Escape"):
		get_tree().quit()
		
	if event.is_action("E"):
		pass
		
	if event.is_action("Left_Click"):
		if Playerstats.object_detected != null:
			if Playerstats.object_detected.get_parent().grabbable:
				Playerstats.object_held = Playerstats.object_detected
				Playerstats.object_detected.get_parent().hold()
		
	if event.is_action_pressed("Right_Click"):
		if Playerstats.object_held != null:
			Playerstats.object_held.get_parent().drop()

func item_check() -> Object:
	var closest_object :Object = null
	if Playerstats.object_held == null:
		var objects :Array[Node3D] = item_detection.get_overlapping_bodies()
		var closest_distance :float = 50
		for item in objects:
			var distance :float = (item.global_position - global_position).length()
			if distance < closest_distance:
				closest_distance = distance
				closest_object = item
	else:
		Playerstats.object_held.get_parent().hold()
	return closest_object

func set_camera_bob(delta :float) -> void:
	if Playerstats.head_bobbing:
		if is_on_floor():
			head_bob_timer += delta * (velocity.length()/2 + 1.25)
		else:
			head_bob_timer += delta * 3
		camera_bob.x = sin(head_bob_timer + PI/2)/12
		camera_bob.y = abs(sin(head_bob_timer)) /12

func set_speed() -> void:
	if Input.is_action_pressed("Shift"):
		speed = 11
	else:
		speed = 7.5

func set_camera() -> Basis:
	var camera_offset
	if Playerstats.current_state == Playerstats.game_states.PLAYING and movement_state == movement_states.NORMAL:
			camera.h_offset = camera_bob.x
			camera.v_offset = camera_bob.y
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
	elif Playerstats.current_state == Playerstats.game_states.PLAYING:
			speed /= 2
			camera.h_offset = camera_bob.x/2
			camera.v_offset = camera_bob.y/2
			mesh.rotation.y = deg_to_rad(yaw)
			last_direction_facing *= mesh.rotation
			pivot.position.x = move_toward(pivot.position.x, 0.605 * cos(mesh.rotation.y), 0.1)
			pivot.position.z = move_toward(pivot.position.z, -0.561 * sin(mesh.rotation.y), 0.1)
			pivot.position.y = move_toward(pivot.position.y, 1.25 ,0.1)
			camera_yaw.rotation_degrees.y = lerp(camera_yaw.rotation_degrees.y, yaw, camera_speed)
			camera_pitch.rotation_degrees.x = lerp(camera_pitch.rotation_degrees.x, pitch, camera_speed)
			camera_spring.spring_length = lerp(camera_spring.spring_length, 2.0, 0.075)
			camera.fov = move_toward(camera.fov,80 + abs(velocity.length()/3), 1.5)
			
	camera_offset = camera_yaw.transform.basis
	return camera_offset
	
func set_movement_mode():
	if Input.is_action_pressed("Alt"):
		movement_state = movement_states.AIMING
	else:
		movement_state = movement_states.NORMAL
