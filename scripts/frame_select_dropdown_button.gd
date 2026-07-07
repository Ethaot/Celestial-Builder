extends Button
class_name FrameSelectDropdownButton

signal frame_chosen(index: int)

var idx: int

func _ready() -> void:
	button_up.connect(_on_button_up)

func _on_button_up() -> void:
	frame_chosen.emit(idx)
