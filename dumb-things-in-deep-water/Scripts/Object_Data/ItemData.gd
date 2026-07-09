extends Node

##Each prop in the game can be assigned a property, each one changing how the prop interacts with the environment and player
##[br]ID_UPDATE: When used, increases the ID of the object by 1 and reloads it
##[br]HEAL: Heals the player a specified amount
##[br]DELETE: Deletes itself after use
##[br]AIM: Right click puts the player into aiming stance instead of dropping the object
##[br]CANT_DROP_THROW: Disables the ability to throw or drop the object
##[br]SHOOT: Creates a specified bullet when the player uses it while in aim stance. 
##[br]GUN_TYPE: Just specifies what type of gun the player has
##[br]TV: Plays and projects a video file onto a mesh within the model
##[br]ATTRIBUTE_UPDATE: Toggles the attribute parameter after all the other properties have played out
##[br]SPEAKER: Plays a audio file in the 3d environment
##[br]PAINTING: Prop has a raycast to align to the normal of a adjacent wall, then freezes.
enum Properties {ID_UPDATE,HEAL, DAMAGE, DELETE,AIM,CANT_DROP_THROW,SHOOT,TV,ATTRIBUTE_UPDATE, SPEAKER, PAINTING,
TRIGGER, BREAKABLE, BURNABLE, PROP_DAMAGE_MULTIPLIER, SPAWN_OBJECT, OVERRIDE, OVERRIDE_2, OVERRIDE_3, OVERRIDE_4,
RESET_COMPONENTS_TO_DEFAULT, RANDOM}

##Behaviours are run from triggers. They run a specfic function when a trigger has been fired. They are essentially the event system for basic items.
##[br] - HEAL: inherits data from [member Properties.HEAL]. heal's the user of the item by 
##[br]      Properties.HEAL["Value"]
##[br] - DELETE: deletes the object from the world, including its itemdata.
##[br] - SPAWN_OBJECT: inherits data from [member Properties.SPAWN_OBJECT]. It's spawn an item
##[br]      using an ID based off Properties.SPAWN_OBJECT["Object_ID"], it then spawns the 
##[br]      item relative to the object (If properties.SPAWN_OBJECT["Relative_Position"]
##[br]      is provided), or global position (if Properties.SPAWN_OBJECT["Global_Position"]) 
##[br]      is provided. The same applies to properties.SPAWN_OBJECT["Relative_Rotation"],
##[br]      and properties.SPAWN_OBJECT["Global_Rotation"]. Starting linear and angular
##[br]      velocity is given by ["Linear_velocity"] and ["Angular_velocity"].
##[br]      Then an optional Properties.SPAWN_OBJECT["Component_Override"] can be
##[br]      provided, which overides the components of the new item.
##[br] - ATTRIBUTE_UPDATE: Toggles the attribute from on or off.
##[br] - OVERRIDE_COMPONENTS: inherits data from [member Properies.OVERRIDE]. Overrides the
##[br]      entire component dictionary, by essentially setting the components dictionary to 
##[br]      Properties.
##[br] - RESET_COMPONENTS_TO_DEFAULT: Resets ALL the components back to the ones defined
##[br]      in the itemdata dictionary.
##[br] - DROP: Drops the item.
enum Behaviour {HEAL, HEAL_CONTACTED, DAMAGE, DAMAGE_CONTACTED, DELETE, SPAWN_OBJECT, ATTRIBUTE_UPDATE, OVERRIDE, OVERRIDE_2, OVERRIDE_3, OVERRIDE_4, RESET_COMPONENTS_TO_DEFAULT, DROP, ID_UPDATE,
RANDOM}

enum Triggers {HIT_GEOMETRY, HIT_SPECIFIC_GEOMETRY, HIT_ENTITY, HIT_SPECIFIC_ENTITY, FOR_ENTITY_TOUCHED, FOR_ENTITY_SPECIFIC_TOUCHED, FOR_GEOMETRY_TOUCHED, FOR_GEOMETRY_SPECIFIC_TOUCHED, ON_PROPERTY_THRESHOLD, FOR_PROPERTY_THRESHOLD, ON_BUTTON_PRESSED, ON_TIME_PASSED, ON_TICK, ON_SPAWN_FIRST_TIME, ON_GRAB, ON_DROP, ON_THROW, ON_LOAD_FROM_INVENTORY}

