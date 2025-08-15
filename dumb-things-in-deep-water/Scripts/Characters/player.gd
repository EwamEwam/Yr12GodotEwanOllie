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

var camera_speed :float = 30.0
var yaw :float = 0.0
var pitch :float = 0.0
var last_direction_facing :Vector3 = Vector3.ZERO

var camera_bob :Vector2 = Vector2.ZERO
var head_bob_timer :float = 0.0
var noise :FastNoiseLite = FastNoiseLite.new()
var noise_t :float = 0.0
var camera_shake :Vector2 = Vector2.ZERO
var shake_duration :float = 0.0
var shake_strength :float = 0.0
var camera_jerk: float = 0.0
var jerk_velocity: float = 0.0
var zoom :float = 1.0

var debug_movement :bool = false

var throw_power :float = 1.0
var can_move :bool = true
var reloading :bool = false

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
@onready var camera_raycast :RayCast3D = $Camera_Pivot/Yaw/Pitch/Camera_Spring/Camera3D/Camera_ray

#The physics process function which essentially runs every frame. Handles most of the player's essential logic
func _ready() -> void:
	noise.seed = randi()

func _physics_process(delta: float) -> void:
	debug()
	set_speed()
	fall_damage_calculation()
		
	$Mesh/Body_Parts/Head.position = Vector3.ZERO
	$Mesh/Body_Parts/Torso.position = Vector3.ZERO
	$Mesh/Body_Parts/Legs.position = Vector3.ZERO
	$Mesh/Body_Parts/Arms.position = Vector3.ZERO
		
	if ground_check.is_colliding():
		var collider :Object
		collider = ground_check.get_collider(0)  
		if collider is RigidBody3D:
			collider.linear_velocity = Vector3.ZERO
			
	var current_direction_held :Vector2
	if Playerstats.current_state == Playerstats.game_states.PLAYING:
		var camera_offset :Basis = set_camera(delta)
		current_direction_held = Input.get_vector("Left","Right","Up","Down").normalized()
		var direction :Vector3 = (camera_offset * Vector3(current_direction_held.x, 0, current_direction_held.y)).normalized()
		
		if not debug_movement:
			$Collision.disabled = false
			if is_on_floor() and can_move: 
				if not current_direction_held == Vector2.ZERO:
					last_direction_facing.x = move_toward(last_direction_facing.x,direction.x, 6 * delta)
					last_direction_facing.z = move_toward(last_direction_facing.z,direction.z, 6 * delta)
				calculated_velocity.x = move_toward(calculated_velocity.x, speed * direction.x, acceleration * delta)
				calculated_velocity.z = move_toward(calculated_velocity.z, speed * direction.z, acceleration * delta)
				last_velocity_grounded = Vector3(calculated_velocity.x, 0, calculated_velocity.z)
				calculated_velocity.y = 0
				if Input.is_action_just_pressed("Space"):
					calculated_velocity.y = jump_strength
			elif can_move:
				calculated_velocity.x = move_toward(calculated_velocity.x, (speed * direction.x)/3 + last_velocity_grounded.x/1.5, acceleration/2 * delta)
				calculated_velocity.z = move_toward(calculated_velocity.z, (speed * direction.z)/3 + last_velocity_grounded.z/1.5, acceleration/2 * delta)
			
			if last_direction_facing != Vector3.ZERO and movement_state == movement_states.NORMAL:
				$Mesh.basis = Basis.looking_at(last_direction_facing)
		
		else:
			$Collision.disabled = true
			calculated_velocity.x = direction.x * 300 * speed * delta
			calculated_velocity.z = direction.z * 300 * speed * delta
			calculated_velocity.y = 0
			if Input.is_action_pressed("Space"):
				calculated_velocity.y = 300 * speed * delta
			if Input.is_action_pressed("Ctrl"):
				calculated_velocity.y = -300 * speed * delta
		
	if not is_on_floor() and not debug_movement:
		calculated_velocity.y -= gravity * delta
		
	if Playerstats.current_state == Playerstats.game_states.PLAYING:
		Playerstats.oxygen -= delta/2.5
		
	position_last_frame = global_position
	velocity = calculated_velocity
	push_rigid_body()
	#check_velocity()
	control_shake(delta)
	move_and_slide()
	true_velocity = (global_position - position_last_frame) * 90
	
	set_camera_movement(delta)
	Playerstats.object_detected = item_check()
	set_movement_mode(delta)
	
