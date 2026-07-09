##The entity class is used for enemies that can take, handle, and deal damage.
##[br]Basic friendly NPCs that use dialogue and flags use the NPC class
##[br]And NPC's that require BOTH enemy AI and dialogue use the entity_NPC class
extends CharacterBody3D

class_name entity

enum AI_type {NONE, FOLLOW, WANDER, CUSTOM}

@export var entity_type :EntityData.BaseEntites = EntityData.BaseEntites.BASIC
@export var health :float = 25
@export var max_health :float = 25

@export var attack_strength :float = 3.0
@export var defense :float = 0.0
@export var safe_falling_speed :float = -10.0
@export var incoming_damage_modifier :float = 1.0
@export var incoming_heal_modifier :float = 1.0
@export var fall_damage_modifier :float = 1.0

@export var entity_AI :AI_type = AI_type.NONE

@onready var world :Object = get_node('/root/World')
@onready var world_space :SubViewport = get_node('/root/World/SubViewportContainer/SubViewport')

signal health_updated(change :float)
signal entity_dead

func _physics_process(_delta: float) -> void:
	health = clampf(health, 0, max_health)

func change_in_health(amt :float = 0, show_particles :bool = true):
	health += amt
	if show_particles and abs(amt) >= 1:
		var number :PackedScene = load("res://Scenes/Characters/number.tscn")
		var new_number :Label3D = number.instantiate()
		new_number.create("Enemy_Damage",str(int(round(amt))),global_position)
		world_space.add_child(new_number)
		emit_signal("health_updated",amt)
	if health <= 0:
		death()
		
func death():
	emit_signal("entity_dead")
