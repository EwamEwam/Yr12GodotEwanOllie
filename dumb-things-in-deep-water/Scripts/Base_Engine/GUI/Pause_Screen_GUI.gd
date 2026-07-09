extends Node2D

var opened :bool = false

func open_pause_menu() -> void:
	if not opened:
		Playerstats.pause_menu_open = true
		$Confirmation_Box.visible = false
		Input.action_release("Escape")
		opened = true
		get_tree().paused = true
		Playerstats.current_state = Playerstats.game_states.PAUSED
		visible = true
		get_node('/root/World/HUD').visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_resume_pressed() -> void:
	close()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape") and opened:
		Playerstats.escape_pressed = true
		close()
		
	if event.is_action_released("Escape"):
		Playerstats.escape_pressed = false

func close() -> void:
	if opened and not $Confirmation_Box.visible:
		Playerstats.pause_menu_open = false
		Playerstats.current_state = Playerstats.game_states.PLAYING
		opened = false
		visible = false
		get_tree().paused = false
		get_node('/root/World/HUD').visible = true

func _on_leave_game_pressed() -> void:
	$Confirmation_Box.visible = true
	var result = await $Confirmation_Box.return_result()
	if result:
		get_tree().quit()
	else:
		$Confirmation_Box.visible = false
		
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not opened and get_tree().paused == false and Playerstats.pause_game_when_out_of_focus:
		open_pause_menu()

func _on_exit_stage_pressed() -> void:
	Input.set_mouse_mode(Input.MouseMode.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/Level/level_select.tscn")
	Playerstats.current_state = Playerstats.game_states.PAUSED
