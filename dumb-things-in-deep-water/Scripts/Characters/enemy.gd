extends CharacterBody3D

var ATTACK_READY: bool = true
@export var dmg :float = 3
@export var health :float = 10
@export var max_health :float = 10
@onready var nav_agent :NavigationAgent3D = $NavigationAgent3D

@export var push_strength :float = 10.0

@export var SPEED :float = 8
@export var ACCEL :float = 3.0

@export var DETECTION_DISTANCE :float = 50.0
@export var MIN_DETECTION_DIST :float = 3.0

func _ready() -> void:
	$Ragdoll/CollisionShape3D.disabled = true
	$Ragdoll.freeze = true

func _smooth_look_at(target_pos: Vector3, delta: float) -> void:
	var to_target = target_pos - $Ragdoll/Body.global_position
	to_target.y = 0

	if to_target.length() > 0.01:

		to_target = to_target.normalized()
		var target_rot = Quaternion(Vector3.FORWARD, to_target).normalized()
		var current_rot = $Ragdoll/Body.global_transform.basis.get_rotation_quaternion()
		var smooth_rot = current_rot.slerp(target_rot, delta * 7.0)
		$Ragdoll/Body.rotation = smooth_rot.get_euler()

func _physics_process(delta :float) -> void:
	$Raycast.target_position = Playerstats.player.global_position - global_position
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is RigidBody3D and collider.is_in_group("Prop") and $Invinicibility.is_stopped() and health > 0:
			take_damage(collider.get_parent().previous_velocity.length()/5 * collider.mass)
			$Invinicibility.start()
			
	
	if health > 0:
		if not is_on_floor():
			velocity.y -= 0.9
		else:
			velocity.y = 0
				
		var distance :float = (global_position - Playerstats.player.global_position).length()
		if distance < DETECTION_DISTANCE and distance > MIN_DETECTION_DIST:
		
			var direction :Vector3 = Vector3()
			direction = (nav_agent.get_next_path_position() - global_position).normalized()
			velocity = velocity.lerp(direction * SPEED, ACCEL * delta)
			_smooth_look_at(global_position + velocity, delta)
			
		elif distance < MIN_DETECTION_DIST:
			
			velocity = velocity.lerp(Vector3.ZERO, delta*10)
			_smooth_look_at(Playerstats.player.global_position, delta)
			
			if ATTACK_READY:
				ATTACK_READY = false
				attack()

		else:
			velocity = velocity.lerp(Vector3.ZERO, ACCEL*delta)
			ATTACK_READY = true

		$Ragdoll/Body.rotation = Vector3(0,$Ragdoll/Body.rotation.y,0)
		push_rigid_body()
		move_and_slide()
	
func update_target_location(target_location :Vector3) -> void:
	if not $Raycast.is_colliding() and health > 0:
		nav_agent.target_position = target_location

func attack():
	var club = $Ragdoll/Body/Club
	$Hit_Timer.start()
	check_hitbox()
	club.rotation_degrees.x = -90
	await get_tree().create_timer(0.25).timeout
	reset_club()

func reset_club():
	var club = $Ragdoll/Body/Club
	club.rotation_degrees.x = 0

func check_hitbox() -> void:
	var bodies :Array[Node3D] = $Ragdoll/Body/Hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Player"):
			body.change_in_health(-dmg,true)

func _on_hit_timer_timeout() -> void:
	ATTACK_READY = true

func take_damage(damage: float):
	if damage > 1 and health > 0:
		health -= damage
		var number :PackedScene = load("res://Scenes/Characters/number.tscn")
		var new_number :Label3D = number.instantiate()
		new_number.create("Enemy_Damage",str(int(round(damage))),global_position)
		$"../../NavigationRegion3D/Environment".add_child(new_number)
		if health <= 0:
			die()

func die():
	$Ragdoll/CollisionShape3D.disabled = false
	$Ragdoll.freeze = false
	$Ragdoll.linear_velocity = velocity
	$CollisionShape3D.disabled = true
	$Healthbar.queue_free()
	velocity = Vector3.ZERO

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
	
func push_back() -> void:
	pass
