extends Node2D

@onready var reticle :Sprite2D = $Reticule
@onready var throw_bar :ProgressBar = $Throw_Bar
@onready var player :CharacterBody3D = get_node('/root/Main/SubViewportContainer/SubViewport/Player')

func _process(_delta: float) -> void:
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
		$Item_Description/Holding.text = str(ItemData.itemdata[str(Playerstats.object_ID)]["Name"])
		$Item_Description/Holding.position = Vector2(-265,-235)
		$Item_Description/Weight.visible = true
		$Item_Description/Holding.size = Vector2(1,1)
		$Item_Description/Weight.text = "(" + str(Playerstats.object_mass) + "Kg)"
		$Item_Description/TextEnder.visible = true
		$Item_Description/Object_Icons.visible = true
		if str(Playerstats.object_ID) in $Item_Description/Object_Icons.sprite_frames.get_animation_names():
			$Item_Description/Object_Icons.play(str(Playerstats.object_ID))
		else:
			$Item_Description/Object_Icons.play("error")
	
		
	$Item_Description/Line.size.x = round($Item_Description/Holding.size.x /(4.0/3.0)) + 3
	$Item_Description/TextEnder.position.x = -260 + ($Item_Description/Line.size.x * 2)
		
	$Hp.text = str(int(ceil(Playerstats.health))) + "/" + str(int(Playerstats.max_health))
	$Oxygen.text =  "Oxygen: " + str(int(Playerstats.oxygen)) + "%"