#The function that handles most input events
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Playerstats.current_state == Playerstats.game_states.PLAYING:
		if movement_state == movement_states.NORMAL:
			yaw += -event.relative.x * Playerstats.sensitivity * Playerstats.screen_factor
			pitch += -event.relative.y * Playerstats.sensitivity * Playerstats.screen_factor
		else:
			yaw += -event.relative.x * Playerstats.aiming_sensitivity * Playerstats.screen_factor
			pitch += -event.relative.y * Playerstats.aiming_sensitivity * Playerstats.screen_factor
		pitch = clamp(pitch, -60,65)
		
	if event.is_action_pressed("Escape"):
		get_tree().quit()
		
	if event.is_action_pressed("E"):
		if Playerstats.object_held != null and not movement_state == movement_states.THROWING and can_move:
			if roundf(Playerstats.inventory_mass * 10) / 10 + roundf(Playerstats.object_mass * 10) / 10 <= roundf(Playerstats.max_inventory):
				Playerstats.inventory.append(Playerstats.object_ID)
				Playerstats.inventory_mass += Playerstats.object_mass
				Playerstats.object_held.get_parent().queue_free()
				Playerstats.object_held = null
				Playerstats.object_ID = 0
				Playerstats.object_mass = 0
				Playerstats.object_properties = []
				Playerstats.object_prompts = []
			else:
				$"../../../HUD".alert("Too heavy for inventory!")

	if event.is_action_pressed("Q"):
		if Playerstats.object_held == null and not movement_state == movement_states.THROWING and Playerstats.inventory.size() > 0 and can_move:
			var new_prop_ID: int = Playerstats.inventory.pop_back()
			var prop :PackedScene = load(ItemData.itemdata[str(new_prop_ID)]["Path"])
			var new_prop :Node3D = prop.instantiate()
			Playerstats.object_ID = new_prop_ID
			Playerstats.object_mass = ItemData.itemdata[str(new_prop_ID)]["Mass"]
			$"../Props".add_child(new_prop)
			Playerstats.object_held = new_prop.body
			Playerstats.inventory_mass -= ItemData.itemdata[str(new_prop_ID)]["Mass"]
			item_check()
		
	if event.is_action_pressed("Left_Click"):
		if Playerstats.object_held == null:
			if Playerstats.object_detected != null and Playerstats.object_detected.get_parent().grabbable and can_move:
				if Playerstats.object_detected.mass <= Playerstats.max_carry_weight:
					Playerstats.object_held = Playerstats.object_detected
					Playerstats.object_detected.get_parent().hold()
					Playerstats.object_ID = Playerstats.object_held.get_parent().ID
					Playerstats.object_mass = Playerstats.object_held.mass
					Input.action_release("Left_Click")
				else:
					$"../../../HUD".alert("Too heavy to lift! (" + str(round(Playerstats.object_detected.mass*10)/10)  +"kg)")
		elif movement_state == movement_states.NORMAL or Playerstats.object_properties.has(ItemData.properties.CANT_DROP_THROW):
			Playerstats.object_held.get_parent().item_use()
		
	if event.is_action_pressed("Right_Click"):
		if Playerstats.object_held != null and movement_state != movement_states.THROWING:
			if check_if_in_wall(Playerstats.object_held) and not Playerstats.object_properties.has(ItemData.properties.CANT_DROP_THROW):
				Playerstats.object_held.get_parent().drop()
			elif not Playerstats.object_properties.has(ItemData.properties.CANT_DROP_THROW):
				$"../../../HUD".alert("Can't place here, there's something in the way.")

	if event.is_action_pressed("V"): set_camera_mode()
		
	if event.is_action_pressed("R"):
		if Playerstats.object_properties.has(ItemData.properties.SHOOT): reload()

	if event.is_action_pressed("B"):
		if Playerstats.no_clip: debug_movement = !debug_movement
	
#runs every frame, checks the objects in the player's grab range 
func item_check() -> Object:
	var closest_object :Object = null
	if Playerstats.current_camera != Playerstats.camera_states.FIRST:
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
	
