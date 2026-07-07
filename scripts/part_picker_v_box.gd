extends VBoxContainer
class_name PartPickerVBox

signal part_picker_button_down

@export var name_label: RichTextLabel
@export var grid_container: GridContainer

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				part_picker_button_down.emit()
				#accept_event()
	if event is InputEventScreenTouch:
		if event.index == 0:
			if event.pressed:
				part_picker_button_down.emit()
