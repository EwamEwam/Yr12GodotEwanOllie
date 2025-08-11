extends Control

var opened :bool = false
var last_mouse_position :Vector2 = Vector2.ZERO

const button :Resource = preload("res://Scenes/Misc/button.tscn")

func _ready() -> void:
	last_mouse_position = Vector2(get_viewport().get_texture().get_size()/2)

func _process(_delta :float) -> void:
	if opened:
		$Inventory_panel/Mass.text = str(round(Playerstats.inventory_mass*10)/10) + "/" + (str(Playerstats.max_inventory))
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("E"):
		if not opened and Playerstats.object_held == null:
			Playerstats.current_state = Playerstats.game_states.PAUSED
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			visible = true
			opened = true
			if len(Playerstats.organised_inventory) == 0:
				var label = Label.new()
				label.text = "Nothing..."
				$Inventory_panel/ScrollContainer/VBoxContainer.add_child(label)
			else:
				make_buttons()
			warp_mouse(last_mouse_position)
		elif opened:
			close()
		
func update(ID) -> void:
	Playerstats.inventory.erase(ID)
	Playerstats.organise_inventory()
	close()
	Playerstats.player.load_item_from_inventory(ID)
	
func close() -> void:
	Playerstats.current_state = Playerstats.game_states.PLAYING
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	opened = false
	get_tree().paused = false
	last_mouse_position = get_local_mouse_position()
	visible = false
	for nodes in $Inventory_panel/ScrollContainer/VBoxContainer.get_children():
		nodes.queue_free()
		
func make_buttons() -> void:
	if len(Playerstats.organised_inventory) > 0:
		for item in Playerstats.organised_inventory:
			var button_node = button.instantiate()
			button_node.ID = item
			if Playerstats.organised_inventory[str(item)] > 1:
				button_node.text = str(ItemData.itemdata[str(item)]["Name"]) + " X" + str(Playerstats.organised_inventory[str(item)]) + "\n" +  str(Playerstats.organised_inventory[str(item)] * ItemData.itemdata[item]["Mass"]) + "Kg (" + str(Playerstats.organised_inventory[str(item)]) + " X " + str(ItemData.itemdata[item]["Mass"]) + "Kg)"    
			else:
				button_node.text = str(ItemData.itemdata[str(item)]["Name"]) + " X" + str(Playerstats.organised_inventory[str(item)]) + "\n" +  str(Playerstats.organised_inventory[str(item)] * ItemData.itemdata[item]["Mass"]) + "Kg"    
			var path = "res://Assets/Sprites/Item_Icons/" + str(item) + ".png"
			button_node.icon = load(path)
			$Inventory_panel/ScrollContainer/VBoxContainer.add_child(button_node)