func load_item_from_inventory(ID :int) -> void:
	Playerstats.object_ID = ID
	var object = load(ItemData.itemdata[str(ID)]["Path"])
	var new_object = object.instantiate()
	new_object.ID = ID
	$"../Props".add_child(new_object)
	new_object.global_position = hand.global_position
	Playerstats.object_held = new_object.body
	new_object.rotation = mesh.rotation + new_object.pick_up_rotation
	Playerstats.inventory_mass -= round(new_object.body.mass * 10) / 10

func set_camera_movement(delta :float) -> void:
	if Playerstats.head_bobbing:
		if is_on_floor():
			head_bob_timer += delta * (velocity.length()/1.8 + 1)
		else:
			head_bob_timer += delta * 3
		camera_bob.x = move_toward(camera_bob.x,sin(head_bob_timer + PI/2)/16 + camera_shake.x,delta * 15)
		camera_bob.y = move_toward(camera_bob.y, abs(sin(head_bob_timer))/16 + camera_shake.y,delta * 15)
	if abs(camera_jerk) > 0.005 or abs(jerk_velocity) > 0.005:
		jerk_velocity = min(jerk_velocity,65)
		var camera_acceleration = -100 * camera_jerk - 25 * jerk_velocity
		jerk_velocity += camera_acceleration * delta
		camera_jerk += jerk_velocity * delta
		camera.rotation.x = camera_jerk
	else:
		jerk_velocity = 0.0
		camera_jerk = 0.0
		camera.rotation.x = 0.0

func set_speed() -> void:
	if not Playerstats.shift_lock:
		if Input.is_action_pressed("Shift"):
			Playerstats.sprint_key = true
		else:
			Playerstats.sprint_key = false
		
	else:
		if Input.is_action_just_pressed("Shift"):
			if Playerstats.sprint_key:
				Playerstats.sprint_key = false
			else:
				Playerstats.sprint_key = true
				
	if Playerstats.sprint_key:
		speed = 11
	else:
		speed = 7.5
				
	speed /= (1 + (Playerstats.object_mass/(15 * Playerstats.strength)))
	speed *= ((Playerstats.legs_hp/Playerstats.max_health)/1.25 + 0.2)

func set_camera(delta: float) -> Basis:
	var camera_offset: Basis
	
	if Playerstats.current_state == Playerstats.game_states.PLAYING and movement_state == movement_states.NORMAL and can_move:
		camera.h_offset = camera_bob.x
		camera.v_offset = camera_bob.y
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		var screen_size: Vector2 = get_viewport().get_texture().get_size()
		get_viewport().warp_mouse(screen_size / 2)
		camera_yaw.rotation_degrees.y = lerp(camera_yaw.rotation_degrees.y, yaw, camera_speed * delta)
		camera_pitch.rotation_degrees.x = lerp(camera_pitch.rotation_degrees.x, pitch, camera_speed * delta)
		pivot.position.x = move_toward(pivot.position.x, 0.0, delta * 2)
		pivot.position.z = move_toward(pivot.position.z, 0.0, delta * 2)
		pivot.position.y = lerp(pivot.position.y, zoom * (3 - (pitch + 45) / 45), delta * 10)
		camera_spring.spring_length = lerp(camera_spring.spring_length, zoom * ((abs(calculated_velocity.length()) / 7.5) + 6.5), delta * 5)
		camera_spring.spring_length = clamp(move_toward(camera_spring.spring_length, camera_spring.spring_length * zoom, delta * 5), 2.0, 8.0)
		camera.fov = move_toward(camera.fov, 80.0 + abs(calculated_velocity.length() / 2.5), delta * 80)
	elif Playerstats.current_camera == Playerstats.camera_states.FIRST:
		camera.h_offset = camera_bob.x
		camera.v_offset = camera_bob.y
		camera_yaw.rotation_degrees.y = lerp(camera_yaw.rotation_degrees.y, yaw, camera_speed * delta)
		camera_pitch.rotation_degrees.x = lerp(camera_pitch.rotation_degrees.x, pitch, camera_speed * delta)
		camera.fov = 90.0
	else:
		speed /= 2
		camera.h_offset = camera_bob.x / 2
		camera.v_offset = camera_bob.y / 2
		mesh.rotation.y = deg_to_rad(yaw)
		last_direction_facing = Vector3(-sin(deg_to_rad(yaw)), 0, -cos(deg_to_rad(yaw)))
		pivot.position.x = move_toward(pivot.position.x, 0.605 * cos(mesh.rotation.y), delta * 8)
		pivot.position.z = move_toward(pivot.position.z, -0.561 * sin(mesh.rotation.y), delta * 8)
		pivot.position.y = lerp(pivot.position.y, 1.25, delta * 10)
		camera_yaw.rotation_degrees.y = yaw
		camera_pitch.rotation_degrees.x = lerp(camera_pitch.rotation_degrees.x, pitch, camera_speed * delta)
		camera_spring.spring_length = lerp(camera_spring.spring_length, 2.0 * zoom, 0.075)
		camera.fov = move_toward(camera.fov, 80.0 + abs(calculated_velocity.length() / 3), delta * 80)
	
	camera_offset = camera_yaw.transform.basis
	return camera_offset
	