enum Prompts {OPEN,HEAL,AIM,SHOOT,TOGGLE,EAT}
enum Materials {DEFAULT, WOOD, GLASS, PLASTIC, METAL, CUSTOM}

##the text display system (tooltip edition) in the game. Has 5 different types/commands. 
##[br]Text is to be written as an array with the [text_type,Color,String of text,Parameter1,Parameter2...]
##[br]Commands are to be written as [text_type,parameter1,parameter2...]
##[br]STANDARD: instantly displays the text in the colour described.
##[br]TYPE_OUT: Writes out the text by typing it out character by character. parameter one is the delay, parameter two is the amount of characters it should instantly type out, can be left out.
##[br]TIMER: Delays for a set amount of time, as set by parameter one.
##[br]RESET: Clears ALL text.
##[br]EDIT: Edits a previous instance of text, based on the order that one created, starts at index 0, parameter one is the index of the array that should be accessed.
enum Text_Type {STANDARD,TYPE_OUT,TIMER,RESET,EDIT}

#A dictionary used to store all the audio paths used depending on an object's Materials. Properly could of just directly
#Added this into the item data dictionary for each object but oh well, at least this is more readable and easier to understand.
const Audio_Bank :Dictionary = {
	Materials.DEFAULT: ["res://Assets/Videos_and_Audio/Default_hit_1.mp3"],
	Materials.METAL: ["res://Assets/Videos_and_Audio/Metal_hit_1.mp3"],
}

