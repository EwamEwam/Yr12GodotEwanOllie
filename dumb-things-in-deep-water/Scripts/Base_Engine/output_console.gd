extends Control

@onready var text_container :VBoxContainer = $NinePatchRect/ScrollContainer/VBoxContainer
var enabled :bool = false

func _ready() -> void:
	for log_index in DeveloperSettings.logs:
		var new_label :Label = Label.new()
		new_label.text = str(log_index[0]) + ": " + str(log_index[1])
		new_label.modulate = log_index[3]
		text_container.add_child(new_label)
	
	DeveloperSettings.log_updated.connect(redraw)
	
func redraw(log_index :Array) -> void:
	var new_label :Label = Label.new()
	new_label.text = str(log_index[0]) + ": " + str(log_index[1])
	new_label.modulate = log_index[3]
	text_container.add_child(new_label)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Developer"):
		enabled = !enabled

func _process(_delta: float) -> void:
	visible = enabled
