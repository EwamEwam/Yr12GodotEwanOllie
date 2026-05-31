extends Node

var target_scene_path :String = ""
var progress :Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)

func load_scene(target_path :String) -> void:
	target_scene_path = target_path
	
	ResourceLoader.load_threaded_request(target_scene_path)
	set_process(true)
	
func _process(_delta: float) -> void:
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			DeveloperSettings.add_log("Loading to path " + str(target_scene_path) + " is at " + str(progress[0] * 100) + "%", DeveloperSettings.Log_Types.INFO)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			DeveloperSettings.add_log("Load to path " + str(target_scene_path) + " has failed", DeveloperSettings.Log_Types.ERROR)
		ResourceLoader.THREAD_LOAD_LOADED:
			finalize_scene_loading()
	
func finalize_scene_loading() -> void:
	var new_scene :PackedScene = ResourceLoader.load_threaded_get(target_scene_path)
	get_tree().change_scene_to_packed(new_scene)
	
	set_process(false)
	
