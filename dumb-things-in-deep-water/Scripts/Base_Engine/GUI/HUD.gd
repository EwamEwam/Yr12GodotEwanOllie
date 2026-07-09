extends Control

@onready var reticle :Sprite2D = $Reticule
@onready var reticle_gun :Sprite2D = $ReticuleGun
@onready var throw_bar :ProgressBar = $Throw_Bar
@onready var player :CharacterBody3D = $"../SubViewportContainer/SubViewport/Player"

@onready var health_bar :TextureProgressBar = $CornerHUD/Health_Bar_Border/Health_Bar
@onready var health_bar_border :TextureProgressBar = $CornerHUD/Health_Bar_Border
@onready var health_bar_end :ColorRect = $CornerHUD/Bar_End
@onready var health_bar_border_end :Sprite2D = $CornerHUD/Health_Bar_Border/Health_Bar_Border_End

var level_time :int = 0
var formatted_time :Vector2i = Vector2i(0,0)
var alerts :Array[Node] = []

var red_fade :float = 0

var damage_numbers :Array[Label] = []
var damage_number_velocity :Array[Vector2] = []

var heal_numbers :Array[Label] = []
var heal_number_velocity :Array[Vector2] = []

func _ready() -> void:
	Playerstats.player = player
	if Playerstats.max_health <= 300:
		health_bar.value = round_to_1_DP(Playerstats.health)
		health_bar_border_end.position.x = ((1.0/2.0) * Playerstats.max_health) + 19
		health_bar_border.value = (Playerstats.max_health/2) + 19
		health_bar_end.position.x = 138 + (3.0/2.0) * round_to_1_DP(Playerstats.health)
	else:
		health_bar.max_value = Playerstats.max_health
		health_bar.value = Playerstats.health
		health_bar_border.value = 169
		health_bar_end.position.x = 588

func _process(delta: float) -> void:
	health_bar.value = round_to_1_DP(Playerstats.health)
	$CornerHUD/Flux_metre.frame = Playerstats.stamina
	reticle.modulate.g = 1
	reticle.modulate.b = 1
	reticle.modulate.a = 0.2
	if player.movement_state != player.movement_states.NORMAL:
		reticle.modulate.a = 1

	if player.movement_state == player.movement_states.THROWING:
		throw_bar.visible = true
		throw_bar.value = player.throw_power
	else:
		throw_bar.visible = false
	
	
	if Playerstats.object_held == null:
		$Item_Description/Holding.text = "Nothing"
		$Item_Description/Holding.position = Vector2(-265,-226)
		$Item_Description/Holding.size = Vector2(1,1)
		$Item_Description/Weight.visible = false
		$Item_Description/TextEnder.visible = false
		$Item_Description/Object_Icons.play("error")
		$Item_Description/Object_Icons.visible = false
	else:
		$Item_Description/Holding.text = str(ItemData.itemdata[Playerstats.object_ID]["Name"])
		$Item_Description/Holding.position = Vector2(-265,-235)
		$Item_Description/Weight.visible = true
		$Item_Description/Holding.size = Vector2(1,1)
		$Item_Description/Weight.text = "(" + str(round(Playerstats.object_held.mass*10)/10) + "Kg)"
		$Item_Description/TextEnder.visible = true
		$Item_Description/Object_Icons.visible = true
		if str(Playerstats.object_ID) in $Item_Description/Object_Icons.sprite_frames.get_animation_names():
			$Item_Description/Object_Icons.play(str(Playerstats.object_ID))
		else:
			$Item_Description/Object_Icons.play("error")
			
	$FPS.text = "FPS " +  str(int(Engine.get_frames_per_second()))
			
	$Item_Description/Line.size.x = round($Item_Description/Holding.size.x /(4.0/3.0)) + 3
	$Item_Description/TextEnder.position.x = -260 + ($Item_Description/Line.size.x * 2)
		
	$CornerHUD/Hp.text = str(int(ceil(Playerstats.health))) + "/" + str(int(Playerstats.max_health))
	
	if Playerstats.max_health <= 300:
		@warning_ignore("integer_division")
		health_bar_border.value = (Playerstats.max_health/2) + 19
		@warning_ignore("integer_division")
		health_bar_border_end.position.x = (Playerstats.max_health/2) + 19
		health_bar_end.position.x = 138 + (3.0/2.0) * round_to_1_DP(Playerstats.health)
	else:
		@warning_ignore("integer_division")
		health_bar_border.value = 169
		@warning_ignore("integer_division")
		health_bar_border_end.position.x = 169
		health_bar_end.position.x = 138 + 450 * (Playerstats.health/Playerstats.max_health)
	
	#set_reticle_size()
	set_red_border_opacity(delta)
	process_damage_and_healing_numbers(delta)
	
	#if Playerstats.object_held != null:
	#	if Playerstats.object_properties.has(ItemData.Properties.AIM) and Playerstats.player.movement_state == Playerstats.player.movement_states.AIMING and Playerstats.object_held.get_parent().attribute:
	#		if Playerstats.player.check_raycast_collider():
	#			reticle.modulate.g = 0
	#			reticle.modulate.b = 0
			
	for text in alerts:
		text.position.y = 82 + (25*alerts.find(text))
		
	#$Ammo.visible = false
	#set_ammo()
		
	set_prompts()

