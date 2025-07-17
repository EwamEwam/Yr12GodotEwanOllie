extends Node2D

@onready var reticle :Sprite2D = $Reticule
@onready var throw_bar :ProgressBar = $Throw_Bar
@onready var player :CharacterBody3D = Playerstats.player

var level_time :int = 0
var formatted_time :Vector2i = Vector2i(0,0)
var alerts :Array[Node] = []

func _ready() -> void:
	$Health_bar/Health_Bar.value = Playerstats.health
	$Health_bar/HealthBarEnd.position.x = (3 * Playerstats.max_health) + 121.5

func _process(_delta: float) -> void:
	reticle.modulate.a = 0.2
	if player.movement_state != player.movement_states.NORMAL:
		reticle.modulate.a = 1

	if player.movement_state == player.movement_states.THROWING:
		throw_bar.visible = true
		throw_bar.value = player.throw_power
	else:
		throw_bar.visible = false
		
	$Health_bar/Oxygen_Bar.value = Playerstats.oxygen
	
	if Playerstats.object_held == null:
		$Item_Description/Holding.text = "Nothing"
		$Item_Description/Holding.position = Vector2(-265,-226)
		$Item_Description/Holding.size = Vector2(1,1)
		$Item_Description/Weight.visible = false
		$Item_Description/TextEnder.visible = false
		$Item_Description/Object_Icons.play("error")
		$Item_Description/Object_Icons.visible = false
	else:
		$Item_Description/Holding.text = str(ItemData.itemdata[str(Playerstats.object_ID)]["Name"])
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
		
	$Health_bar/Hp.text = str(int(ceil(Playerstats.health))) + "/" + str(int(Playerstats.max_health))
	
	$Health_bar/Health_Bar_Background.value = Playerstats.max_health + 38
	$Health_bar/HealthBarEnd.position.x = (3 * Playerstats.max_health) + 121.5
	$Health_bar/Hp.position.x = (Playerstats.max_health * 3) + 130
	$Health_bar/Oxygen.text = str(int(ceil(Playerstats.oxygen))) + "%"
	
	for text in alerts:
		text.position.y = 82 + (25*alerts.find(text))

func shake_part(body_part :String) -> void:
	var part :Sprite2D
	var Body_part_hp :float
	Body_part_hp = clamp(Body_part_hp,0,Playerstats.max_health)
	match body_part:
		"Head":
			part = $Health_bar/BodyPartHead
			Body_part_hp = Playerstats.head_hp
		"Torso":
			part = $Health_bar/BodyPartTorso
			Body_part_hp = Playerstats.torso_hp
		"Legs":
			part = $Health_bar/BodyPartLegs
			Body_part_hp = Playerstats.legs_hp
		"Arms":
			part = $Health_bar/BodyPartArms
			Body_part_hp = Playerstats.arms_hp
			
	var tween :Tween = get_tree().create_tween()
	var color: float = (Playerstats.max_health - Body_part_hp)/Playerstats.max_health
	part.modulate = Color.from_hsv(0,color,1,1)
	tween.tween_property(part, "scale", Vector2(1.75,3.5) , 0.025).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	var tween2 :Tween = get_tree().create_tween()
	tween2.tween_property(part, "scale", Vector2(3.5,1.75) , 0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween2.finished
	var tween3 :Tween = get_tree().create_tween()
	tween3.tween_property(part, "scale", Vector2(3,3) , 0.025).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func health_bar_animation(before :float) -> void:
	var tween :Tween = get_tree().create_tween()
	var tween2 :Tween = get_tree().create_tween()
	var texture :ColorRect = ColorRect.new()
	tween.tween_property($Health_bar/Health_Bar, "value", Playerstats.health, abs($Health_bar/Health_Bar.value-Playerstats.health)/200).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	texture.position = Vector2(117,447)
	texture.color = Color(1,1,1,1)
	texture.scale = Vector2(3,3)
	texture.size = Vector2(before,5)
	texture.z_index = -1
	$Health_bar.add_child(texture)
	tween2.tween_property(texture, "modulate", Color(1,1,1,0), 0.75).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	$Health_bar/Health_Bar.value = Playerstats.health
	await tween2.finished
	texture.queue_free()
	
func update_health_bar() -> void:
	$Health_bar/Health_Bar.value = Playerstats.health
	
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

func alert(text: String) -> void:
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
	add_child(text_box)
	var tween1 :Tween = get_tree().create_tween()
	tween1.tween_property(text_box,"position",Vector2(-6,57+(25*alerts.size())),0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1).timeout
	var tween2 :Tween = get_tree().create_tween()
	tween2.tween_property(text_box,"modulate",Color(1,1,1,0),2).set_trans(Tween.TRANS_LINEAR)
	await tween2.finished
	if is_instance_valid(text_box):
		text_box.queue_free()
		alerts.erase(text_box)
