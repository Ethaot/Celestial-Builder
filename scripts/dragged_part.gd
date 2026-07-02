extends Control
class_name DraggedPart

@export var part_grid: GridContainer

var empty_grid_frame: Texture2D = preload("res://assets/empty_grid_frame.png")

func _process(_delta: float) -> void:
	global_position = get_viewport().get_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if !event.pressed:
				clear_part()

func assign_part(held_part: HeldPart) -> void:
	var part: Part = ResourceManager.part_dict[held_part.part_id]
	var num_columns: int = 0
	var num_rows: int = 0
	for p in held_part.slots:
		if p.x + 1 > num_columns:
			num_columns = p.x + 1
		if p.y + 1 > num_rows:
			num_rows = p.y + 1
	part_grid.columns = num_columns
	var current_texture_index: int = 0
	for y in range(num_rows):
		for x in range(num_columns):
			var texrect: TextureRect = TextureRect.new()
			texrect.custom_minimum_size = Vector2(128.0, 128.0)
			if held_part.slots.has(Vector2i(x, y)):
				texrect.texture = part.part_icons[current_texture_index]
				current_texture_index += 1
			else:
				texrect.texture = empty_grid_frame
			texrect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			part_grid.add_child(texrect)

func clear_part() -> void:
	for child in part_grid.get_children():
		child.queue_free()
