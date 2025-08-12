extends Node

enum game_states {PLAYING,PAUSED,MENU}
enum camera_states {CLOSE,NORMAL,OUTWARDS,FIRST}
var current_state :game_states = game_states.PLAYING
var current_camera :camera_states = camera_states.NORMAL

var sensitivity :float = 0.4
var aiming_sensitivity :float = 0.25
var screen_factor :float = 1.0
var shift_lock :bool = false
var allow_shaking :bool = true
var show_prompts :bool = true

var max_health :float = 25.0
var strength :float = 1.0
var max_carry_weight :float = 50.0
var max_inventory :float = 5.0

var health :float = 25.0
var oxygen :float = 100.0
var special :float = 100.0
var inventory_mass :float = 0.0
var inventory :Array[int] = []
var organised_inventory :Dictionary = {}

var object_detected :Object = null
var object_ID :int = 0
var object_held :Object = null
var object_mass :float = 0.0
var object_properties :Array = []
var object_prompts :Array = []

var head_hp :float = 125.0
var torso_hp :float = 125.0
var legs_hp :float = 125.0
var arms_hp :float = 125.0

var invincibility :bool = false
var regen :bool = true
var sprint_key :bool = false
var time_since_last_damage :float = 0.0
var next_health_regen :float = 0.0

var time_played :int = 0

var head_bobbing :bool = true

var ammo :Dictionary = { 
	"Pistol" = [14,28],
	"Revolver" = [0,0],
	"Shotgun" = [0,0],
	"UZI" = [0,0],
}

@onready var player = get_tree().get_first_node_in_group("Player")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta :float) -> void:
	var screen_size :Vector2i = DisplayServer.window_get_size()
	screen_factor = get_largest_4_3_viewport(screen_size).length()/2431.4
	
	oxygen = clamp(oxygen,0,100)
	health = clamp(health,0,max_health)
	
	head_hp = clamp(head_hp,0,max_health)
	torso_hp = clamp(torso_hp,0,max_health)
	legs_hp = clamp(legs_hp,0,max_health)
	arms_hp = clamp(arms_hp,0,max_health)
	
	if head_hp <= 0 or torso_hp <= 0:
		health = 0
		
	if health <= 0:
		get_tree().quit()
		
	time_since_last_damage = min(time_since_last_damage + delta, 60)
		
	if regen and health < max_health and current_state == game_states.PLAYING: 
		next_health_regen += (time_since_last_damage/60)*(delta/2)
		if next_health_regen >= 0.25:
			player.change_in_health(0.25,false) 
			health = clamp(health,0,max_health)
			torso_hp = min(torso_hp + 0.25,max_health)
			head_hp = min(head_hp + 0.25,max_health)
			legs_hp = min(legs_hp + 0.25,max_health)
			arms_hp = min(arms_hp + 0.25,max_health)
			next_health_regen = 0.0
			
	if oxygen <= 0 and current_state == game_states.PLAYING:
		player.change_in_health(-delta*6,false)
		
	organise_inventory()
		
func organise_inventory():
	organised_inventory = {}
	var sorted :Array[int] = inventory.duplicate(); sorted.sort()
	for item in sorted:
		if str(item) in organised_inventory:
			organised_inventory[str(item)] += 1
		else:
			organised_inventory.get_or_add(str(item))
			organised_inventory[str(item)] = 1
			
func get_largest_4_3_viewport(window_size: Vector2i) -> Vector2i:
	@warning_ignore("integer_division")
	var width_based_height :int = int(window_size.x * 3 / 4)
	if width_based_height <= window_size.y:
		return Vector2i(window_size.x, width_based_height)

	@warning_ignore("integer_division")
	var height_based_width = int(window_size.y * 4 / 3)
	return Vector2i(height_based_width, window_size.y)
