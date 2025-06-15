extends CharacterBody3D
#The main player's script, holds a lot of the game's and player's basic logic, kind of a mess though.
var speed :float = 7.5
var acceleration :float = 45.0
var gravity :float = 20.0
var jump_strength : float = 9.0

var calculated_velocity :Vector3 = Vector3.ZERO
var last_velocity_grounded :Vector3 = Vector3.ZERO
var position_last_frame :Vector3 = Vector3.ZERO
var true_velocity :Vector3 = Vector3.ZERO
var push_strength :float = 10.0

var camera_speed :float = 0.5
var yaw :float = 0.0
var pitch :float = 0.0
var last_direction_facing :Vector3 = Vector3.ZERO

var camera_bob :Vector2 = Vector2.ZERO
var head_bob_timer :float = 0.0

var throw_power :float = 1.0

enum movement_states {NORMAL,AIMING,THROWING}
var movement_state :movement_states = movement_states.NORMAL

@onready var camera_yaw :Node3D = $Camera_Pivot/Yaw
@onready var camera_pitch :Node3D = $Camera_Pivot/Yaw/Pitch
@onready var pivot :Node3D = $Camera_Pivot
@onready var camera_spring :SpringArm3D = $Camera_Pivot/Yaw/Pitch/Camera_Spring
@onready var camera :Camera3D = $Camera_Pivot/Yaw/Pitch/Camera_Spring/Camera3D
@onready var item_detection :Area3D = $Mesh/Item_Detection
@onready var hand :Marker3D = $Mesh/Hand
@onready var mesh :MeshInstance3D = $Mesh
@onready var ground_check :ShapeCast3D = $Ground_Check

#The physics process function which essentially runs every frame. Handles most of the player's essential logic
func _physics_process(delta: float) -> void:
	set_speed()
	
	if ground_check.is_colliding():
		var collider
		collider = ground_check.get_collider(0)  
		if collider is RigidBody3D:
			collider.linear_velocity = Vector3.ZERO
			
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
		
	position_last_frame = global_position
	velocity = calculated_velocity
	push_rigid_body()
	move_and_slide()
	true_velocity = (global_position - position_last_frame) * 60
	
	set_camera_bob(delta)
	Playerstats.object_detected = item_check()
	set_movement_mode(delta)
	
#The function that handles most input events
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Playerstats.current_state == Playerstats.game_states.PLAYING:
		yaw += -event.relative.x * Playerstats.sensitivity * Playerstats.screen_factor
		pitch += -event.relative.y * Playerstats.sensitivity * Playerstats.screen_factor
		pitch = clamp(pitch, -60,65)
		
	if event.is_action_pressed("Escape"):
		get_tree().quit()
		
	if event.is_action_pressed("E"):
		pass
		
	if event.is_action_pressed("Left_Click"):
		if Playerstats.object_detected != null:
			if Playerstats.object_detected.get_parent().grabbable:
				Playerstats.object_held = Playerstats.object_detected
				Playerstats.object_detected.get_parent().hold()
		
	if event.is_action_pressed("Right_Click"):
		if Playerstats.object_held != null:
			Playerstats.object_held.get_parent().drop()

#runs every frame, checks the objects in the player's grab range 
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
			last_direction_facing = Vector3(-sin(deg_to_rad(yaw)),0,-cos(deg_to_rad(yaw)))
			pivot.position.x = move_toward(pivot.position.x, 0.605 * cos(mesh.rotation.y), 0.1)
			pivot.position.z = move_toward(pivot.position.z, -0.561 * sin(mesh.rotation.y), 0.1)
			pivot.position.y = move_toward(pivot.position.y, 1.25 ,0.1)
			camera_yaw.rotation_degrees.y = lerp(camera_yaw.rotation_degrees.y, yaw, camera_speed)
			camera_pitch.rotation_degrees.x = lerp(camera_pitch.rotation_degrees.x, pitch, camera_speed)
			camera_spring.spring_length = lerp(camera_spring.spring_length, 2.0, 0.075)
			camera.fov = move_toward(camera.fov,80 + abs(velocity.length()/3), 1.5)
	camera_offset = camera_yaw.transform.basis
	return camera_offset
	
func set_movement_mode(delta :float) -> void:
	if Input.is_action_pressed("Alt"):
		if Input.is_action_just_pressed("Left_Click") and Playerstats.object_held == null:
			Input.action_release("Left_Click")
		elif Playerstats.object_held != null:
			throw_process(delta)
		else:
			movement_state = movement_states.AIMING
	else:
		movement_state = movement_states.NORMAL

func throw_process(delta :float) -> void:
	if Input.is_action_pressed("Left_Click"):
		movement_state = movement_states.THROWING
		throw_power = clamp(throw_power + delta * 2,1,6)
		print(throw_power)
	elif throw_power > 1:
		print("Throw")
		Playerstats.object_held.get_parent().throw(throw_power)
		movement_state = movement_states.AIMING
		throw_power = 1

