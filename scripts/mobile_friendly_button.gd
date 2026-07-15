extends Button
class_name MobileFriendlyButton

var drag_deadzone: float = 10.0
var touch_start_pos: Vector2 = Vector2.ZERO
var is_dragging: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed():
			touch_start_pos = event.position
			is_dragging = false
		else:
			if is_dragging:
				accept_event()
				set_pressed_no_signal(false)
	if event is InputEventScreenDrag:
		if button_pressed and !is_dragging:
			if touch_start_pos.distance_to(event.position) > drag_deadzone:
				is_dragging = true
				set_pressed_no_signal(false)