func set_movement_mode(delta :float) -> void:
	if Input.is_action_pressed("Alt") or (Playerstats.object_properties.has(ItemData.properties.AIM) and Input.is_action_pressed("Right_Click")):
		if Playerstats.object_held != null:
			movement_state = movement_states.AIMING
			throw_process(delta)
		else:
			movement_state = movement_states.AIMING
			throw_power = 1
	else:
		movement_state = movement_states.NORMAL
		throw_power = 1

func throw_process(delta :float) -> void:
	if Input.is_action_pressed("Left_Click") and not Playerstats.object_properties.has(ItemData.properties.CANT_DROP_THROW):
		movement_state = movement_states.THROWING
		throw_power = clamp(throw_power + delta * 5,1,6)
	elif throw_power > 1 and Input.is_action_pressed("Alt"):
		if check_if_in_wall(Playerstats.object_held):
			Playerstats.object_held.get_parent().throw(throw_power)
			movement_state = movement_states.AIMING
			throw_power = 1
		else:
			$"../../../HUD".alert("Can't throw here, there's something in the way.")
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
	
func fall_damage_calculation() -> void:
	if is_on_floor():
		if calculated_velocity.y < -22:
			change_in_health(calculated_velocity.y/8 ,true)
			Playerstats.legs_hp -= abs(calculated_velocity.y/8)
			$"../../../HUD".shake_part("Legs")

func change_in_health(amt :float, particles :bool) -> void:
	var before :float = Playerstats.health
	var previous_health :int = int(ceil(Playerstats.health))
	Playerstats.health += amt
	if previous_health - int(ceil(Playerstats.health)) > 0:
		Playerstats.time_since_last_damage = 0
		Playerstats.next_health_regen = 0
		if particles:
			var number :PackedScene = load("res://Scenes/Characters/number.tscn")
			var new_number :Label3D = number.instantiate()
			new_number.create("Player_Damage",str(int(previous_health - int(ceil(Playerstats.health)))),global_position)
			$"../NavigationRegion3D/Environment".add_child(new_number)
			$"../../../HUD".health_bar_animation(before)
			shake(max(0.1,-(25*amt)/Playerstats.max_health),0.3)
			jerk_velocity = min((20*amt)/Playerstats.max_health,-1)
		else:
			$"../../../HUD".update_health_bar()
	elif particles and int(ceil(Playerstats.health)) - previous_health > 0:
		var number :PackedScene = load("res://Scenes/Characters/number.tscn")
		var new_number :Label3D = number.instantiate()
		new_number.create("Heal",str(int(int(ceil(Playerstats.health))-previous_health)),global_position)
		Playerstats.health = clamp(Playerstats.health,0,Playerstats.max_health)
		$"../NavigationRegion3D/Environment".add_child(new_number)
		$"../../../HUD".update_health_bar()
	else:
		$"../../../HUD".update_health_bar()

func check_velocity() -> void:
	if abs(calculated_velocity.z - true_velocity.z) > 4:
		velocity.z = true_velocity.z
	if abs(calculated_velocity.x - true_velocity.x) > 4:
		velocity.x = true_velocity.x
	if abs(calculated_velocity.y - true_velocity.y) > 20:
		velocity.y = true_velocity.y
		
