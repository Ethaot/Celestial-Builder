extends ScrollContainer
class_name TouchScrollContainer

var is_dragging: bool = false
var swipe_speed = 1.0
var drag_speed: float = 0.0
var drag_accum: float
var last_drag_accum: float
var drag_from: float
var time_since_motion: float
var deaccel: bool = false
var deadzone: float = 10.0
var beyond_deadzone: bool = false


#func _ready() -> void:
	#custom_minimum_size.x = get_window().size.x

func _physics_process(delta: float) -> void:
	if is_dragging:
		if deaccel:
			scroll_vertical -= drag_speed * delta
			var sgn_y: float = -1.0 if drag_speed < 0 else 1.0
			var val_y: float = abs(drag_speed)
			val_y -= 1000 * delta
			if val_y < 0:
				_cancel_drag()
			drag_speed = sgn_y * val_y
		else:
			if time_since_motion > 1.0:
				_cancel_drag()
			if time_since_motion == 0.0 or time_since_motion > 0.1:
				var diff: float = drag_accum - last_drag_accum
				last_drag_accum = drag_accum
				drag_speed = clamp(diff / delta, -3000.0, 3000.0)
			time_since_motion += delta
		
func _cancel_drag() -> void:
	drag_speed = 0.0
	drag_accum = 0.0
	last_drag_accum = 0.0
	drag_from = 0.0
	deaccel = false
	is_dragging = false
	beyond_deadzone = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.index == 0:
			if !event.pressed:
				if drag_speed == 0.0:
					_cancel_drag()
				else:
					deaccel = true
			else:
				if is_dragging:
					_cancel_drag()
				deaccel = false
				is_dragging = true
				time_since_motion = 0.0
				drag_from = event.position.y
	if event is InputEventScreenDrag:
		if is_dragging and !deaccel:
			var motion: float = event.relative.y
			drag_accum += event.relative.y * swipe_speed
			if abs(drag_accum) > deadzone:
				beyond_deadzone = true
			if beyond_deadzone:
				drag_accum = motion * swipe_speed
			#var diff = drag_from + drag_accum
			time_since_motion = 0.0
			scroll_vertical -= event.relative.y * swipe_speed
