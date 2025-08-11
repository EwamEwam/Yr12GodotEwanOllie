extends RigidBody3D

@export var impulse_strength: float = 10.0
@export var bullet_speed: float = 300.0
var damage :float = 2.0

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

func _on_body_entered(body: Node) -> void:
	print(body)
	if body is RigidBody3D:
		var hit_position :Vector3 = global_transform.origin
		var direction :Vector3 = velocity.normalized()
		var impulse :Vector3 = direction * impulse_strength
		var offset :Vector3 = hit_position - body.global_transform.origin

		body.apply_impulse(-offset, impulse)

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
