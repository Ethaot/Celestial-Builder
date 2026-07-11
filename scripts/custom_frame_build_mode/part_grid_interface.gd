extends Node
class_name PartGridInterface

const LONG_PRESS_TIMER: float = 0.75

enum Mode{Normal, Edit}

@export var frame_tab_menu: FrameBuilderFrameTabMenu
@export var parts_tab_menu: FrameBuilderPartsTabMenu
@export var dragged_part: DraggedPart

var current_mode: Mode = Mode.Normal
var current_held_part: HeldPart
var hovered_grids: Array[int]
var selected_grid: int = 0
var button_held: bool = false
var mouse_button_pressed_timer: float = 0.0
var start_part_pickup: bool = false

func _input(event: InputEvent) -> void:
	match current_mode:
		Mode.Normal:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if event.pressed:
						button_held = true
						mouse_button_pressed_timer = 0.0
					else:
						button_held = false
						start_part_pickup = false
						parts_tab_menu.selecting_part_from_parts = false
			if event is InputEventScreenTouch:
				if event.index == 0:
					if event.pressed:
						button_held = true
						mouse_button_pressed_timer = 0.0
					else:
						button_held = false
						start_part_pickup = false
						parts_tab_menu.selecting_part_from_parts = false
		Mode.Edit:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if !event.pressed:
						if hovered_grids.size() > 0:
							pass
							#_on_part_dropped(hovered_grids[0])
						else:
							parts_tab_menu._on_part_cleared()
						button_held = false
			if event is InputEventScreenTouch:
				if event.index == 0:
					if !event.pressed:
						if hovered_grids.size() > 0:
							pass
							#_on_part_dropped(hovered_grids[0])
						else:
							parts_tab_menu.on_part_cleared()
						button_held = false

func _process(delta: float) -> void:
	match current_mode:
		Mode.Normal:
			if start_part_pickup:
				if button_held:
					mouse_button_pressed_timer += delta
					if mouse_button_pressed_timer >= LONG_PRESS_TIMER:
						if hovered_grids.size() > 0:
							frame_tab_menu.pickup_placed_part(hovered_grids[0])
						start_part_pickup = false
			elif parts_tab_menu.selecting_part_from_parts:
				if button_held:
					mouse_button_pressed_timer += delta
					if mouse_button_pressed_timer >= LONG_PRESS_TIMER:
						parts_tab_menu._on_part_grabbed(current_held_part)
						parts_tab_menu.selecting_part_from_parts = false

func change_mode(new_mode: Mode) -> void:
	match current_mode:
		Mode.Normal:
			pass
		Mode.Edit:
			pass
	match new_mode:
		Mode.Normal:
			pass
		Mode.Edit:
			pass
	current_mode = new_mode
