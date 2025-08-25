extends RigidBody3D

@export var impulse_strength: float = 10.0
@export var bullet_speed: float = 300.0
var damage :float = 7.0
var base_impulse_strength :float = 10.0

var velocity: Vector3 = Vector3.ZERO
var target :Vector3 = Vector3.ZERO
var target_normal :Vector3 = Vector3.ZERO

func create(target_position: Array) -> void:
	target = target_position[0]
	target_normal = target_position[1]
	
	look_at(target_position[0], Vector3.UP)

	velocity = -global_transform.basis.z * bullet_speed
	linear_velocity = velocity
	
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var direction = -global_transform.basis.z
	state.linear_velocity = direction * bullet_speed
	#check_if_in_object()

func check_if_in_object() -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var collision_node: CollisionShape3D = $Collision
	
	var shape : = collision_node.shape.duplicate()
	
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1
	query.exclude = [self]
	
	var results := space_state.intersect_shape(query, 32)
	
	for result in results:
		var collider = result.collider
		if collider is StaticBody3D or collider is RigidBody3D or collider is CharacterBody3D:
			collide(collider)

func collide(body: Node) -> void:
	print(body)
	if body is RigidBody3D:
		var collision_normal = (global_position - body.global_position).normalized()
		var bullet_direction = velocity.normalized()
		var impact_factor = -bullet_direction.dot(collision_normal)
		impact_factor = max(impact_factor, 0.0)
		var impulse_magnitude = base_impulse_strength * impact_factor
		var impulse = bullet_direction * impulse_magnitude
		body.apply_impulse(impulse, global_position - body.global_position)
		
		if body.is_in_group("Prop"):
			body.get_parent().disable_velocity_check(0.5)
			body.get_parent().play_sound(randf_range(-7,-5))

	if body.is_in_group("Enemy"):
		body.take_damage(damage)

	if body is StaticBody3D:
		var hole_scene: PackedScene = preload("res://Scenes/Level/bullet_hole.tscn")
		var new_hole :Node3D = hole_scene.instantiate()
		var world :SubViewport = get_node('/root/World/SubViewportContainer/SubViewport')
		if not world:
			return
		world.add_child(new_hole)
		
		var decal_position = target + target_normal * 0.01
		new_hole.global_position = decal_position
		
		if target_normal.length_squared() < 0.001:
			target_normal = Vector3.UP
		
		basis = Basis()
		var up :Vector3 = Vector3.UP
		if abs(target_normal.dot(up)) > 0.999:
			up = Vector3.RIGHT
		
		var right :Vector3 = up.cross(target_normal).normalized()
		if right.length_squared() < 0.001:
			right = Vector3.RIGHT if abs(target_normal.dot(Vector3.RIGHT)) < 0.999 else Vector3.FORWARD
			right = right.cross(target_normal).normalized()
		
		var new_up :Vector3 = target_normal.cross(right).normalized()
		
		basis.x = right
		basis.y = new_up
		basis.z = -target_normal.normalized()
		
		# Add random rotation around the normal (z-axis of the basis)
		var random_angle :float = randf_range(0, TAU)  # Random angle between 0 and 2π
		basis = basis.rotated(target_normal, random_angle)
		
		new_hole.global_transform.basis = basis
	queue_free()

func _on_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node) -> void:
	collide(body)
