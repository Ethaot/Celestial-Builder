extends ScrollContainer
class_name FrameBuilderPartsTabMenu

var part_group_tab_vbox_prefab: PackedScene = preload("res://scenes/part_group_v_box.tscn")
var part_picker_vbox_prefab: PackedScene = preload("res://scenes/part_picker_v_box.tscn")
var empty_grid_frame: Texture2D = preload("res://assets/empty_grid_frame.png")

@export var main_script: CustomFrameBuildMode
@export var part_grid_interface: PartGridInterface
@export var part_tabs_vbox: VBoxContainer
@export var parts_grid_container: GridContainer
@export var weapons_ranged_tab_button: Button
@export var weapons_explosive_tab_button: Button
@export var weapons_melee_tab_button: Button
@export var weapons_ew_tab_button: Button
@export var weapons_missiles_tab_button: Button
@export var parts_reactors_tab_button: Button
@export var parts_thrusters_tab_button: Button
@export var parts_processors_tab_button: Button
@export var parts_shields_tab_button: Button

var is_dragging: bool = false
var swipe_speed = 1.0

var start_part_pickup: bool = false
var selecting_part_from_parts: bool = false

func _ready() -> void:
	weapons_ranged_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponRanged))
	weapons_explosive_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponExplosive))
	weapons_melee_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponMelee))
	weapons_ew_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponEW))
	weapons_missiles_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponMissile))
	parts_reactors_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartReactor))
	parts_thrusters_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartThruster))
	parts_processors_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartProcessor))
	parts_shields_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartShield))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.index == 0:
			is_dragging = event.pressed
	if event is InputEventScreenDrag:
		if is_dragging:
			scroll_vertical -= event.relative.y * swipe_speed

func _input(event: InputEvent) -> void:
	match part_grid_interface.current_mode:
		part_grid_interface.Mode.Normal:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if !event.pressed:
						start_part_pickup = false
						selecting_part_from_parts = false
			if event is InputEventScreenTouch:
				if event.index == 0:
					if !event.pressed:
						start_part_pickup = false
						selecting_part_from_parts = false
		part_grid_interface.Mode.Edit:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if !event.pressed:
						if part_grid_interface.hovered_grids.size() > 0:
							pass
							#_on_part_dropped(hovered_grids[0])
						else:
							_on_part_cleared()
			if event is InputEventScreenTouch:
				if event.index == 0:
					if !event.pressed:
						if part_grid_interface.hovered_grids.size() > 0:
							pass
							#_on_part_dropped(hovered_grids[0])
						else:
							_on_part_cleared()

func show_parts_screen(part_type: Constants.PartType) -> void:
	#switch_to_parts_view()
	populate_parts_screen(part_type)

