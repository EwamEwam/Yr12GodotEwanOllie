extends Node

enum game_states {PLAYING,PAUSED,MENU}
enum camera_states {THIRD,FIRST}
var current_state :game_states = game_states.PLAYING
var current_camera :camera_states = camera_states.THIRD

var sensitivity :float = 0.4
var screen_factor :float = 1.0

var max_health :float = 100.0
var strength :float = 1.0
var max_carry_weight :float = 50.0
var max_inventory :float = 5.0

var health :float = 100.0
var oxygen :float = 100.0
var special :float = 100.0
var inventory_mass :float = 0.0
var inventory :Array[int] = []
var organised_inventory :Dictionary = {}

var object_detected :Object = null
var object_ID :int = 0
var object_held :Object = null
var object_mass :float = 0.0

var head_hp :float = 100.0
var torso_hp :float = 100.0
var legs_hp :float = 100.0
var arms_hp :float = 100.0

var invincibility :bool = false

var time_played :int = 0

var head_bobbing :bool = true

@onready var player = get_tree().get_first_node_in_group("Player")

func _process(_delta :float) -> void:
	#screen_factor = DisplayServer.window_get_size().length()
	oxygen = clamp(oxygen,0,100)
	health = clamp(health,0,max_health)
	
	head_hp = clamp(head_hp,0,max_health)
	torso_hp = clamp(torso_hp,0,max_health)
	legs_hp = clamp(legs_hp,0,max_health)
	arms_hp = clamp(arms_hp,0,max_health)

func organise_inventory():
	organised_inventory = {}
	var sorted = inventory.duplicate(); sorted.sort()
	for item in sorted:
		if str(item) in organised_inventory:
			organised_inventory[str(item)] += 1
		else:
			organised_inventory.get_or_add(str(item))
			organised_inventory[str(item)] = 1
