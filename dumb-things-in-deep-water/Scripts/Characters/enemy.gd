extends CharacterBody3D

var ATTACK_READY: bool = true
@export var damage :float = 1
@export var health :float = 5
@onready var nav_agent :NavigationAgent3D = $NavigationAgent3D

@export var SPEED :float = 8
@export var ACCEL :float = 3.0

@export var DETECTION_DISTANCE :float = 50.0
@export var MIN_DETECTION_DIST :float = 3.0

func _smooth_look_at(target_pos: Vector3, delta: float) -> void:
	var to_target = target_pos - $Body.global_position
	to_target.y = 0

	if to_target.length() > 0.01:

		to_target = to_target.normalized()
		var target_rot = Quaternion(Vector3.FORWARD, to_target).normalized()
		var current_rot = $Body.global_transform.basis.get_rotation_quaternion()
		var smooth_rot = current_rot.slerp(target_rot, delta * 7.0)
		$Body.rotation = smooth_rot.get_euler()

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
		_smooth_look_at(global_position + velocity, delta)
		
	elif distance < MIN_DETECTION_DIST:
		
		velocity = velocity.lerp(Vector3.ZERO, delta*10)
		_smooth_look_at(Playerstats.player.global_position, delta)
	
		if ATTACK_READY and not $Raycast.is_colliding():
			ATTACK_READY = false
			attack()

	else:
		velocity = velocity.lerp(Vector3.ZERO, ACCEL*delta)
		ATTACK_READY = true

	$Body.rotation = Vector3(0,$Body.rotation.y,0)
	move_and_slide()
	
func update_target_location(target_location :Vector3) -> void:
	$Raycast.target_position = target_location - global_position
	if not $Raycast.is_colliding():
		nav_agent.target_position = target_location

func attack():
	var club = $Body/Club
	$Hit_Timer.start()
	check_hitbox()
	club.rotation_degrees.x = -90
	await get_tree().create_timer(0.25).timeout
	reset_club()

func reset_club():
	var club = $Body/Club
	club.rotation_degrees.x = 0

func check_hitbox() -> void:
	var bodies :Array[Node3D] = $Body/Hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Player"):
			body.change_in_health(-damage,true)

func _on_hit_timer_timeout() -> void:
	ATTACK_READY = true
