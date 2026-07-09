##The class primarly used for all general props in the game
extends Node3D

class_name Prop

@export var ID :int = 1
@export var pick_up_position :Vector3 = Vector3.ZERO
@export var pick_up_rotation :Vector3 = Vector3.ZERO
@onready var body :RigidBody3D = $Body
@onready var model :MeshInstance3D = $Body/Model
@onready var outline :MeshInstance3D = $Body/Model/Outline
@onready var collision :CollisionShape3D = $Body/Collision
@onready var onscreen :VisibleOnScreenNotifier3D = $Body/Onscreen
@onready var timer :Timer = $Damage_Timer

@export var attribute :bool = false
@export var max_speed :float = 60.0
@export var should_query :bool = false
@export var should_tick :bool = false

var last_entity_touched :Object = null
var distance_to_player :float = 0.0
var previous_velocity :Vector3 = Vector3.ZERO
var previous_position :Vector3 = Vector3.ZERO
var true_velocity :Vector3 = Vector3.ZERO 

var grabbable :bool = true
var can_play_audio :bool = true
var velocity_check :bool = true
var outline_shader :StandardMaterial3D

var can_use :bool = false
var first_time_loaded :bool = true
var item_resource :ItemResource

var functions :Dictionary[StringName, Array] = {}
var valid_input_maps :Array[StringName] = []
var specific_entities :Array[EntityData.BaseEntites] = []
var interval :int = 1
var period :float = 1/60.0
var time_since_last_call :float = 0.0

var behaviour_library :Dictionary[ItemData.Behaviour, Callable] = {
	ItemData.Behaviour.DELETE: delete,
	ItemData.Behaviour.SPAWN_OBJECT: spawn_object,
	ItemData.Behaviour.DROP: drop,
	ItemData.Behaviour.OVERRIDE: override_1,
	ItemData.Behaviour.OVERRIDE_2: override_2,
	ItemData.Behaviour.OVERRIDE_3: override_3,
	ItemData.Behaviour.OVERRIDE_4: override_4,
	ItemData.Behaviour.HEAL: heal, 
	ItemData.Behaviour.HEAL_CONTACTED: heal_contacted,
	ItemData.Behaviour.DAMAGE: damage,
	ItemData.Behaviour.DAMAGE_CONTACTED: damage_contacted,
}

@export var components :Dictionary = {}

signal function_called(function :Callable, extras :Array)
signal trigger_called(trigger :StringName)

func _ready() -> void:
	if first_time_loaded:
		components = ItemData.itemdata[ID]["Components"].duplicate(true)
		first_time_loaded = false
	item_resource = ItemResource.new()
	item_resource.create_item(self)
	link_functions()
	load_item()
	
func _input(event: InputEvent) -> void:
	if Playerstats.object_held == body:
		for function :StringName in valid_input_maps:
			if InputMap.event_is_action(event,function) and event.is_pressed() and can_use:
				call_functions(function)

func _physics_process(delta: float) -> void:
	if should_tick:
		if time_since_last_call >= period:
			var repeats :int = floor(time_since_last_call/period)
			time_since_last_call = fmod(time_since_last_call,period)
			for _i :int in range(repeats):
				call_functions("On_Tick_" + str(interval))
		time_since_last_call += delta
	
	if should_query:
		for object in body.get_colliding_bodies():
			if object is CharacterBody3D and object.is_in_group("Entity"):
				last_entity_touched = object

func load_item() -> void:
	var data :Array = item_resource.recreate_object()
	ID = data[0]
	body.mass = data[2]
	components = data[1]
	var item_data :Dictionary = ItemData.itemdata[ID]
	body.mass = item_data["Mass"]
	model.mesh = load(item_data["Model"])
	outline.mesh = load(item_data["Outline"])
	if data.has("Collision"):
		collision.shape = load(item_data["Collision"])
		
func load_item_from_prop_resource(prop_resource :PropResource) -> void:
	if prop_resource.type == PropResource.Types.DATA:
		ID = prop_resource.ID 
		position = prop_resource.position
		rotation = prop_resource.rotation
		body.position = prop_resource.body_position
		body.rotation = prop_resource.body_rotation
		body.mass = prop_resource.item_resource.Mass
		body.linear_velocity = prop_resource.linear_velocity
		body.angular_velocity = prop_resource.angular_velocity
		attribute = prop_resource.attribute
		max_speed = prop_resource.max_speed
		item_resource = prop_resource.item_resource
	else:
		DeveloperSettings.add_log("Cannot load " + str(self) + " from a prop resource in OBJECT mode, can only use DATA mode.", DeveloperSettings.Log_Types.ERROR)
	