#A dictionary holding all of the item data in the game, this includes the name, the path, the model and outline model, the mass,
#If object is breakable, any special properties, the object's prompts on the HUD, the material and the tooltip in the inventory.
#It works on an ID system where each prop is given an integer, it reads off here and then it's off to the races.
const itemdata :Dictionary[int,Dictionary] = {
	0: {
		"Name": "Error",
		"Path": "res://Scenes/Props/Placeholder(1).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/1_Placeholder_Model.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/1_Placeholder_Outline.tres",
		"Mass": 0.1,
		"Prompts": [],
		"Select_Sound": null,
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1.0, 0.26, 0.26, 1.0),"You Should NOT have this in\nyour inventory."]],
		"Components": {}
	},
	1: {
		"Name": "Placeholder",
		"Path": "res://Scenes/Props/Placeholder(1).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/1_Placeholder_Model.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/1_Placeholder_Outline.tres",
		"Mass": 1.0,
		"Prompts": [Prompts.EAT],
		"Select_Sound": null,
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1,1),"Just a standard box"]],
		"Components": {
			Properties.HEAL: {
				"Value": 10,
				"Range": 2,
				"Type": ChangeInHealthManager.TYPES.GENERAL_HEAL
			},
			Properties.DAMAGE: {
				"Value": 12,
				"Range": 3,
				"Type": ChangeInHealthManager.TYPES.INCREMENTAL_PIERCE
			},
			Properties.BREAKABLE: {
				"Health": 100,
				"Regen": true,
				"Regen_rate": 0.0167,
			},
			Properties.BURNABLE: {
				"Burn_time": 10,
				"Regen": true,
				"Regen_rate": 0.0167,
			},
			Properties.PROP_DAMAGE_MULTIPLIER: {
				"Value": 1,
				"Modifiers": [EntityData.BaseEntites.PLAYER],
				"Modified_value": 2,
			},
			Properties.SPAWN_OBJECT: {
				"Object_ID" = 7,
				"Relative_position" = Vector3(0,4,0)
			},
			Properties.TRIGGER: [{
					"Trigger": Triggers.ON_BUTTON_PRESSED,
					"Button_pressed": "Left_Click",
					"Reaction": [Behaviour.HEAL, Behaviour.DELETE],
				},{
					"Trigger": Triggers.HIT_GEOMETRY,
					"Minimum_velocity": 1,
					"Reaction": [Behaviour.SPAWN_OBJECT]
				},{
					"Trigger": Triggers.ON_TICK,
					"Interval": 180,
					"Reaction": [Behaviour.DAMAGE]
				}]
		}
	},
	2: {
		"Name": "White Cyclinder",
		"Path": "res://Scenes/Props/White_Cyclinder(2).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder_Outline.tres",
		"Mass": 50.0,
		"Prompts": [],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"Unbeknownst to the naked eye,\nthis is nothing more than a simple\nwhite cyclinder."]],
		"Components": {}
	},
	3: {
		"Name": "Can - Closed",
		"Path": "res://Scenes/Props/Can_Closed(3).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/3_Can_Closed.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/3_Can_Closed_Outline.tres",
		"Mass": 0.3,
		"Prompts": [Prompts.OPEN],
		"Material": Materials.METAL,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"A basic can, press left click\nwhile holding to open."]],
		"Components": {
			Properties.ID_UPDATE: {
				"Value" = 4,
				"Reload" = false
			},
			Properties.TRIGGER: [{
				"Trigger": Triggers.ON_BUTTON_PRESSED,
				"Button_pressed": "Left_Click",
				"Reaction": [Behaviour.ID_UPDATE],
			}]
		}
	},
	4: {
		"Name": "Can - Opened",
		"Path": "res://Scenes/Props/Can_Opened(4).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/4_Can_Opened.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/4_Can_Opened_Outline.tres",
		"Collision": "res://Assets/Props_Models_And_Collisions/4_Can_Full_Collision.tres",
		"Mass": 0.3,
		"Prompts": [Prompts.EAT],
		"Material": Materials.METAL,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"Press left click while holding\nto consume to heal 5 HP."]],
	},
	5: {
		"Name": "Can - Half Full",
		"Path": "res://Scenes/Props/Can_Half_Full(5).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/5_Can_Half_Full.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/5_Can_Half_Full_Outline.tres",
		"Collision": "res://Assets/Props_Models_And_Collisions/4_Can_Full_Collision.tres",
		"Mass": 0.2,
		"Breakable": false,
		"Value": 5,
		"Properties": [Properties.HEAL,Properties.ID_UPDATE],
		"Prompts": [Prompts.EAT],
		"Material": Materials.METAL,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"Half full (or empty for you\npessimists), press left click to\nconsume to heal 5 HP."]],
	},
	6: {
		"Name": "Can - Empty",
		"Path": "res://Scenes/Props/Can_Empty(6).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/6_Can_Empty.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/6_Can_Empty_Outline.tres",
		"Collision": "res://Assets/Props_Models_And_Collisions/4_Can_Full_Collision.tres",
		"Mass": 0.1,
		"Breakable": false,
		"Properties": [],
		"Prompts": [],
		"Material": Materials.METAL,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"It's empty..."]],
	},
	7: {
		"Name": "Healing Item",
		"Path": "res://Scenes/Props/Basic_Healing(7).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder_Outline.tres",
		"Mass": 1.7,
		"Prompts": [Prompts.HEAL],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"A basic healing item, interact\nwith it while holding it to heal\n10 HP"]],
		"Components": {
			Properties.HEAL: {
				"Value" = 10.0
			},
			Properties.OVERRIDE: {
				"Override": {
					Properties.HEAL: {
						"Value" = 5.0
					},
				},
				"Complete_Override": false,
				"Reload": false,
			},
			Properties.TRIGGER: [{
				"Trigger": Triggers.ON_BUTTON_PRESSED,
				"Button_pressed": "Left_Click",
				"Reaction": [Behaviour.HEAL,Behaviour.DELETE],
			},{
				"Trigger": Triggers.HIT_SPECIFIC_ENTITY,
				"Entity": EntityData.BaseEntites.PLAYER,
				"Reaction": [Behaviour.OVERRIDE, Behaviour.HEAL, Behaviour.DELETE]
			}]
		}
	},
	8:{
		"Name": "TV - Barbeque Chicken Alert",
		"Path": "res://Scenes/Props/TV_Barbeque_Chicken(8).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/8_TV.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/8_TV_Outline.tres",
		"Mass": 12.6,
		"Breakable": false,
		"Video": "res://Assets/Videos_and_Audio/barbequechicken.ogv",
		"Properties": [Properties.TV],
		"Prompts": [Prompts.TOGGLE],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),'Lyrics: "Barbeque chicken\nalert. Barbeque chicken alert"']],
	},
	9: {
		"Name": "Test Gun",
		"Path": "res://Scenes/Props/Test_Gun(9).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/9_Test_Gun.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/9_Test_Gun_Outline.tres" ,
		"Mass": 0.8,
		"Breakable": false,
		"Interval": 0.1,
		"Recoil": 2,
		"Properties": [Properties.AIM,Properties.SHOOT,Properties.CANT_DROP_THROW],
		"Bullet": "res://Scenes/Misc/pistol_bullet.tscn",
		"Range": 25,
		"Prompts": [Prompts.AIM,Prompts.SHOOT],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"Bang bang mother fluffa, this\nhandy dandy handgun can deal\ndecent damage... As long as it is\nin the hands of a worthy user."]],
	},
	10:{
		"Name": "Speaker - Carry On",
		"Path": "res://Scenes/Props/Speaker_Carry_on(10).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/10_Speaker_Carry_on.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/10_Speaker_Carry_on_Outline.tres",
		"Mass": 5.8,
		"Breakable": false,
		"Audio": "res://Assets/Videos_and_Audio/Carryonmywaywardson.mp3",
		"Properties": [Properties.SPEAKER],
		"Prompts": [Prompts.TOGGLE],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"I love this song:)"]],
	},
	11:{
		"Name": "Painting - My Love",
		"Path": "res://Scenes/Props/Painting(11).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/11_Painting.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/11_Painting_Outline.tres",
		"Mass": 4.6,
		"Breakable": false,
		"Properties": [Properties.PAINTING],
		"Prompts": [],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"Joesph McFarland, c. 1767,\nArtist Unknown"]],
	},
	12:{
		"Name": "TV - Intro",
		"Path": "res://Scenes/Props/TV_intro(12).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/8_TV.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/8_TV_Outline.tres",
		"Mass": 12.6,
		"Breakable": false,
		"Video": "res://Assets/Videos_and_Audio/videoplayback.ogv",
		"Properties": [Properties.TV],
		"Prompts": [Prompts.TOGGLE],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"Game by Bourbon and Coke,\nand roobuc, better known\nby his stage name Passionfruit\nman."]],
	},
	14:{
		"Name": "Speaker - Radio",
		"Path": "res://Scenes/Props/Speaker_Radio(14).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/10_Speaker_Carry_on.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/10_Speaker_Carry_on_Outline.tres",
		"Mass": 5.8,
		"Breakable": false,
		"Audio": "res://Assets/Videos_and_Audio/output.mp3",
		"Properties": [Properties.SPEAKER],
		"Prompts": [Prompts.TOGGLE],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"Simply Beautiful."]],
	},
	19:{
		"Name": "dunetoris",
		"Path": "res://Scenes/Props/dunetoris(19).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/19_dunetoris.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/19_dunetoris_outline.tres",
		"Mass": 23.6,
		"Breakable": false,
		"Properties": [],
		"Prompts": [Prompts.TOGGLE],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"Put me down!"]],
	},
	20: {
		"Name": "The Package",
		"Path": "res://Scenes/Props/Package(20).tscn",
		"Model": "res://Assets/Props_Models_And_Collisions/20_The_Package.tres",
		"Outline": "res://Assets/Props_Models_And_Collisions/20_The_Package_Outline.tres",
		"Mass": 2.6,
		"Breakable": false,
		"Properties": [Properties.CANT_DROP_THROW],
		"Prompts": [],
		"Material": Materials.DEFAULT,
		"Tooltip": [[Text_Type.STANDARD,Color(1,1,1),"The oh-so-important package.\nTake special care of this because\nyou HAVE to deliver this."]],
	},
}
