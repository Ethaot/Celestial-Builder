extends ScrollContainer

var is_dragging: bool = false
var swipe_speed = 1.0

func _ready() -> void:
	pass
	#custom_minimum_size.x = get_window().size.x

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.index == 0:
			is_dragging = event.pressed
	if event is InputEventScreenDrag:
		if is_dragging:
			scroll_vertical -= event.relative.y * swipe_speed