func populate_parts_screen(part_type: Constants.PartType) -> void:
	var part_groups_dict: Dictionary[String, PartGroupVBox]
	for child in part_tabs_vbox.get_children():
		if child.get_index() > 3:
			child.queue_free()
	for child in parts_grid_container.get_children():
		child.queue_free()
	var parts: Array[Part]
	match part_type:
		Constants.PartType.WeaponRanged:
			parts = ResourceManager.weapons_ranged
		Constants.PartType.WeaponExplosive:
			parts = ResourceManager.weapons_explosive
		Constants.PartType.WeaponMelee:
			parts = ResourceManager.weapons_melee
		Constants.PartType.WeaponEW:
			parts = ResourceManager.weapons_ew
		Constants.PartType.WeaponMissile:
			parts = ResourceManager.weapons_missiles
		Constants.PartType.PartReactor:
			parts = ResourceManager.parts_reactors
		Constants.PartType.PartThruster:
			parts = ResourceManager.parts_thrusters
		Constants.PartType.PartProcessor:
			parts = ResourceManager.parts_processors
		Constants.PartType.PartShield:
			parts = ResourceManager.parts_shields
	for part in parts:
		var target_parent: GridContainer = parts_grid_container
		if part.part_tab != "":
			if part_groups_dict.has(part.part_tab):
				target_parent = part_groups_dict[part.part_tab].group_tab_grid_container
			else:
				var part_tab: PartGroupVBox = part_group_tab_vbox_prefab.instantiate()
				part_tab.group_tab_button.text = part.part_tab
				part_tabs_vbox.add_child(part_tab)
				part_groups_dict[part.part_tab] = part_tab
				target_parent = part_tab.group_tab_grid_container
		
		
		var held_part: HeldPart = HeldPart.new()
		held_part.part_id = part.part_id
		held_part.slots = part.part_configuration
		held_part.part_icons = ResourceManager.part_image_dict[part.part_id]
		match part.part_type:
			Constants.PartType.PartProcessor:
				target_parent.add_child(draw_part(held_part, false, false, 0))
			Constants.PartType.WeaponRanged, Constants.PartType.WeaponExplosive, Constants.PartType.WeaponMelee, Constants.PartType.WeaponEW, Constants.PartType.WeaponMissile:
				for i in range(4):
					var hp: HeldPart = held_part.duplicate(true)
					match i:
						0:
							target_parent.add_child(draw_part(hp, false, false, 0))
						1:
							hp = mirror_slots_horizontally(hp)
							target_parent.add_child(draw_part(hp, true, false, 0))
						2:
							hp = mirror_slots_vertically(hp)
							target_parent.add_child(draw_part(hp, false, true, 0))
						3:
							hp = mirror_slots_horizontally(mirror_slots_vertically(hp))
							target_parent.add_child(draw_part(hp, true, true, 0))
			Constants.PartType.PartReactor, Constants.PartType.PartThruster, Constants.PartType.PartShield:
				for i in range(4):
					var hp: HeldPart = held_part.duplicate(true)
					match i:
						0:
							target_parent.add_child(draw_part(hp, false, false, 0))
						1:
							rotate_slots(hp)
							target_parent.add_child(draw_part(hp, false, false, 1))
						2:
							rotate_slots(rotate_slots(hp))
							target_parent.add_child(draw_part(hp, false, false, 2))
						3:
							rotate_slots(rotate_slots(rotate_slots(hp)))
							target_parent.add_child(draw_part(hp, false, false, 3))
		
	var vb: VBoxContainer = part_tabs_vbox.get_parent()
	vb.move_child(parts_grid_container, vb.get_children().size() - 1)

func draw_part(hp: HeldPart, mirrored_horizontally: bool, mirrored_vertically: bool, times_rotated: int) -> PartPickerVBox:
	var part: Part = ResourceManager.part_dict[hp.part_id]
	var ppvb: PartPickerVBox = part_picker_vbox_prefab.instantiate()
	var num_columns: int = 0
	var num_rows: int = 0
	for p in hp.slots:
		if p.x + 1 > num_columns:
			num_columns = p.x + 1
		if p.y + 1 > num_rows:
			num_rows = p.y + 1
	ppvb.grid_container.columns = num_columns
	var current_texture_index: int = 0
	var screen_x: int = get_window().size.x
	var min_x: int = mini(ceili(float(screen_x) / float(num_columns) / 2.0), 128.0)
	for y in range(num_rows):
		for x in range(num_columns):
			var texrect_parent: Control = Control.new()
			texrect_parent.custom_minimum_size = Vector2(min_x, min_x)
			var texrect: TextureRect = TextureRect.new()
			texrect.custom_minimum_size = Vector2(min_x, min_x)
			if hp.slots.has(Vector2i(x, y)):
				texrect.texture = hp.part_icons[current_texture_index]
				current_texture_index += 1
			else:
				texrect.texture = empty_grid_frame
			if mirrored_horizontally:
				texrect.flip_h = true
			if mirrored_vertically:
				texrect.flip_v = true
			for i in range(times_rotated):
				texrect.pivot_offset_ratio = Vector2(0.5, 0.5)
				texrect.rotation_degrees = (i + 1) * 90.0
			texrect_parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
			texrect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ppvb.grid_container.add_child(texrect_parent)
			texrect_parent.add_child(texrect)
	ppvb.name_label.text = part.part_name
	if part.requirements != "":
		ppvb.name_label.text += " [color=purple]Req: " + part.requirements + "[/color]"
	#ppvb.name_button.button_down.connect(_on_part_grabbed.bind(hp))
	ppvb.part_picker_button_down.connect(_on_part_grab_started.bind(hp))
	return ppvb