func damage_based_on_prop(body :Node, i1 :float, i2 :float, i3 :float, dot :float, Body_part :String) -> void:
	var prop_velocity :Vector3 = body.get_parent().previous_velocity
	var distance_next_tick :float = ((prop_velocity/60 + body.global_position) - global_position).length()
	var current_distance :float = (body.global_position - global_position).length()
	if body.get_parent().timer.is_stopped() and dot > 0.15 and distance_next_tick < current_distance:
		change_in_health(-prop_velocity.length()/i1 * body.mass/i2 * dot,true)
		body_part(str(Body_part), -prop_velocity.length()/i1 * i3 * body.mass/i2 * dot)
	body.get_parent().timer.start()

func calculate_dot_product(body :Node) -> float:
	var to_player :Vector3 = (global_position - body.global_position).normalized()
	var velocity_dir :Vector3 =  body.get_parent().previous_velocity.normalized()
	var dot :float = velocity_dir.dot(to_player)
	return abs(dot)

func body_part(part :String, val: float) -> void:
	if not Playerstats.invincibility:
		match part:
			"Head":
				Playerstats.head_hp += val
			"Legs":
				Playerstats.legs_hp += val
			"Torso":
				Playerstats.torso_hp += val
			"Arms":
				Playerstats.arms_hp += val
	Playerstats.head_hp = clamp(Playerstats.head_hp,0,Playerstats.max_health)
	Playerstats.torso_hp = clamp(Playerstats.torso_hp,0,Playerstats.max_health)
	Playerstats.legs_hp = clamp(Playerstats.legs_hp,0,Playerstats.max_health)
	Playerstats.arms_hp = clamp(Playerstats.arms_hp,0,Playerstats.max_health)
	$"../../../HUD".shake_part(str(part))

func _on_head_body_entered(body: Node) -> void:
	if body.is_in_group("Prop") and abs(body.get_parent().previous_velocity.length()) > 4 and body.get_parent().grabbable:
		damage_based_on_prop(body,8,2,2,calculate_dot_product(body),"Head")

func _on_torso_body_entered(body: Node) -> void:
	if body.is_in_group("Prop") and abs(body.get_parent().previous_velocity.length()) > 4 and body.get_parent().grabbable:
		damage_based_on_prop(body,16,2,1,calculate_dot_product(body),"Torso")

func _on_legs_body_entered(body: Node) -> void:
	if body.is_in_group("Prop") and abs(body.get_parent().previous_velocity.length()) > 4 and body.get_parent().grabbable:
		damage_based_on_prop(body,18,2,1.25,calculate_dot_product(body),"Legs")

func _on_arms_body_entered(body: Node) -> void:
	if body.is_in_group("Prop") and abs(body.get_parent().previous_velocity.length()) > 4 and body.get_parent().grabbable:
		damage_based_on_prop(body,20,2.75,0.75,calculate_dot_product(body),"Arms")
		
func shake(strength: float, duration: float) -> void:
	shake_strength = strength
	shake_duration = duration
	noise_t = randf_range(0,1000)

func set_camera_mode() -> void:
	var current = Playerstats.current_camera
	if current == Playerstats.camera_states.FIRST:
		Playerstats.current_camera = Playerstats.camera_states.CLOSE
		can_move = true
		mesh.visible = true
		zoom = 0.5
	elif current == Playerstats.camera_states.CLOSE:
		Playerstats.current_camera = Playerstats.camera_states.NORMAL
		zoom = 1
	elif current == Playerstats.camera_states.NORMAL:
		Playerstats.current_camera = Playerstats.camera_states.OUTWARDS
		zoom = 1.75
	elif current == Playerstats.camera_states.OUTWARDS and true_velocity == Vector3.ZERO and Playerstats.object_held == null:
		Playerstats.current_camera = Playerstats.camera_states.FIRST
		mesh.visible = false
		can_move = false
		camera_spring.spring_length = 0.0
		pivot.position.y = 0.5
		zoom = 0
	else:
		Playerstats.current_camera = Playerstats.camera_states.CLOSE
		zoom = 0.5
		
func check_if_in_wall(body: RigidBody3D) -> bool:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var collision_node: CollisionShape3D = body.get_node("Collision")
	
	var scaled_shape : = collision_node.shape.duplicate()
	var verts = scaled_shape.points
	for i in range(verts.size()):
		verts[i] *= 0.95 * collision_node.scale.x
	scaled_shape.points = verts
	
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = scaled_shape
	query.transform = body.global_transform
	query.collision_mask = 1
	query.exclude = [body]
	
	var results := space_state.intersect_shape(query, 32)
	
	for result in results:
		var collider = result.collider
		if collider is StaticBody3D or collider is RigidBody3D:
			print(collider)
			return false
	return true

