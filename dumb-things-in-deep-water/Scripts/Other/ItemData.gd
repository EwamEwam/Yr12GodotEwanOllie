extends Node

#Each prop in the game can be assigned a property, each one changing how the prop interacts with the environment and player
#ID_UPDATE: When used, increases the ID of the object by 1 and reloads it
#HEAL: Heals the player a specified amount
#DELETE: Deletes itself after use
#AIM: Right click puts the player into aiming stance instead of dropping the object
#CAN'T_DROP_THROW: Disables the ability to throw or drop the object
#SHOOT: Creates a specified bullet when the player uses it while in aim stance. 
#GUN_TYPE: Just specifies what type of gun the player has
#TV: Plays and projects a video file onto a mesh within the model
#SPEAKER: Plays a audio file in the 3d environment
#PAINTING: Prop has a raycast to align to the normal of a adjacent wall, then freezes.
enum properties {ID_UPDATE,HEAL,DELETE,AIM,CANT_DROP_THROW,SHOOT,PISTOL,SHOTGUN,UZI,REVOLVER,TV,SPEAKER,PAINTING}
enum prompts {OPEN,HEAL,AIM,SHOOT,TOGGLE,EAT}
enum materials {DEFAULT,WOOD,GLASS,PLASTIC,METAL}

#A dictionary used to store all the audio paths used depending on an object's material. Properly could of just directly
#Add this into the item data dictionary for each object but oh well, at least this is more readable and easier to understand.
const Audio_bank :Dictionary = {
	materials.DEFAULT: ["res://Assets/Videos_and_Audio/Default_hit_1.mp3"],
	materials.METAL: ["res://Assets/Videos_and_Audio/Metal_hit_1.mp3"],
}