func mirror_slots_horizontally(hp: HeldPart) -> HeldPart:
	var part_size: Vector2i
	var new_part_icons: Array[AtlasTexture]
	var new_slots: Array[Vector2i]
	var slot_icon_dict: Dictionary[Vector2i, AtlasTexture]
	for slot in hp.slots:
		if slot.x > part_size.x:
			part_size.x = slot.x
		if slot.y > part_size.y:
			part_size.y = slot.y
	for i in range(part_size.y + 1):
		if i * (part_size.x + 1) + part_size.x + 1 > hp.slots.size():
			var new_slot_array: Array[Vector2i]
			for n in range(hp.slots.size() - 1, i * (part_size.x + 1) - 1, -1):
				var new_vector: Vector2i = Vector2i(part_size.x - hp.slots[n].x, hp.slots[n].y)
				new_slot_array.append(new_vector)
				slot_icon_dict[new_vector] = hp.part_icons[n]
			new_slots.append_array(new_slot_array)
		else:
			var new_slot_array: Array[Vector2i]
			for n in range(i * (part_size.x + 1) + part_size.x, i * (part_size.x + 1) - 1, -1):
				var new_vector: Vector2i = Vector2i(part_size.x - hp.slots[n].x, hp.slots[n].y)
				new_slot_array.append(new_vector)
				slot_icon_dict[new_vector] = hp.part_icons[n]
			new_slots.append_array(new_slot_array)
	
	new_slots.sort_custom(sort_slots_by_x)
	new_slots.sort_custom(sort_slots_by_y)
	
	for slot in new_slots:
		new_part_icons.append(slot_icon_dict[slot])
	hp.part_icons = new_part_icons
	hp.mirrored_h = true
	hp.slots = new_slots
	hp.part_icons = new_part_icons
	return hp

func mirror_slots_vertically(hp: HeldPart) -> HeldPart:
	var part_size: Vector2i
	var new_part_icons: Array[AtlasTexture]
	var new_slots: Array[Vector2i]
	var slot_icon_dict: Dictionary[Vector2i, AtlasTexture]
	for slot in hp.slots:
		if slot.x > part_size.x:
			part_size.x = slot.x
		if slot.y > part_size.y:
			part_size.y = slot.y
	for i in range(part_size.y, -1, -1):
		if i * (part_size.x + 1) + part_size.x + 1 > hp.slots.size():
			for n in range(i * (part_size.x + 1), hp.slots.size()):
				var new_vector: Vector2i = Vector2i(hp.slots[n].x, part_size.y - hp.slots[n].y)
				new_slots.append(new_vector)
				slot_icon_dict[new_vector] = hp.part_icons[n]
		else:
			for n in range(i * (part_size.x + 1), i * (part_size.x + 1) + part_size.x + 1):
				var new_vector: Vector2i = Vector2i(hp.slots[n].x, part_size.y - hp.slots[n].y)
				new_slots.append(new_vector)
				slot_icon_dict[new_vector] = hp.part_icons[n]
	
	new_slots.sort_custom(sort_slots_by_x)
	new_slots.sort_custom(sort_slots_by_y)
	
	for slot in new_slots:
		new_part_icons.append(slot_icon_dict[slot])
				
	hp.part_icons = new_part_icons
	hp.mirrored_v = true
	hp.slots = new_slots
	hp.part_icons = new_part_icons
	return hp

func rotate_slots(hp: HeldPart) -> HeldPart:
	var new_slots: Array[Vector2i]
	var part_size: Vector2i
	var slot_icon_dict: Dictionary[Vector2i, AtlasTexture]
	var new_part_icons: Array[AtlasTexture]
	for i in range(hp.slots.size()):
		if hp.slots[i].x > part_size.x:
			part_size.x = hp.slots[i].x
		if hp.slots[i].y > part_size.y:
			part_size.y = hp.slots[i].y
	for i in range(hp.slots.size()):
		var new_vector: Vector2i = Vector2i(part_size.y - hp.slots[i].y, hp.slots[i].x)
		slot_icon_dict[new_vector] = hp.part_icons[i]
		new_slots.append(new_vector)
	new_slots.sort_custom(sort_slots_by_x)
	new_slots.sort_custom(sort_slots_by_y)
	for slot in new_slots:
		new_part_icons.append(slot_icon_dict[slot])
	hp.slots = new_slots
	hp.part_icons = new_part_icons
	hp.times_rotated += 1
	return hp

func sort_slots_by_y(y0: Vector2i, y1: Vector2i) -> bool:
	return true if y0.y < y1.y else false

func sort_slots_by_x(x0: Vector2i, x1: Vector2i) -> bool:
	return true if x0.x < x1.x else false

func switch_to_main_view() -> void:
	main_script.go_to_page(1)

func _on_part_grabbed(part: HeldPart) -> void:
	part_grid_interface.dragged_part.assign_part(part)
	switch_to_main_view()

func _on_part_grab_started(part: HeldPart) -> void:
	part_grid_interface.current_held_part = part
	selecting_part_from_parts = true

func _on_part_cleared() -> void:
	part_grid_interface.change_mode(part_grid_interface.Mode.Normal)
