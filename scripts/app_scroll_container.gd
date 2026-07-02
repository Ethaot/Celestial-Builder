extends ScrollContainer
class_name AppScrollContainer

@export var snap_speed: float = 0.3
@export var main_scene: MainScene
var dragging: bool = false
var page_width: float = 0.0

func _ready() -> void:
	page_width = get_window().size.x
	get_h_scroll_bar().gui_input.connect(_on_scrollbar_input)

func _process(_delta: float) -> void:
	if dragging and !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_on_drag_ended()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
			else:
				_on_drag_ended()

func _on_scrollbar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if !event.pressed:
			_on_drag_ended()

func _on_drag_ended() -> void:
	dragging = false
	var current_scroll = scroll_horizontal
	var target_page: int = roundi(float(current_scroll) / page_width)
	var target_scroll = target_page * page_width
	
	enable_buttons(target_page)
	
	var max_scroll = get_h_scroll_bar().max_value - page_width
	target_scroll = clamp(target_scroll, 0, max_scroll)
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scroll_horizontal", target_scroll, snap_speed)

func go_to_page(idx: int) -> void:
	enable_buttons(idx)
	var target_page = idx
	var target_scroll = target_page * page_width
	
	var max_scroll = get_h_scroll_bar().max_value - page_width
	target_scroll = clamp(target_scroll, 0, max_scroll)
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scroll_horizontal", target_scroll, snap_speed)

func enable_buttons(target_page: int) -> void:
	match target_page:
		0:
			main_scene.menu_tab_button.disabled = true
			main_scene.frames_tab_button.disabled = false
			main_scene.parts_tab_button.disabled = false
		1:
			main_scene.menu_tab_button.disabled = false
			main_scene.frames_tab_button.disabled = true
			main_scene.parts_tab_button.disabled = false
		2:
			main_scene.menu_tab_button.disabled = false
			main_scene.frames_tab_button.disabled = false
			main_scene.parts_tab_button.disabled = true
