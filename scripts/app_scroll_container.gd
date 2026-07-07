extends ScrollContainer
class_name AppScrollContainer

@export var snap_speed: float = 0.3
@export var main_scene: MainScene
@export var main_hbox: HBoxContainer
var dragging: bool = false
var page_width: float = 0.0

func _ready() -> void:
	get_window().size_changed.connect(setup)
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

func setup() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.SCREEN_PRIMARY)
	#get_window().size = screen_size
	get_window().content_scale_size = screen_size
	
	if !OS.has_feature("mobile") and !OS.has_feature("web_android") and !OS.has_feature("web_ios"):
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_width = screen_size.x
	for child:ScrollContainer in main_hbox.get_children():
		child.custom_minimum_size.x = page_width

func go_to_page(idx: int, delayed: bool = false) -> void:
	if delayed and !main_scene.done_loading:
		await get_tree().process_frame
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
			main_scene.lamplighter_tab_button.disabled = false
			main_scene.frames_tab_button.disabled = false
			main_scene.parts_tab_button.disabled = false
		1:
			main_scene.menu_tab_button.disabled = false
			main_scene.lamplighter_tab_button.disabled = true
			main_scene.frames_tab_button.disabled = false
			main_scene.parts_tab_button.disabled = false
		2:
			main_scene.menu_tab_button.disabled = false
			main_scene.lamplighter_tab_button.disabled = false
			main_scene.frames_tab_button.disabled = true
			main_scene.parts_tab_button.disabled = false
		3:
			main_scene.menu_tab_button.disabled = false
			main_scene.lamplighter_tab_button.disabled = false
			main_scene.frames_tab_button.disabled = false
			main_scene.parts_tab_button.disabled = true