#UNUSED FUNCTION WILL CRASH WHEN RUN,
#Orginally used for player body parts GUI, but they do not exist anymore
#func shake_part(body_part :String) -> void:
	#var part :Sprite2D
	#var Body_part_hp :float
	#Body_part_hp = clamp(Body_part_hp,0,Playerstats.max_health)
	#match body_part:
		#"Head":
			#part = $Health_bar/BodyPartHead
			#Body_part_hp = Playerstats.head_hp
		#"Torso":
			#part = $Health_bar/BodyPartTorso
			#Body_part_hp = Playerstats.torso_hp
		#"Legs":
			#part = $Health_bar/BodyPartLegs
			#Body_part_hp = Playerstats.legs_hp
		#"Arms":
			#part = $Health_bar/BodyPartArms
			#Body_part_hp = Playerstats.arms_hp
			#
	#var tween :Tween = get_tree().create_tween()
	#var color: float = (Playerstats.max_health - Body_part_hp)/Playerstats.max_health
	#part.modulate = Color.from_hsv(0,color,1,1)
	#tween.tween_property(part, "scale", Vector2(1.75,3.5) , 0.025).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#await tween.finished
	#var tween2 :Tween = get_tree().create_tween()
	#tween2.tween_property(part, "scale", Vector2(3.5,1.75) , 0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	#await tween2.finished
	#var tween3 :Tween = get_tree().create_tween()
	#tween3.tween_property(part, "scale", Vector2(3,3) , 0.025).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

##Runs when the player's health bar is updated,
##[br]Requires the health before the change as a parameter
func health_bar_animation(before :float) -> void:
	if Playerstats.max_health <= 300:
		#var tween :Tween = get_tree().create_tween()
		var tween2 :Tween = get_tree().create_tween()
		var texture :ColorRect = ColorRect.new()
		#tween.tween_property($Health_bar/Health_Bar, "value", round_to_1_DP(Playerstats.health), abs($Health_bar/Health_Bar.value-Playerstats.health)/200).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		#tween.parallel().tween_property($Health_bar/Bar_End, "position", Vector2(138 + (3.0/2.0) * round_to_1_DP(Playerstats.health),441), abs($Health_bar/Health_Bar.value-Playerstats.health)/200).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		texture.position = Vector2(141,441)
		texture.color = Color(0.831, 0.613, 0.613, 1.0)
		texture.size = Vector2(round((3.0/2.0)*before),18)
		texture.z_index = -1
		$CornerHUD.add_child(texture)
		tween2.tween_property(texture, "modulate", Color(1,1,1,0), 0.75).set_trans(Tween.TRANS_LINEAR)
		#await tween.finished
		health_bar.value = round_to_1_DP(Playerstats.health)
		health_bar_end.position.x = 138 + (3.0/2.0) * round_to_1_DP(Playerstats.health)
		await tween2.finished
		texture.queue_free()
	
