##Player saves are handled by the save manager.
extends Node

enum Exit_code {SUCCESSFUL_SAVE, SUCCESSFUL_LOAD, SUCCESSFUL_DELETE, FILE_NOT_FOUND, SAVE_SLOT_OUT_OF_BOUNDS, FILE_NOT_CREATED, CANNOT_OPEN_FILE, INVALID_SAVE_DATA, DIRECTORY_FAILED, UNKNOWN_ERROR,}
var max_slots :int = 3
var version = ProjectSettings.get_setting("application/config/version")
var can_save :bool = true

const GAME_NAME :StringName = "Game_Test_Name"
const BUILD_NUMBER :int = 81

var os_name :String = OS.get_name()
var path :String = ""

var saves_path :String = ""

var loaded_data :Dictionary = {}

func _ready() -> void:
	if os_name == "Windows":
		
		DeveloperSettings.add_log("Game has loaded to Windows OS")
		path = OS.get_environment("LOCALAPPDATA") \
		.path_join(GAME_NAME)
		
		saves_path = path \
		.path_join("Saves")
		
		can_save = true
	else:
		DeveloperSettings.add_log("This environment currently does not have save support :(",DeveloperSettings.Log_Types.WARNING)
		can_save = false
		
##Handles the saving of manual save data to the folder.
##In an ideal world, this would be an ideal method to save but backups needs be.
func Save_data_to_files(data :Dictionary, save_slot :int = 1) -> Exit_code:
	if save_slot > max_slots or save_slot <= 0:
		DeveloperSettings.add_log(str(save_slot) + " is out of bound for the allowed Save Slot number: " + str(max_slots),DeveloperSettings.Log_Types.ERROR)
		return Exit_code.SAVE_SLOT_OUT_OF_BOUNDS
		
	var error_code :Error = DirAccess.make_dir_recursive_absolute(saves_path)
	if error_code != OK:
		DeveloperSettings.add_log("Failed to produce directories: " + str(error_string(error_code)),DeveloperSettings.Log_Types.ERROR)
		return Exit_code.DIRECTORY_FAILED
	
	var save_name :String = "save_slot_" + str(save_slot) + ".dat"
	var save_path :String = saves_path.path_join(save_name)
	
	var file :FileAccess = FileAccess.open(save_path,FileAccess.WRITE)
	
	if file == null:
		DeveloperSettings.add_log("Couldn't write to file: " + error_string(FileAccess.get_open_error()))
		return Exit_code.FILE_NOT_CREATED
		
	if file.store_var(data):
		file.close()
		DeveloperSettings.add_log("Data has successfully been written to slot " + str(save_slot))
		return Exit_code.SUCCESSFUL_SAVE
	else:
		file.close()
		DeveloperSettings.add_log("Something has gone wrong while saving to slot " + str(save_slot),DeveloperSettings.Log_Types.ERROR)
		return Exit_code.UNKNOWN_ERROR
	
##Returns a dictionary containing the player's save data
##This includes current triggers, player's stats and current inventory
func Load_data_from_files(save_slot :int = 1) -> Exit_code:
	if save_slot > max_slots and save_slot < 0:
		DeveloperSettings.add_log(str(save_slot) + " is out of bounds for the allowed Save Slot number: " + str(max_slots),DeveloperSettings.Log_Types.ERROR)
		return Exit_code.SAVE_SLOT_OUT_OF_BOUNDS
	
	var save_name :String = "save_slot_" + str(save_slot) + ".dat"
	var save_path :String = saves_path.path_join(save_name)
	
	if !FileAccess.file_exists(save_path):
		DeveloperSettings.add_log("Save Slot " + str(save_slot) + " does not exist",DeveloperSettings.Log_Types.ERROR)
		return Exit_code.FILE_NOT_FOUND
		
	var file :FileAccess = FileAccess.open(save_path,FileAccess.READ)
	if file == null:
		DeveloperSettings.add_log("Failed to open Save Slot " + str(save_slot) + ": " + error_string(FileAccess.get_open_error()),DeveloperSettings.Log_Types.ERROR)
		return Exit_code.CANNOT_OPEN_FILE
	
	var save_data = file.get_var()
	if save_data is Dictionary:
		DeveloperSettings.add_log("Data has successfully been retrieved from slot " + str(save_slot))
		loaded_data = save_data
		return Exit_code.SUCCESSFUL_LOAD
	else:
		DeveloperSettings.add_log("Save data on slot " + str(save_slot) + " may be corrupted, that's unfortunate", DeveloperSettings.Log_Types.ERROR)
		return Exit_code.INVALID_SAVE_DATA

func delete_save_slot(save_slot :int) -> Exit_code:
	if save_slot > max_slots:
		DeveloperSettings.add_log(str(save_slot) + " is higher than the allowed Save Slot number: " + str(max_slots),DeveloperSettings.Log_Types.ERROR)
		return Exit_code.SAVE_SLOT_OUT_OF_BOUNDS
	
	var save_name :String = "save_slot_" + str(save_slot) + ".dat"
	var save_path :String = saves_path.path_join(save_name)
	
	if !FileAccess.file_exists(save_path):
		DeveloperSettings.add_log("Save Slot " + str(save_slot) + " does not exist",DeveloperSettings.Log_Types.ERROR)
		return Exit_code.FILE_NOT_FOUND
	
	var err :Error = DirAccess.remove_absolute(save_path)
	if err == OK:
		return Exit_code.SUCCESSFUL_DELETE
	else:
		DeveloperSettings.add_log("Failed to delete Save Slot " + str(save_slot) + ": " + error_string(err),DeveloperSettings.Log_Types.ERROR)
		return Exit_code.UNKNOWN_ERROR

func Create_save_dictionary() -> Dictionary:
	var save_data :Dictionary = {
		"Save_Slot_Name": Playerstats.Save_Slot,
		"Save_Build": BUILD_NUMBER,
		"Player_Stats":{
			"Max_Health": Playerstats.max_health,
		},
		"RPG_Player_Stats":{
			"Level": 1,
			"Max_Health": 20,
		}
	}
	return save_data
	
func generate_backup() -> void:
	pass