#A dictionary holding all of the item data in the game, this includes the name, the path, the model and outline model, the mass,
#If object is breakable, any special properties, the object's prompts on the HUD, the material and the tooltip in the inventory.
#It works on an ID system where each prop is given an integer, it reads off here and then it's off to the races.
const itemdata :Dictionary = {
	"0": {
		"Name" = "Error",
		"Path" = "res://Scenes/Props/Placeholder(1).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Model.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Outline.tres",
		"Mass" = 0.1,
		"Breakable" = false,
		"Properties" = [],
		"Prompts" = [],
		"Material" = materials.DEFAULT,
		"Tooltip" = "You Should NOT have this in\nyour inventory."
	},
	"1": {
		"Name" = "Placeholder",
		"Path" = "res://Scenes/Props/Placeholder(1).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Model.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Outline.tres",
		"Mass" = 1.0,
		"Breakable" = false,
		"Properties" = [],
		"Prompts" = [],
		"Material" = materials.DEFAULT,
		"Tooltip" = "A basic blue cube, has a mass of\nexactly 1 kg to the atomic level."
	},
	"2": {
		"Name" = "White Cyclinder",
		"Path" = "res://Scenes/Props/White_Cyclinder(2).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder_Outline.tres",
		"Mass" = 50.0,
		"Breakable" = false,
		"Properties" = [], 
		"Prompts" = [],
		"Material" = materials.DEFAULT,
		"Tooltip" = "Unbeknownst to the naked eye,\nthis is nothing more than a simple\nwhite cyclinder."
	},
	"3": {
		"Name" = "Can - Closed",
		"Path" = "res://Scenes/Props/Can_Closed(3).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/3_Can_Closed.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/3_Can_Closed_Outline.tres",
		"Mass" = 0.3,
		"Breakable" = false,
		"Properties" = [properties.ID_UPDATE],
		"Prompts" = [prompts.OPEN],
		"Material" = materials.METAL,
		"Tooltip" = "A basic can, press left click\nwhile holding to open."
	},
	"4": {
		"Name" = "Can - Opened",
		"Path" = "res://Scenes/Props/Can_Opened(4).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/4_Can_Opened.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/4_Can_Opened_Outline.tres",
		"Collision" = "res://Assets/Props_Models_And_Collisions/4_Can_Full_Collision.tres",
		"Mass" = 0.3,
		"Breakable" = false,
		"Value" = 5,
		"Properties" = [properties.HEAL,properties.ID_UPDATE],
		"Prompts" = [prompts.EAT],
		"Material" = materials.METAL,
		"Tooltip" = "Press left click while holding\nto consume to heal 5 HP."
	},
	"5": {
		"Name" = "Can - Half Full",
		"Path" = "res://Scenes/Props/Can_Half_Full(5).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/5_Can_Half_Full.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/5_Can_Half_Full_Outline.tres",
		"Collision" = "res://Assets/Props_Models_And_Collisions/4_Can_Full_Collision.tres",
		"Mass" = 0.2,
		"Breakable" = false,
		"Value" = 5,
		"Properties" = [properties.HEAL,properties.ID_UPDATE],
		"Prompts" = [prompts.EAT],
		"Material" = materials.METAL,
		"Tooltip" = "Half full (or empty for you\npessimists), press left click to\nconsume to heal 5 HP."
	},
	"6": {
		"Name" = "Can - Empty",
		"Path" = "res://Scenes/Props/Can_Empty(6).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/6_Can_Empty.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/6_Can_Empty_Outline.tres",
		"Collision" = "res://Assets/Props_Models_And_Collisions/4_Can_Full_Collision.tres",
		"Mass" = 0.1,
		"Breakable" = false,
		"Properties" = [],
		"Prompts" = [],
		"Material" = materials.METAL,
		"Tooltip" = "It's empty..."
	},
	"7": {
		"Name" = "Healing Item",
		"Path" = "res://Scenes/Props/Basic_Healing(7).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder_Outline.tres",
		"Mass" = 1.7,
		"Breakable" = false,
		"Value" = 10,
		"Properties" = [properties.HEAL,properties.DELETE],
		"Prompts" = [prompts.HEAL],
		"Material" = materials.DEFAULT,
		"Tooltip" = "A basic healing item, interact\nwith it while holding it to heal\n10 HP"
	},
	"8":{
		"Name" = "TV - Barbeque Chicken Alert",
		"Path" = "res://Scenes/Props/TV_Barbeque_Chicken(8).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/8_TV.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/8_TV_Outline.tres",
		"Mass" = 12.6,
		"Breakable" = false,
		"Video" = "res://Assets/Videos_and_Audio/barbequechicken.ogv",
		"Properties" = [properties.TV],
		"Prompts" = [prompts.TOGGLE],
		"Material" = materials.DEFAULT,
		"Tooltip" = 'Lyrics: "Barbeque chicken\nalert. Barbeque chicken alert"'
	},
	"9": {
		"Name" = "Test Gun",
		"Path" = "res://Scenes/Props/Test_Gun(9).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/9_Test_Gun.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/9_Test_Gun_Outline.tres" ,
		"Mass" = 0.8,
		"Breakable" = false,
		"Interval" = 0.1,
		"Recoil" = 2,
		"Properties" = [properties.AIM,properties.SHOOT,properties.CANT_DROP_THROW,properties.PISTOL],
		"Bullet" = "res://Scenes/Misc/pistol_bullet.tscn",
		"Range" = 75,
		"Prompts" = [prompts.AIM,prompts.SHOOT],
		"Material" = materials.DEFAULT,
		"Tooltip" = "Bang bang mother fluffa, this\nhandy dandy handgun can deal\ndecent damage... As long as it is\nin the hands of a worthy user."
	},
	"10":{
		"Name" = "Speaker - Carry On",
		"Path" = "res://Scenes/Props/Speaker_Carry_on(10).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/10_Speaker_Carry_on.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/10_Speaker_Carry_on_Outline.tres",
		"Mass" = 5.8,
		"Breakable" = false,
		"Audio" = "res://Assets/Videos_and_Audio/Carryonmywaywardson.mp3",
		"Properties" = [properties.SPEAKER],
		"Prompts" = [prompts.TOGGLE],
		"Material" = materials.DEFAULT,
		"Tooltip" = "Masquerading as a man with a\nreason goes so hard for no\nreason."
	},
	"11":{
		"Name" = "Painting - My Love",
		"Path" = "res://Scenes/Props/Painting(11).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/11_Painting.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/11_Painting_Outline.tres",
		"Mass" = 4.6,
		"Breakable" = false,
		"Properties" = [properties.PAINTING],
		"Prompts" = [],
		"Material" = materials.DEFAULT,
		"Tooltip" = '"SDIYBT"'
	},
	"12":{
		"Name" = "TV - Intro",
		"Path" = "res://Scenes/Props/TV_intro(12).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/8_TV.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/8_TV_Outline.tres",
		"Mass" = 12.6,
		"Breakable" = false,
		"Video" = "res://Assets/Videos_and_Audio/0001-0200.ogv",
		"Properties" = [properties.TV],
		"Prompts" = [prompts.TOGGLE],
		"Material" = materials.DEFAULT,
		"Tooltip" = "Game by Bourbon and Coke,\nand roobuc, better known\nby his stage name Passionfruit\nman.",
	},
	"14":{
		"Name" = "Speaker radio",
		"Path" = "res://Scenes/Props/Speaker_radio.tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/10_Speaker_Carry_on.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/10_Speaker_Carry_on_Outline.tres",
		"Mass" = 5.8,
		"Audio" = "res://Assets/Videos_and_Audio/output.mp3",
		"Properties" = [properties.SPEAKER],
		"Prompts" = [prompts.TOGGLE],
		"Tooltip" = "Masquerading as a man with a\nreason goes so hard for no\nreason."
	},
	"20": {
		"Name" = "The Package",
		"Path" = "res://Scenes/Props/Basic_Healing(7).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder_Outline.tres",
		"Mass" = 2.6,
		"Breakable" = false,
		"Properties" = [properties.CANT_DROP_THROW],
		"Prompts" = [],
		"Material" = materials.DEFAULT,
		"Tooltip" = "The oh-so-important package.\nTake special care of this because\nyou HAVE to deliver this."
	},
}