##Instantly update the player's health bar
func update_health_bar() -> void:
	if Playerstats.max_health <= 300:
		health_bar.value = round_to_1_DP(Playerstats.health)
		health_bar_end.position.x = 138 + (3.0/2.0) * round_to_1_DP(Playerstats.health)
	
##Formats the time in the level_time variable into hours and seconds
##[br]then displays it in the GUI
func format_time() -> void:
	level_time = clamp(level_time + 1, 0, 3599)
	@warning_ignore("integer_division")
	formatted_time.x = floor(level_time/60)
	formatted_time.y = level_time % 60
	var string1 :String
	var string2 :String
	
	if formatted_time.y < 10:
		string1 = "0" + str(formatted_time.y)
	else:
		string1 = str(formatted_time.y)
		
	if formatted_time.x < 10:
		string2 = "0" + str(formatted_time.x)
	else:
		string2 = str(formatted_time.x)
		
	$Timer.text = string2 + ":" + string1

##Creates an alert on the GUI, requires a string has a parameter
##Supports up to 9 max alerts before the oldest one gets deleted
func alert(text :String = "Alert with no message", time :float = 1) -> void:
	if alerts.size() > 9:
		alerts[0].queue_free()
		alerts.pop_front()
	var text_box: Label = Label.new()
	alerts.append(text_box)
	text_box.label_settings = load("res://Scenes/Misc/Label_Settings.tres")
	text_box.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	text_box.position = Vector2(640, 57+(25*alerts.size()))
	text_box.size = Vector2(640,20)
	text_box.text = text
	text_box.z_index = -1
	add_child(text_box)
	var tween1 :Tween = get_tree().create_tween()
	tween1.tween_property(text_box,"position",Vector2(-6,57+(25*alerts.size())),0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(time).timeout
	if is_instance_valid(text_box):
		var tween2 :Tween = get_tree().create_tween()
		tween2.tween_property(text_box,"modulate",Color(1,1,1,0),2).set_trans(Tween.TRANS_LINEAR)
		await tween2.finished
		if is_instance_valid(text_box):
			text_box.queue_free()
			alerts.erase(text_box)

func set_prompts() -> void:
	$Item_Description/Prompts/InventoryIcon.visible = false
	$Item_Description/Prompts/PickUp.visible = false
	$Item_Description/Prompts/Drop.visible = false
	$Item_Description/Prompts/Throw.visible = false
	$Item_Description/Prompts/Open.visible = false
	$Item_Description/Prompts/Eat.visible = false
	$Item_Description/Prompts/Heal.visible = false
	$Item_Description/Prompts/Shoot.visible = false
	$Item_Description/Prompts/Aim.visible = false
	$Item_Description/Prompts/Toggle.visible = false
	
	var prompts :Array = Playerstats.object_prompts
	var prompt_type = ItemData.Prompts
	if Playerstats.show_prompts:
		$Item_Description/Prompts/InventoryIcon.visible = true
		if Playerstats.object_held != null:
			for prompt in prompts:
				if prompt == prompt_type.OPEN:
					$Item_Description/Prompts/Open.visible = true
				if prompt == prompt_type.HEAL:
					$Item_Description/Prompts/Heal.visible = true
				if prompt == prompt_type.EAT:
					$Item_Description/Prompts/Eat.visible = true
				if prompt == prompt_type.SHOOT:
					$Item_Description/Prompts/Shoot.visible = true
				if prompt == prompt_type.AIM:
					$Item_Description/Prompts/Aim.visible = true
				if prompt == prompt_type.TOGGLE:
					$Item_Description/Prompts/Toggle.visible = true
					
#			if not Playerstats.object_properties.has(ItemData.Properties.CANT_DROP_THROW):
#					$Item_Description/Prompts/Drop.visible = true
#					$Item_Description/Prompts/Throw.visible = true
			
		elif Playerstats.object_detected != null:
			if Playerstats.object_detected.get_parent().grabbable:
				$Item_Description/Prompts/PickUp.visible = true
				
#func set_ammo() -> void:
	#if Playerstats.object_properties.has(ItemData.Properties.SHOOT):
		#$Ammo.visible = true
		#var ammo1 :int
		#var ammo2 :int
		#if Playerstats.object_properties.has(ItemData.Properties.PISTOL):
			#ammo1 = Playerstats.ammo["Pistol"][0]
			#ammo2 = Playerstats.ammo["Pistol"][1]
		#$Ammo/Ammo.text = str(ammo1)
		#$Ammo/Ammo2.text = str(ammo2)
	
func fire() -> void:
	var animation_name :String = str(Playerstats.object_ID)+"_Fire"
	$Ammo/Gun_HUD.play(animation_name)
	var bullet :PackedScene = load("res://Scenes/GUI/white_bullet.tscn")
	var new_bullet :Sprite2D = bullet.instantiate()
	new_bullet.position = Vector2(-50,-15)
	$Ammo.add_child(new_bullet)

#func set_reticle_size() -> void:
	#if Playerstats.object_properties.has(ItemData.Properties.SHOOT):
	#	reticle_gun.visible = true
	#	if Playerstats.object_held.get_parent().attribute:
	#		reticle_gun.modulate.a = 0.5
	#	else:
	#		reticle_gun.modulate.a = 0.1

	#	var scale_factor :float = abs(2.5 * player.camera_jerk) + 1
	#	reticle_gun.scale = scale_factor * Vector2(1,1)
	#else:
	#	reticle_gun.visible = false

func round_to_1_DP(number :float = 0) -> float:
	return (round(10*number)/10)
	
func set_red_border_opacity(delta :float) -> void:
	if abs(red_fade) > 0.005:
		red_fade = min(red_fade,1)
		red_fade -= 4 * red_fade * delta
		$RedBorder.modulate.a = red_fade
	else:
		red_fade = 0.0
		$RedBorder.modulate.a = 0
		
func set_red(num :float) -> void:
	red_fade += num

func override_reticule(Screen_position :Vector2) -> void:
	reticle_gun.position = Screen_position

func create_number(type :String = "Damage", amt :int = 0):
	var new_number :Label = Label.new()
	var label_setting :LabelSettings = LabelSettings.new()
	new_number.label_settings = label_setting
	new_number.scale = Vector2(2,2)
	new_number.text = str(amt)
	new_number.position = Vector2(health_bar_end.global_position.x-5, 430)
	var font
	if type == "Damage":
		font = load("res://Assets/Sprites/Red_Numbers.png")
		damage_number_velocity.append(Vector2(randf_range(0,2),-5))
		damage_numbers.append(new_number)
	if type == "Heal":
		font = load("res://Assets/Sprites/Green_Numbers.png")
		heal_number_velocity.append(Vector2(0,-5))
		heal_numbers.append(new_number)
	label_setting.font = font
	$CornerHUD.add_child(new_number)
	
func process_damage_and_healing_numbers(delta :float) -> void:
	for i in range(damage_numbers.size()):
		if damage_numbers.size() == damage_number_velocity.size():
			damage_numbers[i].position += damage_number_velocity[i] * (delta*60)
			damage_number_velocity[i].y += 0.2 * (delta*60)
		else:
			for item in damage_numbers:
				if is_instance_valid(item):
					damage_numbers.erase(item)
					item.queue_free()
			damage_number_velocity.clear()
			
	for i in range(heal_numbers.size()):
		if heal_numbers.size() == heal_number_velocity.size():
			heal_numbers[i].position += heal_number_velocity[i] * (delta*60)
			heal_number_velocity[i].y /= 1.15 * (delta*60)
			heal_numbers[i].modulate.a -= 0.02 * (delta*60)
		else:
			for item in heal_numbers:
				if is_instance_valid(item):
					heal_numbers.erase(item)
					item.queue_free()
			heal_number_velocity.clear()
			
	for i in range(damage_numbers.size()):
		if damage_numbers[i].position.y > 480:
			damage_numbers[i].queue_free()
			damage_numbers.remove_at(i)
			damage_number_velocity.remove_at(i)
			break

	for i in range(heal_numbers.size()):
		if heal_numbers[i].modulate.a <= 0:
			heal_numbers[i].queue_free()
			heal_numbers.remove_at(i)
			heal_number_velocity.remove_at(i)
			break
