extends GridContainer
class_name PartContainer

signal part_container_button_down

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				part_container_button_down.emit()
				accept_event()
