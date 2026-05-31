##the script with all VITAL variables and settings for the player
##[br]It's an autoloaded and global script that anything can access
##[br]It's vital that this script is used for anything concerning the player entity
extends Node

enum game_states {PLAYING,PAUSED,MENU}
enum camera_states {CLOSE,NORMAL,OUTWARDS,FIRST}

var current_state :game_states = game_states.PLAYING
var current_camera :camera_states = camera_states.NORMAL
var lock_mouse :bool = true

var sensitivity :float = 0.4
var aiming_sensitivity :float = 0.25
var screen_factor :float = 1.0
var shift_lock :bool = false
var show_prompts :bool = true
var allow_water_effects :bool = true
var allow_camera_jerk :bool = true
var post_processing :bool = true
var Add_world_environment :bool = true
var FOV :float = 80

var max_health :float = 300.0
var strength :float = 3.0
var max_carry_weight :float = 50.0
var max_inventory :float = 50.0
var safe_falling_speed :float = -30.0
var defense :float = 5.0
var incoming_damage_modifier :float = 1.0
var incoming_heal_modifier :float = 1.0
var fall_damage_modifier :float = 0.75

var health :float = 300.0
var max_stamina :float = 8.0
var oxygen :float = 100.0
var stamina :float = 8.0
var inventory_mass :float = 0.0
var inventory :Array[int] = []
var organised_inventory :Dictionary = {}

var object_detected :Object = null
var object_ID :int = 0
var object_held :Object = null
var object_mass :float = 0.0
var object_properties :Array = []
var object_prompts :Array = []

#var head_hp :float = 125.0
#var torso_hp :float = 125.0
#var legs_hp :float = 125.0
#var arms_hp :float = 125.0

var invincibility :bool = false
var regen :bool = true
var sprint_key :bool = false
var time_since_last_damage :float = 0.0
var next_health_regen :float = 0.0
var oxygen_depletes :bool = false
var can_regen :bool = false

var time_played :int = 0

var head_bobbing :bool = true

var camera_hitbox :bool = true
var no_clip :bool = true
var show_collision_checks :bool = false
var infinte_inventory :bool = false
var saved_inventory :Array[int] = []

#For the pain in the ass that is using the same button to pause and resume.
var escape_pressed :bool = false
var pause_menu_open :bool = false

var ammo :Dictionary = { 
	"Pistol" = [0,28],
	"Revolver" = [0,0],
	"Shotgun" = [0,0],
	"UZI" = [0,0],
}

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var world = get_node('/root/World')

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func clear_stat() -> void:
	health = max_health
	oxygen = 100
	stamina = max_stamina
	inventory = saved_inventory
	inventory_mass = get_mass_of_inventory(saved_inventory)
	object_held = null
	object_ID = 0
	object_mass = 0
	object_prompts = []
	object_properties = []

	#head_hp = 125.0
	#torso_hp = 125.0
	#legs_hp = 125.0
	#arms_hp = 125.0
	
func _process(delta :float) -> void:
	var screen_size :Vector2i = DisplayServer.window_get_size()
	screen_factor = get_largest_4_3_viewport(screen_size).length()/2431.4
	
	oxygen = clamp(oxygen,0,100)
	health = clamp(health,0,max_health)
	stamina = clamp(stamina,0,max_stamina)
	
	#head_hp = clamp(head_hp,0,max_health)
	#torso_hp = clamp(torso_hp,0,max_health)
	#legs_hp = clamp(legs_hp,0,max_health)
	#arms_hp = clamp(arms_hp,0,max_health)
	#
	#if head_hp <= 0 or torso_hp <= 0: health = 0
		
	if health <= 0: get_tree().quit()
		
	if get_tree().paused == false: time_since_last_damage = min(time_since_last_damage + delta, 60)
	
	can_regen = health < max_health 
	
	if regen and can_regen and current_state == game_states.PLAYING: 
		next_health_regen += (time_since_last_damage/60)*(delta/2)
		if next_health_regen >= 0.25:
			ChangeInHealthManager.handle(player, ChangeInHealthManager.TYPES.INCREMENTAL_PIERCE, 0.25)
			health = clamp(health,0,max_health)
			#torso_hp = min(torso_hp + 0.25,max_health)
			#head_hp = min(head_hp + 0.25,max_health)
			#legs_hp = min(legs_hp + 0.25,max_health)
			#arms_hp = min(arms_hp + 0.25,max_health)
			next_health_regen = 0.0
			
	if oxygen <= 0 and current_state == game_states.PLAYING:
		ChangeInHealthManager.handle(player, ChangeInHealthManager.TYPES.INCREMENTAL_PIERCE, 10 * delta)
		
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
			
func get_mass_of_inventory(input :Array[int]) -> float:
	var mass: float = 0
	for item in input:
		mass += ItemData.itemdata[str(item)]["Mass"] 
	return mass
			
func get_largest_4_3_viewport(window_size: Vector2i) -> Vector2i:
	@warning_ignore("integer_division")
	var width_based_height :int = int(window_size.x * 3/4)
	if width_based_height <= window_size.y:
		return Vector2i(window_size.x, width_based_height)

	@warning_ignore("integer_division")
	var height_based_width :int = int(window_size.y * 4/3)
	return Vector2i(height_based_width, window_size.y)