func full_reload() -> void:
	var prop_resource = PropResource.new()
	prop_resource.create_prop_resource_from_data(ID, item_resource, position, rotation, body.position, body.rotation, body.linear_velocity, body.angular_velocity, attribute, max_speed)
	var item_path :StringName = ItemData.itemdata[ID]["Path"]
	var object :PackedScene = load(item_path)
	var new_object :Prop = object.instantiate()
	get_parent().add_child(new_object)
	new_object.load_item_from_prop_resource(prop_resource)
	queue_free()

func _on_body_body_entered(object: Node) -> void:
	if object is StaticBody3D:
		if functions.has("Hit_Geometry"):
				call_functions("Hit_Geometry")
				
	if object is CharacterBody3D:
		if object.is_in_group("Entity"):
			call_functions("Hit_Entity")
			if object.entity_type in specific_entities:
				last_entity_touched = object
				call_functions(EntityData.BaseEntites.keys()[object.entity_type])
				
	if object is StaticBody3D or object is RigidBody3D or object is CharacterBody3D:
		if body.linear_velocity.length() > 0.5:
			play_sound((body.linear_velocity.length()/3) - 12)
		if components.has(ItemData.Properties.BREAKABLE) and body.linear_velocity.length() > 1:
			components[ItemData.Properties.BREAKABLE]["Health"] -= body.linear_velocity.length()/2 
			if components[ItemData.Properties.BREAKABLE]["Health"] <= 0:
				destroy()

func play_sound(volume :float) -> void:
	if can_play_audio:
		can_play_audio = false
		var material_type = ItemData.itemdata[ID]["Material"]
		var audios :Array = ItemData.Audio_Bank[material_type]
		var audio_file :StringName = audios[randi_range(0,audios.size() - 1)]
		SoundManager.create_sound(audio_file,min(volume,0),min(randf_range(0.75,1.25) + (volume + 12)/60,1.5),2,body.global_position, "Object Collided")
		await get_tree().create_timer(0.1,false,true,false).timeout
		can_play_audio = true

func hold() -> void:
	if Playerstats.object_held == body:
		Playerstats.object_components = components
		Playerstats.object_prompts = ItemData.itemdata[ID]["Prompts"]
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
	can_use = false
	can_play_audio = false
#	disable_velocity_check(0.75)
	Playerstats.object_ID = 0
	Playerstats.object_components = {}
	Playerstats.object_prompts = []
	grabbable = false
	Playerstats.object_held = null
	body.freeze = false
	body.linear_velocity = Playerstats.player.true_velocity/(1 + body.mass/(15 * Playerstats.strength))
	body.angular_velocity = Playerstats.player.true_velocity / (3 + (body.mass/(4 * Playerstats.strength)))
	collision.disabled = false
	Playerstats.object_mass = 0.0
	await get_tree().create_timer(0.005,false,true,false).timeout
	can_play_audio = true
	await get_tree().create_timer(0.745,false,true,false).timeout
	grabbable = true

func throw(power :float) -> void:
	if Playerstats.object_held == body:
		can_use = false
		can_play_audio = false
		Playerstats.object_mass = 0.0
		Playerstats.object_components = {}
		Playerstats.object_prompts = []
		global_position = Playerstats.player.hand.global_position
#		disable_velocity_check(0.75)
		Playerstats.object_ID = 0
		grabbable = false
		Playerstats.object_held = null
		body.freeze = false
		collision.disabled = false
		body.apply_central_impulse(5 * Playerstats.strength * power * Vector3(-sin(Playerstats.player.camera_yaw.rotation.y) ,(Playerstats.player.pitch-2)/60, -cos(Playerstats.player.camera_yaw.rotation.y)))
		body.angular_velocity = (0.25 + Playerstats.strength/35) * power * Vector3(1.5,1.5,1.5) / (2.2 + (body.mass/(5 * Playerstats.strength)))
		await get_tree().create_timer(0.005,false,true,false).timeout
		can_play_audio = true
		await get_tree().create_timer(0.745,false,true,false).timeout
		grabbable = true

func get_component_value(component :ItemData.Properties, value_wanted :String, default :Variant = null) -> Variant:
	if components.has(component):
		if components[component].has(value_wanted):
			return components[component].get(value_wanted, default)
		else:
			#DeveloperSettings.add_log(value_wanted + " is an invalid data of component of " + ItemData.Properties.keys()[component],DeveloperSettings.Log_Types.WARNING)
			return default
	else:
		DeveloperSettings.add_log(ItemData.Properties.keys()[component] + " is an invalid component of " + str(self),DeveloperSettings.Log_Types.WARNING)
		return default
		
