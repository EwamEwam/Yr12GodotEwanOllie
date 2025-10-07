extends Control

var result :bool

signal button_pressed

func return_result() -> bool:
	await button_pressed
	return result

func _on_yes_pressed() -> void:
	result = true
	emit_signal("button_pressed")

func _on_no_pressed() -> void:
	result = false
	emit_signal("button_pressed")
