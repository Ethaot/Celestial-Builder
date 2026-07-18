extends TouchScrollContainer
class_name EncounterModeScrollContainer

@export var snap_speed: float = 0.3
@export var menu_scroll_container: TouchScrollContainer
@export var encounter_scroll_container: TouchScrollContainer
@export var menu_tab_button: Button
@export var encounter_tab_button: Button

var page_width: int

func _ready() -> void:
	get_window().size_changed.connect(setup)
	setup()

func setup() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.SCREEN_PRIMARY)
	#get_window().size = screen_size
	get_window().content_scale_size = screen_size
	page_width = screen_size.x
	menu_scroll_container.custom_minimum_size.x = page_width
	encounter_scroll_container.custom_minimum_size.x = page_width

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
			menu_tab_button.disabled = true
			encounter_tab_button.disabled = false
		1:
			menu_tab_button.disabled = false
			encounter_tab_button.disabled = true