func get_value_using_range(component :ItemData.Properties) -> float:
	var value :float = get_component_value(component, "Value", 0.0)
	var ran_range :int = abs(int(get_component_value(component, "Range", 0.0)))
	return (value + randi_range(-ran_range, ran_range))
	
func add_to_functions(trigger :String, behaviour :ItemData.Behaviour) -> void:
	if behaviour_library.has(behaviour):
		functions[trigger].append(behaviour_library[behaviour])
	else:
		DeveloperSettings.add_log(ItemData.Behaviour.keys()[behaviour] + " is not a valid behaviour that a prop can have",DeveloperSettings.Log_Types.WARNING)
	
func call_functions(trigger_type :StringName) -> void:
	if functions.has(trigger_type):
		emit_signal("trigger_called",trigger_type)
		for function :Callable in functions[trigger_type]:
			if function.is_valid():
				await function.call()
			else:
				DeveloperSettings.add_log("Invalid function called for prop " + str(self),DeveloperSettings.Log_Types.ERROR)
				break

func link_functions() -> void:
	functions.clear()
	valid_input_maps.clear()
	specific_entities.clear()
	for trigger :Dictionary in components.get(ItemData.Properties.TRIGGER, []):
		match trigger.get("Trigger"):
			
			ItemData.Triggers.ON_BUTTON_PRESSED:
				for reaction :ItemData.Behaviour in trigger.get("Reaction",[]):
					var button_pressed :String = trigger.get("Button_pressed","INVALID_BUTTON")
					if not functions.has(button_pressed):
						functions[button_pressed] = []
						valid_input_maps.append(button_pressed)
					add_to_functions(button_pressed, reaction)
					
			ItemData.Triggers.HIT_GEOMETRY:
				for reaction :ItemData.Behaviour in trigger.get("Reaction",[]):
					if not functions.has("Hit_Geometry"):
						functions["Hit_Geometry"] = []
					add_to_functions("Hit_Geometry", reaction)

			ItemData.Triggers.HIT_SPECIFIC_ENTITY:
				for reaction :ItemData.Behaviour in trigger.get("Reaction",[]):
					var specific_entity :EntityData.BaseEntites = trigger.get("Entity", null)
					var string :String = EntityData.BaseEntites.keys().get(specific_entity)
					if specific_entity != null:
						if not functions.has(string):
							functions[string] = []
							specific_entities.append(specific_entity)
						add_to_functions(string, reaction)
					else:
						DeveloperSettings.add_log("No entity type was given to " + str(self),DeveloperSettings.Log_Types.WARNING)
						
			ItemData.Triggers.ON_TICK:
				for reaction :ItemData.Behaviour in trigger.get("Reaction",[]):
					var tick_inteval :int = trigger.get("Interval", 1)
					interval = tick_inteval
					period = interval/60.0
					var string :String = "On_Tick_" + str(tick_inteval)
					if not functions.has(string):
						functions[string] = []
					add_to_functions(string, reaction)
					
			_:
				DeveloperSettings.add_log(ItemData.Triggers.keys()[trigger.get("Trigger",0)] + " is not a supported trigger.",DeveloperSettings.Log_Types.WARNING)
						

func destroy() -> void:
	emit_signal("function_called",destroy,[])
	queue_free()

func heal() -> void:
	var amt :float = get_value_using_range(ItemData.Properties.HEAL)
	var type :ChangeInHealthManager.TYPES = get_component_value(ItemData.Properties.HEAL, "Type", ChangeInHealthManager.TYPES.GENERAL_HEAL)
	ChangeInHealthManager.handle(Playerstats.player, type, amt)
	emit_signal("function_called", heal, [amt])

func heal_contacted() -> void:
	var amt :float = get_value_using_range(ItemData.Properties.HEAL)
	var type :ChangeInHealthManager.TYPES = get_component_value(ItemData.Properties.HEAL, "Type", ChangeInHealthManager.TYPES.GENERAL_HEAL)
	if last_entity_touched:
		ChangeInHealthManager.handle(last_entity_touched, type, amt)
	else:
		DeveloperSettings.add_log(str(self) + " has tried to call last entity touched function with no last entity touched.",DeveloperSettings.Log_Types.WARNING)
	emit_signal("function_called", heal_contacted, [amt,last_entity_touched])