func push_rigid_body() -> void:
	var col := get_last_slide_collision()
	if col:
		var col_collider := col.get_collider()
		var col_position := col.get_position()
		if col_collider is RigidBody3D:
			var body_mass = col_collider.mass
			var all_connected_bodies = get_all_connected_bodies(col_collider)
			var friction = calculate_friction(all_connected_bodies)

			var total_mass = 0.0
			for body in all_connected_bodies:
				total_mass += body.mass

			# Original assumption: all sides free except the bottom
			var free_sides = {
				"LEFT": true,
				"RIGHT": true,
				"FRONT": true,
				"BACK": true,
				"TOP": true,
				"BOTTOM": false
			}

			# Check each side for connected bodies
			for connected_body in all_connected_bodies:
				if connected_body == col_collider:
					continue

				var connected_local_pos = col_collider.to_local(connected_body.global_position)

				# Determine which sides are blocked
				if abs(connected_local_pos.x) > abs(connected_local_pos.z):
					if connected_local_pos.x < 0:
						free_sides["LEFT"] = false
					else:
						free_sides["RIGHT"] = false
				elif abs(connected_local_pos.z) > abs(connected_local_pos.x):
					if connected_local_pos.z < 0:
						free_sides["FRONT"] = false
					else:
						free_sides["BACK"] = false
				if abs(connected_local_pos.y) > max(abs(connected_local_pos.x), abs(connected_local_pos.z)):
					if connected_local_pos.y > 0:
						free_sides["TOP"] = false
					else:
						free_sides["BOTTOM"] = false

			# Adjust total mass if all sides are free
			if free_sides["LEFT"] and free_sides["RIGHT"] and free_sides["FRONT"] and free_sides["BACK"] and free_sides["TOP"]:
				total_mass = body_mass
				friction = 0.0

			# Calculate stacked weight and effective mass
			var stacked_weight = 0.0
			for connected_body in all_connected_bodies:
				if connected_body.global_position.y > col_collider.global_position.y:
					stacked_weight += connected_body.mass
			var effective_mass = total_mass + stacked_weight

			# Calculate strength multiplier
			var push_mult = 1.4
			if total_mass < 25:
				push_mult = lerp(1.5, 1.8, (25 - total_mass) / 25.0)
			elif total_mass < 50:
				push_mult = lerp(1.8, 1.5, (total_mass - 25) / 25.0)

			# Handle pushing restrictions
			if total_mass > push_mult:
				var restricted_sides = []
				var opposite_sides = {
					"LEFT": "RIGHT",
					"RIGHT": "LEFT",
					"FRONT": "BACK",
					"BACK": "FRONT",
					"TOP": "BOTTOM",
					"BOTTOM": "TOP"
				}

				for connected_body in all_connected_bodies:
					if connected_body == col_collider:
						continue
					var connected_local_pos = col_collider.to_local(connected_body.global_position)
					var connected_side = ""
					if abs(connected_local_pos.x) > abs(connected_local_pos.z):
						connected_side = "LEFT" if connected_local_pos.x < 0 else "RIGHT"
					else:
						connected_side = "FRONT" if connected_local_pos.z < 0 else "BACK"
					if abs(connected_local_pos.y) > max(abs(connected_local_pos.x), abs(connected_local_pos.z)):
						connected_side = "TOP" if connected_local_pos.y > 0 else "BOTTOM"
					restricted_sides.append(opposite_sides[connected_side])

				var local_position = col_collider.to_local(global_position)
				var push_side = ""
				if abs(local_position.x) > abs(local_position.z):
					push_side = "LEFT" if local_position.x < 0 else "RIGHT"
				else:
					push_side = "FRONT" if local_position.z < 0 else "BACK"
				if abs(local_position.y) > max(abs(local_position.x), abs(local_position.z)):
					push_side = "TOP" if local_position.y > 0 else "BOTTOM"

				if push_side in restricted_sides:
					var applied_force_og = push_strength * push_mult if body_mass >= push_strength * push_mult else body_mass
					# If the side we push against is blocked allow a small force to be applied so that the pushed body can be moved arround a bit. 
					# For example if you want to allign the pushed body flat against the conected one.
					col_collider.apply_impulse(-col.get_normal().normalized() * applied_force_og * 0.2, col_position - col_collider.global_position)
					return

			# Apply impulse if allowed
			var max_speed = (push_strength * push_mult) / effective_mass
			var applied_force = push_strength * push_mult if effective_mass >= push_strength * push_mult else effective_mass
			applied_force *= (1.0 - friction)
			if col_collider.linear_velocity.length() < max_speed:
				var push_direction = -col.get_normal().normalized()
				col_collider.apply_impulse(push_direction * applied_force, col_position - col_collider.global_position)

# Function to calculate friction based on connected bodies and their masses
func calculate_friction(connected_bodies: Array) -> float:
	var total_mass = 0.0
	for body in connected_bodies:
		total_mass += body.mass
	
	# Base friction with adjustments for body count and mass
	var base_friction = 0.1
	var friction_per_body = 0.05
	var mass_friction_factor = 0.001  # Small adjustment based on mass

	# Calculate friction and clamp it within a valid range
	var friction = base_friction + (connected_bodies.size() * friction_per_body) + (total_mass * mass_friction_factor)
	return clamp(friction, 0.0, 1.0)


# Function to get all connected RigidBody3D objects
func get_all_connected_bodies(start_body: RigidBody3D, max_bodies: int = 6) -> Array:
	var connected_bodies = []
	var visited_bodies = {}
	var stack = [start_body]

	while stack and connected_bodies.size() < max_bodies:
		var current_body = stack.pop_front()

		if current_body in visited_bodies:
			continue
		visited_bodies[current_body] = true
		connected_bodies.append(current_body)

		# Stop if the max number of bodies is reached
		if connected_bodies.size() >= max_bodies:
			break

		# Check for child collision shapes
		var collision_shape = current_body.get_child(0) if current_body.get_child_count() > 0 else null
		if collision_shape is CollisionShape3D:
			var shape = collision_shape.shape
			var query = PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.transform = current_body.global_transform
			query.set_margin(0.01)

			# Find intersecting bodies
			var space_state = get_world_3d().direct_space_state
			var result = space_state.intersect_shape(query)

			for item in result:
				var collider = item.collider
				if collider is RigidBody3D and collider != current_body and collider not in visited_bodies and collider.global_position >= current_body.global_position:
					stack.append(collider)

	return connected_bodies
