extends Marker3D

@export var ID :int = 1
@export var pick_up_position :Vector3 = Vector3.ZERO
@export var pick_up_rotation :Vector3 = Vector3.ZERO
@onready var body :RigidBody3D = $Body
@onready var model :MeshInstance3D = $Body/Model
@onready var outline :MeshInstance3D = $Body/Model/Outline
@onready var collision :CollisionShape3D = $Body/Collision
@onready var onscreen :VisibleOnScreenNotifier3D = $Body/Onscreen
@onready var timer :Timer = $Damage_Timer

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
		previous_velocity = body.linear_velocity
		body.can_sleep = false
		model.visible = true
		if Playerstats.object_detected == body and grabbable:
			outline_shader.albedo_color = Color(1,1,1,1)
		else:
			outline_shader.albedo_color = Color(0,0,0,1)
			
		if (true_velocity - body.linear_velocity).length() > 2 and true_velocity != Vector3.ZERO and Playerstats.object_held != body and grabbable:
			body.linear_velocity = true_velocity
			previous_position = body.global_position
		
	else:
		body.can_sleep = true
		model.visible = false
	
	if body.linear_velocity.length() > 0.001:
		true_velocity = (body.global_position - previous_position)/delta
		previous_position = body.global_position
		
	#if abs(body.linear_velocity.length()) > 1:
	#	print("linear: " + str(body.linear_velocity))
	#	print("true " + str(true_velocity))
	
func item_use():
	match ItemData.itemdata[str(ID)]["Type"]:
		1:
			return
		2:
			ID += 1
			Playerstats.object_ID += 1
			set_props()
		3:
			var value :float = ItemData.itemdata[str(ID)]["Value"]
			Playerstats.player.change_in_health(value,true)
			Playerstats.player.body_part("Head",value)
			Playerstats.player.body_part("Torso",value)
			Playerstats.player.body_part("Legs",value)
			Playerstats.player.body_part("Arms",value)
			ID += 1
			Playerstats.object_ID += 1
			set_props()
		4:
			var value :float = ItemData.itemdata[str(ID)]["Value"]
			Playerstats.player.change_in_health(value,true)
			Playerstats.player.body_part("Head",value)
			Playerstats.player.body_part("Torso",value)
			Playerstats.player.body_part("Legs",value)
			Playerstats.player.body_part("Arms",value)
			Playerstats.object_held = null
			Playerstats.object_mass = 0.0
			Playerstats.object_ID = 0
			queue_free()
	
func hold() -> void:
	if Playerstats.object_held == body:
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
	grabbable = false
	Playerstats.object_held = null
	body.freeze = false
	collision.disabled = false
	body.linear_velocity = Playerstats.player.velocity/(1 + body.mass/(15 * Playerstats.strength))
	body.angular_velocity = Playerstats.player.velocity / (3 + (body.mass/(4 * Playerstats.strength)))
	Playerstats.object_mass = 0.0
	await get_tree().create_timer(0.75).timeout
	grabbable = true
	
func throw(power :float) -> void:
	if Playerstats.object_held == body:
		Playerstats.object_mass = 0.0
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
	body.mass = data["Mass"]
	model.mesh = load(data["Model"])
	outline.mesh = load(data["Outline"])
	if data.has("Collision"):
		collision.shape = load(data["Collision"])
