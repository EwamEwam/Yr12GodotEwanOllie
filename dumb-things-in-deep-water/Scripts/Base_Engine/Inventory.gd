extends Node

var inventory :Array[ItemResource] = Playerstats.inventory
@onready var prop_node :Node3D = get_node("/root/World/SubViewportContainer/SubViewport/Props")

func save_item(item :ItemResource) -> void:
	inventory.append(item)
	Playerstats.inventory_mass += item.Mass
	
func load_item(item_slot :int) -> void:
	var resource :ItemResource = inventory[item_slot]
	var object :Object = load(ItemData.itemdata[resource.Item_ID]["Path"])
	var new_object :Prop = object.instantiate()
	prop_node.add_child(new_object)
	new_object.global_position = Playerstats.player.hand.global_position
	Playerstats.object_held = new_object.body
	new_object.rotation = Playerstats.player.mesh.rotation + new_object.pick_up_rotation
	new_object.first_time_loaded = false
	Playerstats.inventory_mass -= round(new_object.body.mass * 10) / 10
