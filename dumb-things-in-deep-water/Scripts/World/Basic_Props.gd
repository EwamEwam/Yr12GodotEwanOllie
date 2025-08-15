extends Node3D

@export var ID :int = 1
@export var pick_up_position :Vector3 = Vector3.ZERO
@export var pick_up_rotation :Vector3 = Vector3.ZERO
@onready var body :RigidBody3D = $Body
@onready var model :MeshInstance3D = $Body/Model
@onready var outline :MeshInstance3D = $Body/Model/Outline
@onready var collision :CollisionShape3D = $Body/Collision
@onready var onscreen :VisibleOnScreenNotifier3D = $Body/Onscreen
@onready var timer :Timer = $Damage_Timer

var object_properties :Array

@export var attribute :bool = false
@export var max_speed :float = 60.0

var previous_velocity :Vector3 = Vector3.ZERO
var previous_position :Vector3 = Vector3.ZERO
var true_velocity :Vector3 = Vector3.ZERO 

var grabbable :bool = true
var outline_shader :StandardMaterial3D

func _ready() -> void:
	outline_shader = outline.material_overlay
	pick_up_rotation = Vector3(deg_to_rad(pick_up_rotation.x),deg_to_rad(pick_up_rotation.y),deg_to_rad(pick_up_rotation.z))
	set_props()
	
func _physics_process(delta: float) -> void:
	if onscreen.is_on_screen():
		item_process()
		limit_speed()
		previous_velocity = body.linear_velocity
		body.can_sleep = false
		model.visible = true
		if Playerstats.object_detected == body and grabbable:
			outline_shader.albedo_color = Color(1,1,1,1)
		else:
			outline_shader.albedo_color = Color(0,0,0,1)
			
		if (true_velocity - body.linear_velocity).length() > 2 and true_velocity != Vector3.ZERO and Playerstats.object_held != body and grabbable:
			body.linear_velocity = true_velocity
			print(body.linear_velocity)
			previous_position = body.global_position
		
	else:
		body.can_sleep = true
		model.visible = false
	
	if object_properties.has(ItemData.properties.TV):
		var distance_to_player :float = (global_position - Playerstats.player.global_position).length()
		$VideoStreamPlayer.volume_db = -10 - distance_to_player/1.5
		if attribute and not $VideoStreamPlayer.is_playing():
			$VideoStreamPlayer.play()
			
	if object_properties.has(ItemData.properties.SPEAKER):
		if attribute and not $Body/Audio_Player.playing:
			$Body/Audio_Player.play()
	
	if body.linear_velocity.length() > 0.001:
		true_velocity = (body.global_position - previous_position)/delta
		previous_position = body.global_position
		
	#if abs(body.linear_velocity.length()) > 1:
	#	print("linear: " + str(body.linear_velocity))
	#	print("true " + str(true_velocity))
	
func item_process() -> void:
	var properties := ItemData.properties
	
	for property in object_properties:
		if Playerstats.object_properties.has(properties.AIM):
			if Input.is_action_pressed("Right_Click") or Input.is_action_pressed("Alt"):
				Playerstats.player.movement_state = Playerstats.player.movement_states.AIMING
				
		if property == properties.TV:
			if attribute:
				$Body/Model/Screen.visible = true
				var video_texture :Texture2D = $VideoStreamPlayer.get_video_texture()
				var new_texture = StandardMaterial3D.new()
				new_texture.albedo_texture = video_texture
				$Body/Model/Screen.material_override = new_texture
			else:
				$Body/Model/Screen.visible = false
				
		if property == properties.SPEAKER:
			if attribute:
				$Body/Light.light_color = Color(0.092, 0.553, 0.0)
			else:
				$Body/Light.light_color = Color(0.859, 0.0, 0.0)
				
		if property == properties.PAINTING:
			var raycast :RayCast3D = $Body/Wall_Check
			if raycast.is_colliding() and Playerstats.object_held != body and not attribute:
				attribute = true
				body.freeze = true
				true_velocity = Vector3.ZERO
				body.linear_velocity = Vector3.ZERO
				previous_position = global_position
				
				var normal :Vector3 = raycast.get_collision_normal()
				var is_vertical :bool = abs(normal.dot(Vector3.UP)) > 0.99
				var forward :Vector3 = -normal.normalized()
				
				if not is_vertical:
					var up = Vector3.UP
					var right = forward.cross(up).normalized()
					up = right.cross(forward).normalized()
					body.basis = Basis(right, up, forward)
					
			elif not attribute:
				body.freeze = false
				
