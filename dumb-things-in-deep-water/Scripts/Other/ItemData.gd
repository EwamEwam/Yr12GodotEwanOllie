extends Node

#Prop types:
#1: Basic interactable Prop with not other purpose
#2: Increases the ID of prop by 1 when interacted
#3: Increases the ID of prop by 1 when interacted as well as healing the player
#4: Deletes the prop when interacted as well as healing the player
const itemdata :Dictionary = {
	"0": {
		"Name" = "Error",
		"Path" = "res://Scenes/Props/Placeholder(1).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Model.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Outline.tres",
		"Mass" = 0.1,
		"Type" = 1, 
		"Tooltip" = "You Should NOT have this in\nyour inventory."
	},
	"1": {
		"Name" = "Placeholder",
		"Path" = "res://Scenes/Props/Placeholder(1).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Model.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Outline.tres",
		"Mass" = 1.0,
		"Type" = 1, 
		"Tooltip" = "A basic blue cube, has a mass of\nexactly 1 kg to the atomic level"
	},
	"2": {
		"Name" = "White Cyclinder",
		"Path" = "res://Scenes/Props/White_Cyclinder(2).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder_Outline.tres",
		"Mass" = 100.0,
		"Type" = 1, 
		"Tooltip" = "Unbeknownst to the naked eye, this is\nnothing more than a simple white cyclinder."
	},
	"3": {
		"Name" = "Can - Closed",
		"Path" = "res://Scenes/Props/Can_Closed(3).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder_Outline.tres",
		"Mass" = 0.3,
		"Type" = 2, 
		"Tooltip" = "A basic can, press left click\nwhile holding to open."
	},
	"4": {
		"Name" = "Can - Opened",
		"Path" = "res://Scenes/Props/Can_Closed(3).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Model.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Outline.tres",
		"Collision" = "res://Assets/Props_Models_And_Collisions/Box_test.tres",
		"Mass" = 0.3,
		"Type" = 3, 
		"Value" = 5,
		"Tooltip" = "Press left click while holding\nto consume to heal 5 HP."
	},
	"5": {
		"Name" = "Can - Half Full",
		"Path" = "res://Scenes/Props/Can_Half_Full(5).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Model.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/1_Placeholder_Outline.tres",
		"Collision" = "res://Assets/Props_Models_And_Collisions/Box_test.tres",
		"Mass" = 0.2,
		"Type" = 3, 
		"Value" = 5,
		"Tooltip" = "Half full (or empty for you\npessimists), press left click to\nconsume to heal 5 HP."
	},
	"6": {
		"Name" = "Can - Empty",
		"Path" = "res://Scenes/Props/Can_Empty(6).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder_Outline.tres",
		"Collision" = "res://Assets/Props_Models_And_Collisions/Cyclinder_test.tres",
		"Mass" = 0.1,
		"Type" = 1, 
		"Tooltip" = "It's empty..."
	},
	"7": {
		"Name" = "Healing Item",
		"Path" = "res://Scenes/Props/Can_Empty(6).tscn",
		"Model" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder.tres",
		"Outline" = "res://Assets/Props_Models_And_Collisions/2_White_Cyclinder_Outline.tres",
		"Collision" = "res://Assets/Props_Models_And_Collisions/Cyclinder_test.tres",
		"Mass" = 1.7,
		"Type" = 4, 
		"Value" = 10,
		"Tooltip" = "A basic healing item, interact\nwith it while holding it\nto heal 10 HP"
	},
}