func find_raycast_hit_point():
	if camera_raycast.is_colliding():
		var arm_factor :float = (Playerstats.max_health - Playerstats.arms_hp)/Playerstats.max_health
		camera_raycast.target_position = Vector3(randf_range(-5,5)*arm_factor,randf_range(-5,5)*arm_factor,randf_range(-5,5) + -ItemData.itemdata[str(Playerstats.object_ID)]["Range"])
		var results :Array = [camera_raycast.get_collision_point(),camera_raycast.get_collision_normal()]
		return results
	else:
		return false
	
func check_raycast_collider() -> bool:
	$Camera_Pivot/Yaw/Pitch/Camera_Spring/Camera3D/Object_detection_ray.target_position = Vector3(0,0,-ItemData.itemdata[str(Playerstats.object_ID)]["Range"])
	if $Camera_Pivot/Yaw/Pitch/Camera_Spring/Camera3D/Object_detection_ray.is_colliding():
		var collider = $Camera_Pivot/Yaw/Pitch/Camera_Spring/Camera3D/Object_detection_ray.get_collider()
		if collider is CharacterBody3D:
			if collider.is_in_group("Enemy"):
				return true
		return false
	return false

func shoot(target_position :Array) -> void:
	var ammo :Array
	if Playerstats.object_properties.has(ItemData.properties.PISTOL):
		ammo = Playerstats.ammo["Pistol"]
	if Playerstats.object_properties.has(ItemData.properties.SHOTGUN):
		ammo = Playerstats.ammo["Shotgun"]
	if Playerstats.object_properties.has(ItemData.properties.REVOLVER):
		ammo = Playerstats.ammo["Revolver"]
	if Playerstats.object_properties.has(ItemData.properties.UZI):
		ammo = Playerstats.ammo["UZI"]
	if ammo[0] > 0:
		$"../../../HUD".fire()
		Playerstats.object_held.get_parent().create_bullet(target_position)
		jerk_velocity = ItemData.itemdata[str(Playerstats.object_ID)]["Recoil"] / (0.1 + (Playerstats.arms_hp/Playerstats.max_health)/1.111111111111)
		shake(ItemData.itemdata[str(Playerstats.object_ID)]["Recoil"]/(4*(0.1 + (Playerstats.arms_hp/Playerstats.max_health)/1.111111111111)),0.25)
		ammo[0] -= 1
	else:
		reload()
		
func reload() -> void:
	var ammo :Array
	var max_ammo :int
	if Playerstats.object_properties.has(ItemData.properties.PISTOL):
		ammo = Playerstats.ammo["Pistol"]
		max_ammo = 14
	if Playerstats.object_properties.has(ItemData.properties.SHOTGUN):
		ammo = Playerstats.ammo["Shotgun"]
		max_ammo = 8
	if Playerstats.object_properties.has(ItemData.properties.REVOLVER):
		ammo = Playerstats.ammo["Revolver"]
		max_ammo = 6
	if Playerstats.object_properties.has(ItemData.properties.UZI):
		ammo = Playerstats.ammo["UZI"]
		max_ammo = 30
		
	if ammo[1] == 0 and ammo[0] == 0:
		$"../../../HUD".alert("No Ammo")
		
	elif ammo[0] != max_ammo:
		if ammo[1] + ammo[0] > max_ammo:
			ammo[1] -= max_ammo - ammo[0]
			ammo[0] = max_ammo
		else:
			ammo[0] += ammo[1]
			ammo[1] = 0

func control_shake(delta :float) -> void:
	if shake_duration > 0:
		noise_t += delta * 10.0
		camera_shake = Vector2(
			noise.get_noise_1d(noise_t) * shake_strength,
			noise.get_noise_1d(noise_t + 100.0) * shake_strength
		)
		
		# Reduce duration and strength over time
		shake_duration -= delta
		shake_strength /= 1.25
		
		# Stop shake when duration ends
		if shake_duration <= 0:
			shake_duration = 0
			shake_strength = 0
			camera_shake = Vector2.ZERO

func debug() -> void:
	if Playerstats.camera_hitbox:
		camera_spring.collision_mask = 128
	else:
		camera_spring.collision_mask = 0
	
