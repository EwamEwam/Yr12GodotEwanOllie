##The primary way to store an item's logic data (most important are components).
##[br]Physical components isn't stored here though, that requires Prop_Resource.
extends Resource

class_name ItemResource

@export var Item_ID :int = 0
@export var Component :Dictionary = {}
@export var Mass :float = 1.0

##Run this when an ItemResource is created and feed it the prop node itself
##[br]This stores the prop's Item_ID, Mass, AND Components
func create_item(object :Prop) -> void: 
	Component = object.components
	Mass = object.body.mass
	Item_ID = object.ID
	
##Run this when an item must be 
func recreate_object() -> Array:
	return[Item_ID, Component, Mass]
