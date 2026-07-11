extends ColorRect
class_name CustomFrameBuildMode

@export var snap_speed: float = 0.3
@export var scroll_container: ScrollContainer
@export var main_hbox: HBoxContainer
@export var menu_tab_button: Button
@export var frame_tab_button: Button
@export var parts_tab_button: Button

var page_width: int

func _ready() -> void:
	get_window().size_changed.connect(setup)
	setup()
	
	menu_tab_button.button_up.connect(_on_menu_tab_button_pressed)
	frame_tab_button.button_up.connect(_on_frame_tab_button_pressed)
	parts_tab_button.button_up.connect(_on_parts_tab_button_pressed)

func setup() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.SCREEN_PRIMARY)
	#get_window().size = screen_size
	get_window().content_scale_size = screen_size
	page_width = screen_size.x
	scroll_container.custom_minimum_size.x = page_width
	
	for child:ScrollContainer in main_hbox.get_children():
		child.custom_minimum_size.x = page_width

func go_to_page(idx: int, _delayed: bool = false) -> void:
	enable_buttons(idx)
	var target_page = idx
	var target_scroll = target_page * page_width
	
	var max_scroll = scroll_container.get_h_scroll_bar().max_value - page_width
	target_scroll = clamp(target_scroll, 0, max_scroll)
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(scroll_container, "scroll_horizontal", target_scroll, snap_speed)
	
func enable_buttons(target_page: int) -> void:
	match target_page:
		0:
			menu_tab_button.disabled = true
			frame_tab_button.disabled = false
			parts_tab_button.disabled = false
		1:
			menu_tab_button.disabled = false
			frame_tab_button.disabled = true
			parts_tab_button.disabled = false
		2:
			menu_tab_button.disabled = false
			frame_tab_button.disabled = false
			parts_tab_button.disabled = true

func _on_menu_tab_button_pressed() -> void:
	go_to_page(0)
	
func _on_frame_tab_button_pressed() -> void:
	go_to_page(1)

func _on_parts_tab_button_pressed() -> void:
	go_to_page(2)
