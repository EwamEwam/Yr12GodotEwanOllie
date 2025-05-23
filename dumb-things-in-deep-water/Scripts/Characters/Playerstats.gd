extends Node

enum game_states {PLAYING,PAUSED,MENU}
enum camera_states {THIRD,FIRST}
var current_state :game_states = game_states.PLAYING
var current_camera :camera_states = camera_states.THIRD

var sensitivity :float = 0.25