func damage() -> void:
	var amt :float = -get_value_using_range(ItemData.Properties.DAMAGE)
	var type :ChangeInHealthManager.TYPES = get_component_value(ItemData.Properties.DAMAGE, "Type", ChangeInHealthManager.TYPES.GENERAL_DAMAGE)
	ChangeInHealthManager.handle(Playerstats.player, type, amt)
	emit_signal("function_called",damage,[amt])

func damage_contacted() -> void:
	var amt :float = -get_value_using_range(ItemData.Properties.DAMAGE)
	var type :ChangeInHealthManager.TYPES = get_component_value(ItemData.Properties.DAMAGE, "Type", ChangeInHealthManager.TYPES.GENERAL_DAMAGE)
	if last_entity_touched:
		ChangeInHealthManager.handle(last_entity_touched, type, amt)
	else:
		DeveloperSettings.add_log(str(self) + " has tried to call last entity touched function with no last entity touched.",DeveloperSettings.Log_Types.WARNING)
	emit_signal("function_called",damage_contacted,[amt,last_entity_touched])

func delete() -> void:
	if Playerstats.object_held == body:
		Playerstats.object_held = null
		Playerstats.object_mass = 0.0
		Playerstats.object_ID = 0
	emit_signal("function_called", delete, [])
	queue_free()
	
func spawn_object() -> void:
	var data :Dictionary = components.get(ItemData.Properties.SPAWN_OBJECT, {"Object_Id": 0})
	var object_id :int = data["Object_ID"]
	var spawn_position :Vector3 = Vector3.ZERO
	var spawn_rotation :Vector3 = Vector3.ZERO
	var start_L_velocity :Vector3 = Vector3.ZERO
	var start_A_velocity :Vector3 = Vector3.ZERO
	
	if data.has("Relative_position"):
		spawn_position = body.global_position + data.get("Relative_position",Vector3.ZERO)
	elif data.has("Global_position"):
		spawn_position = data.get("Global_position",Vector3.ZERO)
		
	if data.has("Relative_Rotation"):
		spawn_rotation = body.rotation + data.get("Relative_rotation",Vector3.ZERO)
	elif data.has("Global_Rotation"):
		spawn_rotation = data.get("Global_rotation",Vector3.ZERO)
		
	if data.has("Linear_velocity"):
		start_L_velocity = data.get("Linear_velocity",Vector3.ZERO)
	elif data.has("Angular_Rotation"):
		start_A_velocity = data.get("Angular_velocity",Vector3.ZERO)
		
	var object :Resource = load(ItemData.itemdata[object_id]["Path"])
	var new_object :Prop = object.instantiate()
	new_object.ID = object_id
	get_parent().add_child(new_object)
	new_object.global_position = spawn_position
	new_object.rotation = spawn_rotation
	new_object.body.linear_velocity = start_L_velocity
	new_object.body.angular_velocity = start_A_velocity
	emit_signal("function_called", spawn_object, [new_object])

func store() -> void:
	Inventory.save_item(item_resource)
	delete()

func override_1() -> void:
	override(ItemData.Properties.OVERRIDE)

func override_2() -> void:
	override(ItemData.Properties.OVERRIDE_2)

func override_3() -> void:
	override(ItemData.Properties.OVERRIDE_3)

func override_4() -> void:
	override(ItemData.Properties.OVERRIDE_4)

func override(override_value :ItemData.Properties) -> void:
	var component :Dictionary = get_component_value(override_value, "Override", {})
	var complete_override :bool = get_component_value(override_value,"Complete_override",false)
	var reload :bool = get_component_value(override_value, "Reload", false)
	if not complete_override:
		for data in component:
			if components.has(data):
				components[data] = component[data]
			else:
				DeveloperSettings.add_log(str(data) + " Is not a valid component of " + str(self), DeveloperSettings.Log_Types.WARNING)
	else:
		components = component
	item_resource.create_item(self)
	if reload:
		full_reload()
	else:
		link_functions()
	emit_signal("function_called", override, [override_value ,component, complete_override])

func reset_to_base_components() -> void:
	var base_components :Dictionary[String,Variant] = ItemData.itemdata[ID]
	components = base_components
	var reload :bool = get_component_value(ItemData.Properties.RESET_COMPONENTS_TO_DEFAULT,"Reload",false)
	if reload:
		full_reload()
	else:
		link_functions()
	emit_signal("function_called", reset_to_base_components, [reload])
