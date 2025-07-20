extends Button

var ID :int = 0

@onready var inventory = get_node("/root/World/HUD/Inventory")
const tooltip :Resource = preload("res://Scenes/Misc/tooltip.tscn")
var current_tooltip :NinePatchRect = null

func _on_pressed() -> void:
	inventory.update(ID)
	
func _on_mouse_entered() -> void:
	if current_tooltip == null:
		var new_tooltip = tooltip.instantiate()
		new_tooltip.create_text(ItemData.itemdata[str(ID)]["Tooltip"])
		current_tooltip = new_tooltip
		inventory.add_child(new_tooltip)
	
func _on_mouse_exited() -> void:
	current_tooltip.queue_free()
	current_tooltip = null
