##The singleton that handles Developer Mode
##[br]Grants access the dev menu, alongside direct
##[br]manipulation to the player, entities, and other in
##[br]stats. These settings are normally locked unless 100% completion
##[br]is achieved. good luck ;)
extends Node

##The different types of logs
##[br]INFO: Displayed in White, for standard printing
##[br]WARNING: Displayed in Yellow, used to warn something is bad practice, but still functional
##[br]ERROR: Displayed in Red, used to display a caught error
##[br]CUSTOM: Displayed in a user_defined_colour
enum Log_Types {INFO, WARNING, ERROR, CUSTOM}

##The array used to save the past 100 logs, the first index is the time of the log
##[br]the second is the actual string ,the third index is the type, the fourth is the Colour
var logs :Array[Array] = []
var max_logs :int = 100

signal log_updated(log_index :Array)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_log("Game Entered")

##The function used to add logs to the external output console.
##[br]Important to note that the types are Log_Types.INFO, Log_Types.WARNING, 
##[br]Log_Types.ERROR, and Log_Types.CUSTOM, these are purely for visual colour coding
##[br]and the custom type means that you can manually define a colour using the third parameter.
func add_log(text :Variant = "Text Output", type :Log_Types = Log_Types.INFO, colour :Color = Color(1,1,1,1)) -> void:
	if type == Log_Types.INFO:
		colour = Color(1,1,1,1)
	if type == Log_Types.WARNING:
		colour = Color(0.847, 0.635, 0.0, 1.0)
	if type == Log_Types.ERROR:
		colour = Color(0.868, 0.0, 0.0, 1.0)
	logs.append([Time.get_time_string_from_system() ,str(text) ,type ,colour])
	if logs.size() > max_logs:
		logs.pop_front()
	emit_signal("log_updated", [Time.get_time_string_from_system() ,text ,type ,colour])
