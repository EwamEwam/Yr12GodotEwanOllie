extends Resource

class_name PropResource

enum Types {OBJECT, DATA}
var type :Types = Types.DATA

var object :Prop = null

var ID :int = 0
var position :Vector3 = Vector3(0,0,0)
var rotation :Vector3 = Vector3(0,0,0)
var body_position :Vector3 = Vector3(0,0,0)
var body_rotation :Vector3 = Vector3(0,0,0)
var linear_velocity :Vector3 = Vector3(0,0,0)
var angular_velocity :Vector3 = Vector3(0,0,0)

var attribute :bool = false
var max_speed :float = 60.0
var item_resource :ItemResource = null

func create_prop_resource_from_object(prop :Prop) -> void:
	type = Types.OBJECT
	object = prop
	
func create_prop_resource_from_data(id:int, Item_Resource :ItemResource,  Position :Vector3 = Vector3.ZERO, Rotation :Vector3 = Vector3.ZERO,
Body_position :Vector3 = Vector3.ZERO, Body_rotation :Vector3 = Vector3.ZERO , Linear_Velocity :Vector3 = Vector3.ZERO, Angular_velocity :Vector3 = Vector3.ZERO,
Attribute :bool = false, Max_Speed :float = 60.0) -> void:
	ID = id
	body_position = Body_position
	body_rotation = Body_rotation
	position = Position
	rotation = Rotation
	linear_velocity = Linear_Velocity
	angular_velocity = Angular_velocity
	attribute = Attribute
	max_speed = Max_Speed
	item_resource = Item_Resource
	type = Types.DATA
	
func return_object() -> Prop:
	return object