func item_use():
	var held_properties :Array = Playerstats.object_properties
	var properties := ItemData.properties
	
	for property in held_properties:
		if property == properties.ID_UPDATE:
			ID += 1
			Playerstats.object_ID += 1
			set_props()
		
		if property == properties.HEAL:
			var value :float = ItemData.itemdata[str(ID)]["Value"]
			Playerstats.player.change_in_health(value,true)
			Playerstats.player.body_part("Head",value)
			Playerstats.player.body_part("Torso",value)
			Playerstats.player.body_part("Legs",value)
			Playerstats.player.body_part("Arms",value)
	
		if property == properties.DELETE:
			Playerstats.object_held = null
			Playerstats.object_mass = 0.0
			Playerstats.object_ID = 0
			queue_free()
			
		if property == properties.SHOOT:
			if $Shoot_Cooldown.is_stopped() and Playerstats.player.movement_state != Playerstats.player.movement_states.NORMAL:
				attribute = false
				$Shoot_Cooldown.start(ItemData.itemdata[str(ID)]["Interval"] / (0.5 + (Playerstats.arms_hp/Playerstats.max_health)/2))
				var target_position = Playerstats.player.find_raycast_hit_point()
				if not target_position is Array:
					target_position = [Vector3.ZERO,Vector3.ZERO]
				Playerstats.player.shoot(target_position)
				await $Shoot_Cooldown.timeout
				attribute = true
				
		if property == properties.TV:
			$VideoStreamPlayer.stream = load(ItemData.itemdata[str(ID)]["Video"])
			if attribute == false:
				$Body/Model/Screen.visible = true
				attribute = true
			else:
				$Body/Model/Screen.visible = false
				attribute = false
		
		if property == properties.SPEAKER:
			$Body/Audio_Player.stream = load(ItemData.itemdata[str(ID)]["Audio"])
			if attribute == false:
				attribute = true
				$Body/Light.light_color = Color(0.092, 0.553, 0.0)
			else:
				attribute = false
				$Body/Light.light_color = Color(0.859, 0.0, 0.0)
			
func hold() -> void:
	if Playerstats.object_held == body:
		Playerstats.object_properties = ItemData.itemdata[str(ID)]["Properties"]
		Playerstats.object_prompts = ItemData.itemdata[str(ID)]["Prompts"]
		global_position = Playerstats.player.hand.global_position
		Playerstats.object_mass = body.mass
		body.position = pick_up_position
		body.rotation = Vector3.ZERO
		rotation = Playerstats.player.mesh.rotation + pick_up_rotation
		collision.disabled = true
		body.freeze = true
		grabbable = false
		
func drop() -> void:
	global_position = Playerstats.player.hand.global_position
	Playerstats.object_ID = 0
	Playerstats.object_properties = []
	Playerstats.object_prompts = []
	grabbable = false
	Playerstats.object_held = null
	body.freeze = false
	body.linear_velocity = Playerstats.player.true_velocity/(1 + body.mass/(15 * Playerstats.strength))
	body.angular_velocity = Playerstats.player.true_velocity / (3 + (body.mass/(4 * Playerstats.strength)))
	collision.disabled = false
	Playerstats.object_mass = 0.0
	await get_tree().create_timer(0.75).timeout
	grabbable = true
	
func throw(power :float) -> void:
	if Playerstats.object_held == body:
		Playerstats.object_mass = 0.0
		Playerstats.object_properties = []
		Playerstats.object_prompts = []
		global_position = Playerstats.player.hand.global_position
		Playerstats.object_ID = 0
		grabbable = false
		Playerstats.object_held = null
		body.freeze = false
		collision.disabled = false
		body.apply_central_impulse(5 * Playerstats.strength * power * Vector3(-sin(Playerstats.player.camera_yaw.rotation.y) ,(Playerstats.player.pitch-2)/60, -cos(Playerstats.player.camera_yaw.rotation.y)))
		body.angular_velocity = (0.25 + Playerstats.strength/35) * power * Vector3(1.5,1.5,1.5) / (2.2 + (body.mass/(5 * Playerstats.strength)))
		await get_tree().create_timer(0.75).timeout
		grabbable = true
	
func set_props() -> void:
	var data :Dictionary = ItemData.itemdata[str(ID)]
	object_properties = ItemData.itemdata[str(ID)]["Properties"]
	body.mass = data["Mass"]
	model.mesh = load(data["Model"])
	outline.mesh = load(data["Outline"])
	if data.has("Collision"):
		collision.shape = load(data["Collision"])
	if object_properties.has(ItemData.properties.TV):
		$VideoStreamPlayer.stream = load(ItemData.itemdata[str(ID)]["Video"])
	if object_properties.has(ItemData.properties.SPEAKER):
		$Body/Audio_Player.stream = load(ItemData.itemdata[str(ID)]["Audio"])

func limit_speed() -> void:
	if body.linear_velocity.length() > max_speed:
		body.linear_velocity = body.linear_velocity.normalized() * max_speed
	
func create_bullet(target_position :Array) -> void:
	var bullet :PackedScene = load(ItemData.itemdata[str(ID)]["Bullet"])
	var new_bullet :Node3D = bullet.instantiate()
	$"../..".add_child(new_bullet)
	new_bullet.global_position = $Body/Spawner.global_position
	new_bullet.create(target_position)
