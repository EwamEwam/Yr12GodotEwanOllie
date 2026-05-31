##The handler for changes of health in entities, uses TYPES to determine the behaviour
##[br]requires a damage TYPE, and amt parametre, fall damage requires a third parametre for the speed at point of collision
extends Node

##Damage Types include:
##[br]GENERAL_DAMAGE and GENERAL_HEAL: Use in most cases, takes all modifiers into account
##[br]MAGIC_DAMAGE: Ignores defence but special modifiers still affect it
##[br]FALL_DAMAGE: Takes the speed upon into account, affected by certain modifiers
##[br]FORCED_DAMAGE and FORCED_HEAL: Forces a change in hp no matter current modifers and status effects
##[br]INCREMENTAL_PIERCE and INCREMENTAL_NO_PIERCE: A special type that doesn't show any effect on the player model or HUD
##[br]PIERCE determines whether it can pierce through defense and modifiers.
enum TYPES {GENERAL_DAMAGE,GENERAL_HEAL,MAGIC_DAMAGE,FALL_DAMAGE,FORCED_DAMAGE,FORCED_HEAL,INCREMENTAL_PIERCE,INCREMENTAL_NO_PIERCE}

##Determines what damage types get Player Model and HUD feedback
const SHOWS_PARTICLES = [TYPES.GENERAL_DAMAGE,TYPES.MAGIC_DAMAGE,TYPES.GENERAL_HEAL,TYPES.FALL_DAMAGE,TYPES.FORCED_DAMAGE,TYPES.FORCED_HEAL]

##Function used to handle damage events, assumes all entities have the change_in_health function.
##Requires three parametres, except fall damage, that requires four (amt = 0 in that case).
func handle(object :Object, type :TYPES = TYPES.GENERAL_DAMAGE, amt :float = 0, fall_speed :float = 0.0) -> void:
	if object != Playerstats.player:
		match type:
			TYPES.GENERAL_DAMAGE:
				amt *= object.incoming_damage_modifier
				amt /= (1+(object.defense/20))
			TYPES.GENERAL_HEAL:
				amt *= object.incoming_heal_modifier
			TYPES.FALL_DAMAGE:
				var damage_from_fall_speed :float = (fall_speed-object.safe_falling_speed) * 2 * object.fall_damage_modifier
				if damage_from_fall_speed > 1:
					amt = damage_from_fall_speed
			TYPES.MAGIC_DAMAGE:
				amt *= object.incoming_damage_modifier
			TYPES.FORCED_DAMAGE:
				DeveloperSettings.add_log("Amount of {amt} hp change to {object}".format({"amt": amt,"object": str(object)}))
			TYPES.INCREMENTAL_NO_PIERCE:
				amt *= object.incoming_damage_modifier
				amt /= (1+(object.defense/20))
	else:
		match type:
			TYPES.GENERAL_DAMAGE:
				amt *= Playerstats.incoming_damage_modifier
				amt /= (1+(Playerstats.defense/20))
			TYPES.GENERAL_HEAL:
				amt *= Playerstats.incoming_heal_modifier
			TYPES.FALL_DAMAGE:
				var damage_from_fall_speed :float = (fall_speed-Playerstats.safe_falling_speed) * 2 * Playerstats.fall_damage_modifier
				if damage_from_fall_speed <= -1:
					amt = damage_from_fall_speed
			TYPES.MAGIC_DAMAGE:
				amt *= Playerstats.incoming_damage_modifier
			TYPES.FORCED_DAMAGE:
				DeveloperSettings.add_log("Amount of {amt} hp change to {object}".format({"amt": amt,"object": str(Playerstats)}))
			TYPES.INCREMENTAL_NO_PIERCE:
				amt *= Playerstats.incoming_damage_modifier
				amt /= (1+(Playerstats.defense/20))
		
	object.change_in_health(amt,type in SHOWS_PARTICLES)
