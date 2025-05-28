extends Marker3D

@export var ID :int = 1
@export var pick_up_position :Vector3 = Vector3.ZERO
@export var pick_up_rotation :Vector3 = Vector3.ZERO
@onready var body :RigidBody3D = $Body
@onready var model :MeshInstance3D = $Body/Model
@onready var outline :MeshInstance3D = $Body/Model/Outline
@onready var collision :CollisionShape3D = $Body/Collision
@onready var onscreen :VisibleOnScreenNotifier3D = $Body/Onscreen

func _ready():
	set_props()
	
func set_props():
	var data :Dictionary = ItemData.itemdata[str(ID)]
	body.mass = data["Mass"]
	model.mesh = load(data["Model"])
	outline.mesh = load(data["Outline"])
	if data.has("Collision"):
		collision.shape = load(data["Collision"])
