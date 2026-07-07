extends ColorRect
class_name MainScene

const LONG_PRESS_TIMER: float = 0.75

enum Mode {Normal, Edit}

var label_prefab: PackedScene = preload("res://scenes/grid_label.tscn")
var grid_texture_button_prefab: PackedScene = preload("res://scenes/grid_texture_button.tscn")
var empty_grid_frame: Texture2D = preload("res://assets/empty_grid_frame.png")
var selectable_grid_frame: Texture2D = preload("res://assets/ui/EmptyGridSpace.png")
var part_group_tab_vbox_prefab: PackedScene = preload("res://scenes/part_group_v_box.tscn")
var part_picker_vbox_prefab: PackedScene = preload("res://scenes/part_picker_v_box.tscn")
var part_effect_label_prefab: PackedScene = preload("res://scenes/part_effect_label.tscn")
var load_frame_build_button_prefab: PackedScene = preload("res://scenes/load_frame_build_button.tscn")
var shields_vbox_prefab: PackedScene = preload("res://scenes/shields_v_box.tscn")
var load_save_hbox_prefab: PackedScene = preload("res://scenes/load_save_h_box.tscn")

@export var app_scroll_container: AppScrollContainer
@export_group("Menu")
@export var menu_scroll_container: ScrollContainer
@export var menu_options_vbox: VBoxContainer
@export var menu_new_pilot_button: Button
@export var menu_load_button: Button
@export var load_lamplighter_vbox: VBoxContainer
@export_group("Lamplighter Screen")
@export var character_name_line_edit: LineEdit
@export var character_callsign_line_edit: LineEdit
@export var attribute_hboxes: Array[AttributeHBox]
@export var edit_attributes_button: Button
@export var remaining_attribute_points_label: Label
@export var prem_up_button: Button
@export var prem_amt_label: Label
@export var prem_down_button: Button
@export_group("Main Screen")
@export var main_scroll_container: ScrollContainer
@export var frame_option_button: OptionButton
@export var frame_name_line_edit: LineEdit
@export var grid_grid_container: GridContainer
@export var armor_grid_container: GridContainer
@export var defenses_hbox: HFlowContainer
@export var hp_up_button: Button
@export var hp_label: Label
@export var hp_down_button: Button
@export var part_effects_vbox: VBoxContainer
@export var save_frame_build_button: Button
#@export var debug_save_frame_build_button: Button
@export var load_frame_build_button: Button
@export var reset_frame_damage_button: Button
@export_group("Parts Screen")
@export var parts_scroll_container: ScrollContainer
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
@export_group("Other")
@export var dragged_part: DraggedPart
@export var menu_tab_button: Button
@export var lamplighter_tab_button: Button
@export var frames_tab_button: Button
@export var parts_tab_button: Button
@export var load_frame_build_menu: ColorRect
@export var load_frame_build_vbox: VBoxContainer

var current_held_part: HeldPart

var grid_container_texture_buttons: Array[GridTextureButton]
var shields_interfaces: Array[ShieldsVBox]

var current_mode: Mode = Mode.Normal
var selected_grid: int
var hovered_grids: Array[int]
var done_loading: bool = false

var frame_option_dict: Dictionary[int, String]

var button_held: bool = false
var mouse_button_pressed_timer: float = 0.0
var start_part_pickup: bool = false
var selecting_part_from_parts: bool = false

func _ready() -> void:
	app_scroll_container.setup()
	
	if !ResourceManager.prepared:
		await ResourceManager.prepared_signal
	
	populate_frame_option_button()
	frame_option_button.item_selected.connect(_on_frame_option_chosen)
	frame_option_button.select(0)
	if DataManager.save_data.save_id == "":
		frame_option_button.item_selected.emit(0)
	populate_grid()
	
	if DataManager.save_data.save_id != "":
		_on_lamplighter_loaded()
	DataManager.save_data_loaded.connect(_on_lamplighter_loaded)
	
	menu_tab_button.button_up.connect(app_scroll_container.go_to_page.bind(0))
	lamplighter_tab_button.button_up.connect(app_scroll_container.go_to_page.bind(1))
	frames_tab_button.button_up.connect(app_scroll_container.go_to_page.bind(2))
	parts_tab_button.button_up.connect(app_scroll_container.go_to_page.bind(3))
	
	menu_new_pilot_button.button_up.connect(_on_new_lamplighter_button_pressed)
	menu_load_button.button_up.connect(_on_load_lamplighter_button_pressed)
	
	character_name_line_edit.text_changed.connect(_on_lamplighter_name_line_edit_changed)
	character_callsign_line_edit.text_changed.connect(_on_callsign_line_edit_changed)
	for ahb in attribute_hboxes:
		ahb.attribute_edited.connect(_on_attribute_edited)
		ahb.display_attribute_amount()
	edit_attributes_button.button_up.connect(_on_edit_attributes_button_pressed)
	prem_up_button.button_up.connect(_on_prem_up_button_pressed)
	prem_down_button.button_up.connect(_on_prem_down_button_pressed)
	update_prem_amt_label()
	
	hp_up_button.button_up.connect(_on_hp_up_button_pressed)
	hp_down_button.button_up.connect(_on_hp_down_button_pressed)
	
	save_frame_build_button.button_up.connect(_on_save_frame_build_button_pressed)
	#debug_save_frame_build_button.button_up.connect(_debug_save_stock_build)
	load_frame_build_button.button_up.connect(_on_load_frame_build_button_pressed)
	reset_frame_damage_button.button_up.connect(_reset_frame_damage)
	
	weapons_ranged_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponRanged))
	weapons_explosive_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponExplosive))
	weapons_melee_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponMelee))
	weapons_ew_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponEW))
	weapons_missiles_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponMissile))
	parts_reactors_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartReactor))
	parts_thrusters_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartThruster))
	parts_processors_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartProcessor))
	parts_shields_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartShield))
	
	ready.connect(_on_ready)

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
						selecting_part_from_parts = false
			if event is InputEventScreenTouch:
				if event.index == 0:
					if event.pressed:
						button_held = true
						mouse_button_pressed_timer = 0.0
					else:
						button_held = false
						start_part_pickup = false
						selecting_part_from_parts = false
		Mode.Edit:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if !event.pressed:
						if hovered_grids.size() > 0:
							pass
							#_on_part_dropped(hovered_grids[0])
						else:
							_on_part_cleared()
						button_held = false
			if event is InputEventScreenTouch:
				if event.index == 0:
					if !event.pressed:
						if hovered_grids.size() > 0:
							pass
							#_on_part_dropped(hovered_grids[0])
						else:
							_on_part_cleared()
						button_held = false

func _process(delta: float) -> void:
	match current_mode:
		Mode.Normal:
			if start_part_pickup:
				if button_held:
					mouse_button_pressed_timer += delta
					if mouse_button_pressed_timer >= LONG_PRESS_TIMER:
						if hovered_grids.size() > 0:
							pickup_placed_part(hovered_grids[0])
						start_part_pickup = false
			elif selecting_part_from_parts:
				if button_held:
					mouse_button_pressed_timer += delta
					if mouse_button_pressed_timer >= LONG_PRESS_TIMER:
						_on_part_grabbed(current_held_part)
						selecting_part_from_parts = false

func populate_frame_option_button() -> void:
	for i in range(ResourceManager.frames.size()):
		frame_option_button.add_item(ResourceManager.frames[i].frame_name, i)
		frame_option_dict[i] = ResourceManager.frames[i].frame_id

func populate_grid() -> void:
	var f: Frame = ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id]
	for child in grid_grid_container.get_children():
		child.queue_free()
	grid_container_texture_buttons.clear()
	var top_left_label: Label = label_prefab.instantiate()
	grid_grid_container.add_child(top_left_label)
	for i in range(1,7):
		var l: Label = label_prefab.instantiate()
		l.text = str(i * 10)
		grid_grid_container.add_child(l)
	for i in range(1,7):
		var l: Label = label_prefab.instantiate()
		l.text = str(i)
		grid_grid_container.add_child(l)
		for n in range(6):
			var b: GridTextureButton = grid_texture_button_prefab.instantiate()
			grid_grid_container.add_child(b)
			b.button_down.connect(_on_grid_button_clicked.bind((i - 1) * 6 + n))
			b.button_up.connect(_on_grid_button_button_up.bind((i - 1) * 6 + n))
			if !f.frame_available_slots.has(Vector2i(n, i - 1)):
				b.self_modulate = Color("282828")
				b.disabled = true
			b.mouse_entered.connect(_on_grid_cell_hovered.bind((i - 1) * 6 + n))
			b.mouse_exited.connect(_on_grid_cell_unhovered.bind((i - 1) * 6 + n))
			b.grid_texture_button_up.connect(_on_part_dropped.bind((i - 1) * 6 + n))
			b.grid_index = (i-1)*6+n
			b.texrect.pivot_offset_ratio = Vector2(0.5, 0.5)
			b.grid_gradient_rect.texture = ResourceManager.player_grid_gradient_atlastextures[(i-1)*6+n]
			grid_container_texture_buttons.append(b)

func show_parts_screen(part_type: Constants.PartType) -> void:
	switch_to_parts_view()
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
	#var p: HeldPart = hp.duplicate(true)
	var part_size: Vector2i
	var new_part_icons: Array[AtlasTexture]
	var new_slots: Array[Vector2i]
	var slot_icon_dict: Dictionary[Vector2i, AtlasTexture]
	for slot in hp.slots:
		if slot.x > part_size.x:
			part_size.x = slot.x
		if slot.y > part_size.y:
			part_size.y = slot.y
	#for slot in hp.slots:
		#slot.x = part_size.x - slot.x
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
	#var p: HeldPart = hp.duplicate(true)
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
	#var p: HeldPart = hp.duplicate(true)
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

func set_part_to_grid_cell(hp: HeldPart) -> void:
	var pi: PartInstance = PartInstance.new()
	var p: Part = ResourceManager.part_dict[hp.part_id]
	var indices: Array[int] = []
	var selected_cell_pos: Vector2i = Vector2i(selected_grid % 6, floori(float(selected_grid) / 6.0))
	for offset in hp.slots:
		# Make sure we don't wrap around
		if selected_cell_pos.x + offset.x > 5 or selected_cell_pos.y + offset.y > 5:
			return
		# Make sure we're placing in a legal grid space for our frame
		if !ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id].frame_available_slots.has(selected_cell_pos + offset):
			return
		indices.append((selected_cell_pos.y + offset.y) * 6 + offset.x + selected_cell_pos.x)
	pi.part_instance_slots = indices
	pi.part_instance_name = p.part_name
	pi.part_id = p.part_id
	pi.mirrored_h = hp.mirrored_h
	pi.mirrored_v = hp.mirrored_v
	pi.times_rotated = hp.times_rotated
	
	for slot in pi.part_instance_slots:
		for i in range(DataManager.save_data.character.current_frame_build.frame_build_configuration.size()):
			if DataManager.save_data.character.current_frame_build.frame_build_configuration[i].part_instance_slots.has(slot):
				DataManager.save_data.character.current_frame_build.frame_build_configuration.remove_at(i)
				break
	DataManager.save_data.character.current_frame_build.frame_build_configuration.append(pi)
	DataManager.data_changed = true
	draw_grid_cells()

func draw_grid_cells() -> void:
	var contiguous_neighbor_offsets: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]
	var f: Frame = ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id]
	#var margin_size: int = 0
	#if grid_container_texture_buttons.size() > 0:
		#margin_size = floori(grid_container_texture_buttons[0].size.x / 16.0)
	for i in range(grid_container_texture_buttons.size()):
		grid_container_texture_buttons[i].self_modulate = Color.WHITE
		grid_container_texture_buttons[i].grid_gradient_rect.visible = false
		grid_container_texture_buttons[i].texture_normal = selectable_grid_frame
		grid_container_texture_buttons[i].texrect.texture = null
		if !f.frame_available_slots.has(Vector2i(i % 6, floori(float(i) / 6.0))):
			grid_container_texture_buttons[i].self_modulate = Color("282828")
			grid_container_texture_buttons[i].disabled = true
		else:
			grid_container_texture_buttons[i].self_modulate = Color.WHITE
			grid_container_texture_buttons[i].disabled = false
	for pi in DataManager.save_data.character.current_frame_build.frame_build_configuration:
		var hp: HeldPart = HeldPart.new()
		var p: Part = ResourceManager.part_dict[pi.part_id]
		hp.part_icons = ResourceManager.part_image_dict[p.part_id]
		hp.slots = p.part_configuration
		if pi.mirrored_h:
			hp = mirror_slots_horizontally(hp)
		if pi.mirrored_v:
			hp = mirror_slots_vertically(hp)
		for i in range(pi.times_rotated):
			hp = rotate_slots(hp)
		for i in range(pi.part_instance_slots.size()):
			#grid_container_texture_buttons[pi.part_instance_slots[i]].texture_normal = hp.part_icons[i]
			var margin_size = floori(grid_container_texture_buttons[pi.part_instance_slots[i]].grid_clipping_rect.size.x / 16.0)
			var vec: Vector2i = Vector2i(pi.part_instance_slots[i] % 6, floori(float(pi.part_instance_slots[i]) / 6.0)) 
			var margins: Vector4i = Vector4i(margin_size, margin_size, margin_size, margin_size)
			for n in range(contiguous_neighbor_offsets.size()):
				var neighbor_vec: Vector2i = vec + contiguous_neighbor_offsets[n]
				if neighbor_vec.x < 6 and neighbor_vec.x >= 0 and neighbor_vec.y < 6 and neighbor_vec.y >= 0:
					var neighbor: int = (neighbor_vec.y) * 6 + neighbor_vec.x
					if pi.part_instance_slots.has(neighbor):
						match n:
							0:
								margins.w = 0
							1:
								margins.x = 0
							2:
								margins.y = 0
							3:
								margins.z = 0
								
								
			grid_container_texture_buttons[pi.part_instance_slots[i]].grid_clipping_rect.position = Vector2.ZERO
			grid_container_texture_buttons[pi.part_instance_slots[i]].grid_clipping_rect.offset_left = margins.w
			grid_container_texture_buttons[pi.part_instance_slots[i]].grid_clipping_rect.offset_top = margins.x
			grid_container_texture_buttons[pi.part_instance_slots[i]].grid_clipping_rect.offset_right = -margins.y
			grid_container_texture_buttons[pi.part_instance_slots[i]].grid_clipping_rect.offset_bottom = -margins.z
			grid_container_texture_buttons[pi.part_instance_slots[i]].grid_gradient_rect.visible = true
			grid_container_texture_buttons[pi.part_instance_slots[i]].self_modulate = Color.BLACK
			grid_container_texture_buttons[pi.part_instance_slots[i]].texrect.texture = hp.part_icons[i]
			if hp.mirrored_h: 
				#grid_container_texture_buttons[pi.part_instance_slots[i]].flip_h = true
				grid_container_texture_buttons[pi.part_instance_slots[i]].texrect.flip_h = true
			else:
				grid_container_texture_buttons[pi.part_instance_slots[i]].texrect.flip_h = false
			if hp.mirrored_v: 
				#grid_container_texture_buttons[pi.part_instance_slots[i]].flip_v = true
				grid_container_texture_buttons[pi.part_instance_slots[i]].texrect.flip_v = true
			else:
				grid_container_texture_buttons[pi.part_instance_slots[i]].texrect.flip_v = false
			#grid_container_texture_buttons[pi.part_instance_slots[i]].rotation_degrees = hp.times_rotated * 90.0
			grid_container_texture_buttons[pi.part_instance_slots[i]].texrect.rotation_degrees = hp.times_rotated * 90.0
	populate_part_labels()
	draw_armor_grids()
	check_power()
	create_shields_interfaces()

func check_power() -> void:
	for b in grid_container_texture_buttons:
		for texr in b.power_texrects:
			texr.visible = false
	var orthogonal_neighbors: Array[Vector2i] = [Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1)]
	for pi in DataManager.save_data.character.current_frame_build.frame_build_configuration:
		var part: Part = ResourceManager.part_dict[pi.part_id]
		if part.part_type == Constants.PartType.PartReactor:
			var cells_to_check: Array[Vector2i]
			var cells_to_check_next: Array[Vector2i]
			var checked_cells: Array[Vector2i]
			for cell in pi.part_instance_slots:
				var vector: Vector2i = Vector2i(cell % 6, floori(float(cell) / 6.0))
				cells_to_check.append(vector)
			while cells_to_check.size() > 0:
				for cell in cells_to_check:
					for i in range(orthogonal_neighbors.size()):
						var checked_cell: Vector2i = cell + orthogonal_neighbors[i]
						if checked_cell.x >= 0 and checked_cell.y >= 0:
							for p_inst in DataManager.save_data.character.current_frame_build.frame_build_configuration:
								var slot = checked_cell.y*6+checked_cell.x
								if p_inst.part_instance_slots.has(slot):
									if ResourceManager.part_dict[p_inst.part_id].powered:
										if ResourceManager.part_dict[p_inst.part_id].part_type == Constants.PartType.PartProcessor:
											if !checked_cells.has(checked_cell):
												cells_to_check_next.append(checked_cell)
										draw_power_arrow(slot, (i+2)%4)
										break
					checked_cells.append(cell)
				cells_to_check = cells_to_check_next.duplicate()
				cells_to_check_next.clear()

func draw_power_arrow(slot: int, dir: int) -> void:
	grid_container_texture_buttons[slot].power_texrects[dir].visible = true

func create_shields_interfaces() -> void:
	var old_shields: Array[int] = DataManager.save_data.character.current_shields.duplicate()
	DataManager.save_data.character.current_shields.clear()
	for si in shields_interfaces:
		si.queue_free()
	shields_interfaces.clear()
	var frame: Frame = ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id]
	var has_reactor: bool = false
	var largest_reactor_size: Constants.Size = Constants.Size.Ultralight
	for pi in DataManager.save_data.character.current_frame_build.frame_build_configuration:
		var part: Part = ResourceManager.part_dict[pi.part_id]
		if part.part_type == Constants.PartType.PartReactor:
			has_reactor = true
			if part.size > largest_reactor_size:
				largest_reactor_size = part.size
				
	var iter: int = 0
	for pi in DataManager.save_data.character.current_frame_build.frame_build_configuration:
		var part: Part = ResourceManager.part_dict[pi.part_id]
		if part.part_type == Constants.PartType.PartShield and part is Shield:
			var svb: ShieldsVBox = shields_vbox_prefab.instantiate()
			var shield_capacity: int
			if !has_reactor:
				shield_capacity = 0
			elif largest_reactor_size < frame.frame_size:
				shield_capacity = part.capacity - part.capacity_modifier
			elif largest_reactor_size == frame.frame_size:
				shield_capacity = part.capacity
			else:
				shield_capacity = part.capacity + part.capacity_modifier
				
			svb.shield_index = iter
			if old_shields.size() > iter:
				DataManager.save_data.character.current_shields.append(old_shields[iter])
			else:
				DataManager.save_data.character.current_shields.append(shield_capacity)
			svb.set_shield_max_amount(part.part_name, shield_capacity)
			if old_shields.size() > iter:
				svb.set_shield_current_amount(old_shields[iter])
			iter += 1
			shields_interfaces.append(svb)
			defenses_hbox.add_child(svb)

func populate_part_labels() -> void:
	for child in part_effects_vbox.get_children():
		child.queue_free()
	
	var frame: Frame = ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id]
	if frame.frame_feature_name != "":
		var ffl: RichTextLabel = part_effect_label_prefab.instantiate()
		ffl.text = "[b]" + frame.frame_feature_name + ":[/b] " + frame.frame_feature_text
		part_effects_vbox.add_child(ffl) 
	
	var weapons: Array[Part]
	var parts: Array[Part]
	for p in DataManager.save_data.character.current_frame_build.frame_build_configuration:
		var part: Part = ResourceManager.part_dict[p.part_id]
		match part.part_type:
			Constants.PartType.WeaponRanged, Constants.PartType.WeaponExplosive, Constants.PartType.WeaponMelee, Constants.PartType.WeaponEW, Constants.PartType.WeaponMissile:
				weapons.append(part)
			_:
				parts.append(part)
	for w in weapons:
		if w.part_description != null:
			var pel: RichTextLabel = part_effect_label_prefab.instantiate()
			pel.text = w.part_description
			part_effects_vbox.add_child(pel)
	for p in parts:
		if p.part_description != "":
			var pel: RichTextLabel = part_effect_label_prefab.instantiate()
			pel.text = p.part_description
			part_effects_vbox.add_child(pel)

func draw_armor_grids() -> void:
	for child in armor_grid_container.get_children():
		child.queue_free()
	var frame: Frame = ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id]
	for y in range(7):
		for x in range(7):
			if y == 0 or x == 0:
				var control_pad: Control = Control.new()
				control_pad.custom_minimum_size = Vector2(64.0, 64.0)
				armor_grid_container.add_child(control_pad)
			else:
				var pos: Vector2i = Vector2i(x-1,y-1)
				if frame.frame_armor_slots.has(pos):
					var texrect: TextureRect = TextureRect.new()
					texrect.mouse_filter = Control.MOUSE_FILTER_IGNORE
					texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
					texrect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					texrect.size_flags_vertical = Control.SIZE_EXPAND_FILL
					texrect.texture = ArmorSheets.armor_atlases[ArmorSheets.get_tile_by_neighbors(pos, frame, false)]
					armor_grid_container.add_child(texrect)
				elif frame.frame_reinforced_armor_slots.has(pos):
					var texrect: TextureRect = TextureRect.new()
					texrect.mouse_filter = Control.MOUSE_FILTER_IGNORE
					texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
					texrect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					texrect.size_flags_vertical = Control.SIZE_EXPAND_FILL
					texrect.texture = ArmorSheets.reinforced_armor_atlases[ArmorSheets.get_tile_by_neighbors(pos, frame, true)]
					armor_grid_container.add_child(texrect)
				else:
					var texrect: TextureRect = TextureRect.new()
					texrect.mouse_filter = Control.MOUSE_FILTER_IGNORE
					texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
					texrect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					texrect.size_flags_vertical = Control.SIZE_EXPAND_FILL
					texrect.texture = ArmorSheets.armor_atlases[15]
					armor_grid_container.add_child(texrect)

func switch_to_main_view() -> void:
	app_scroll_container.go_to_page(2)
	#main_scroll_container.visible = true
	#parts_scroll_container.visible = false

func switch_to_parts_view() -> void:
	app_scroll_container.go_to_page(3)
	#main_scroll_container.visible = false
	#parts_scroll_container.visible = true

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

func pickup_placed_part(idx: int) -> void:
	var part: Part
	var iter: int = 0
	for pi in DataManager.save_data.character.current_frame_build.frame_build_configuration:
		if pi.part_instance_slots.has(idx):
			change_mode(Mode.Edit)
			part = ResourceManager.part_dict[pi.part_id]
			current_held_part = HeldPart.new()
			current_held_part.part_id = part.part_id
			current_held_part.part_icons = ResourceManager.part_image_dict[part.part_id]
			current_held_part.slots = part.part_configuration
			if pi.mirrored_h:
				current_held_part = mirror_slots_horizontally(current_held_part)
			if pi.mirrored_v:
				current_held_part = mirror_slots_vertically(current_held_part)
			for i in range(pi.times_rotated):
				current_held_part = rotate_slots(current_held_part)
			
			dragged_part.assign_part(current_held_part)
			DataManager.save_data.character.current_frame_build.frame_build_configuration.remove_at(iter)
			draw_grid_cells()
			break
		else:
			iter += 1
			

func update_prem_amt_label() -> void:
	prem_amt_label.text = str(DataManager.save_data.character.premonitions)

func _on_new_lamplighter_button_pressed() -> void:
	DataManager.save_save_data()
	DataManager.save_data = SaveData.new()
	character_name_line_edit.text = ""
	character_callsign_line_edit.text = ""
	frame_name_line_edit.text = ""
	frame_option_button.select(0)
	_on_frame_option_chosen(0)
	#DataManager.save_data.current_frame_build = FrameBuild.new()
	draw_grid_cells()

func _on_load_lamplighter_button_pressed() -> void:
	for child in load_lamplighter_vbox.get_children():
		child.queue_free()
	menu_options_vbox.visible = false
	load_lamplighter_vbox.visible = true
	var saves_array: Array[Dictionary] = DataManager.get_saves_dicts()
	for save in saves_array:
		var lshb: LoadSaveHBox = load_save_hbox_prefab.instantiate()
		lshb.load_save_button.text = save[save.keys()[0]]
		lshb.load_save_button.button_up.connect(_on_save_load_button_pressed.bind(save.keys()[0]))
		lshb.delete_button.button_up.connect(_on_save_delete_button_pressed.bind(save.keys()[0]))
		load_lamplighter_vbox.add_child(lshb)
	var back_button: Button = load_frame_build_button_prefab.instantiate()
	back_button.text = "Close"
	back_button.button_up.connect(func() -> void:
		load_lamplighter_vbox.visible = false
		menu_options_vbox.visible = true)
	load_lamplighter_vbox.add_child(back_button)

func _on_save_load_button_pressed(save_id: String) -> void:
	DataManager.load_save_data(save_id)
	load_lamplighter_vbox.visible = false
	menu_options_vbox.visible = true
	draw_grid_cells()
	app_scroll_container.go_to_page(1)

func _on_lamplighter_loaded() -> void:
	character_name_line_edit.text = DataManager.save_data.character.lamplighter_name
	character_callsign_line_edit.text = DataManager.save_data.character.callsign
	for i in range(attribute_hboxes.size()):
		attribute_hboxes[i].display_attribute_amount()
	for i in range(ResourceManager.frames.size()):
		if ResourceManager.frames[i].frame_id == DataManager.save_data.character.current_frame_build.frame_id:
			frame_option_button.select(i)
			hp_label.text = str(ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id].frame_hp)
			#draw_grid_cells()
			break
	frame_name_line_edit.text = DataManager.save_data.character.current_frame_build.frame_build_name
	draw_grid_cells()
	hp_label.text = str(DataManager.save_data.character.current_hp) + "/" + str(ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id].frame_hp)
	for i in range(shields_interfaces.size()):
		if DataManager.save_data.character.current_shields.size() > i:
			shields_interfaces[i].set_shield_current_amount(DataManager.save_data.character.current_shields[i])
	for i in range(DataManager.save_data.character.current_damage.size()):
		grid_container_texture_buttons[i].current_mode = GridTextureButton.Mode.Normal
		grid_container_texture_buttons[i].damage_label.visible = false
		grid_container_texture_buttons[i].disabled_label.visible = false
		for n in range(DataManager.save_data.character.current_damage[i]):
			grid_container_texture_buttons[i].cycle_labels()
	app_scroll_container.go_to_page(1, true)

func _on_save_delete_button_pressed(save_id: String) -> void:
	DataManager.delete_save_data(save_id)
	_on_load_lamplighter_button_pressed()

func _on_frame_option_chosen(idx: int) -> void:
	DataManager.save_data.character.current_frame_build = FrameBuild.new()
	DataManager.save_data.character.current_frame_build.frame_id = frame_option_dict[idx]
	_reset_frame_damage()
	DataManager.save_data.character.current_shields.clear()
	hp_label.text = str(DataManager.save_data.character.current_hp) + "/" + str(ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id].frame_hp)
	DataManager.data_changed = true
	draw_grid_cells()

func _on_grid_button_clicked(index: int) -> void:
	selected_grid = index
	match current_mode:
		Mode.Normal:
			start_part_pickup = true
		Mode.Edit:
			pass

func _on_grid_button_button_up(index: int) -> void:
	if grid_container_texture_buttons[index].hovered:
		grid_container_texture_buttons[index].cycle_labels()
		DataManager.data_changed = true

func _on_part_chosen(part: HeldPart) -> void:
	set_part_to_grid_cell(part)
	#switch_to_main_view()

func _on_part_grab_started(part: HeldPart) -> void:
	current_held_part = part
	selecting_part_from_parts = true

func _on_part_grabbed(part: HeldPart) -> void:
	change_mode(Mode.Edit)
	dragged_part.assign_part(part)
	switch_to_main_view()

func _on_part_dropped(idx: int) -> void:
	if current_mode == Mode.Edit:
		selected_grid = idx
		set_part_to_grid_cell(current_held_part)
		change_mode(Mode.Normal)
		#switch_to_parts_view()

func _on_part_cleared() -> void:
	change_mode(Mode.Normal)

func _on_grid_cell_hovered(idx: int) -> void:
	hovered_grids.append(idx)

func _on_grid_cell_unhovered(idx: int) -> void:
	for i in range(hovered_grids.size()):
		if hovered_grids[i] == idx:
			hovered_grids.remove_at(i)
			break

func _on_save_frame_build_button_pressed() -> void:
	if frame_name_line_edit.text != "":
		var saved_fb: bool = false
		for fb in DataManager.save_data.frame_builds:
			if fb.frame_build_name == frame_name_line_edit.text:
				fb = DataManager.save_data.character.current_frame_build
				saved_fb = true
				break
		if !saved_fb:
			DataManager.save_data.character.current_frame_build.frame_build_name = frame_name_line_edit.text
			DataManager.save_data.frame_builds.append(DataManager.save_data.character.current_frame_build.duplicate(true))
		DataManager.data_changed = true

func _on_load_frame_build_button_pressed() -> void:
	# Make a menu here with all the frame builds in the save data
	for child in load_frame_build_vbox.get_children():
		child.queue_free()
	for fb in DataManager.save_data.frame_builds:
		var lfbb: Button = load_frame_build_button_prefab.instantiate()
		lfbb.text = fb.frame_build_name
		lfbb.button_up.connect(_on_frame_build_load.bind(fb))
		load_frame_build_vbox.add_child(lfbb)
	for fb in ResourceManager.frame_builds:
		var lfbb: Button = load_frame_build_button_prefab.instantiate()
		lfbb.text = fb.frame_build_name
		lfbb.button_up.connect(_on_frame_build_load.bind(fb.duplicate(true)))
		load_frame_build_vbox.add_child(lfbb)
	var back_button: Button = load_frame_build_button_prefab.instantiate()
	back_button.text = "Back"
	back_button.button_up.connect(func() -> void: load_frame_build_menu.visible = false)
	load_frame_build_vbox.add_child(back_button)
	load_frame_build_menu.visible = true

func _on_frame_build_load(fb: FrameBuild) -> void:
	frame_name_line_edit.text = fb.frame_build_name
	var frame_idx: int
	for i in range(ResourceManager.frames.size()):
		if ResourceManager.frames[i].frame_id == fb.frame_id:
			frame_idx = i
			break
	frame_option_button.select(frame_idx)
	DataManager.save_data.character.current_frame_build = fb
	_reset_frame_damage()
	hp_label.text = str(DataManager.save_data.character.current_hp) + "/" + str(ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id].frame_hp)
	draw_grid_cells()
	load_frame_build_menu.visible = false
	DataManager.data_changed = true

func _on_hp_up_button_pressed() -> void:
	DataManager.save_data.character.current_hp += 1
	hp_label.text = str(DataManager.save_data.character.current_hp) + "/" + str(ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id].frame_hp)
	DataManager.data_changed = true

func _on_hp_down_button_pressed() -> void:
	DataManager.save_data.character.current_hp -= 1
	hp_label.text = str(DataManager.save_data.character.current_hp) + "/" + str(ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id].frame_hp)
	DataManager.data_changed = true

func _on_lamplighter_name_line_edit_changed(s: String) -> void:
	DataManager.save_data.character.lamplighter_name = s
	DataManager.data_changed = true

func _on_callsign_line_edit_changed(s: String) -> void:
	DataManager.save_data.character.callsign = s
	DataManager.data_changed = true

func _on_edit_attributes_button_pressed() -> void:
	for ahb in attribute_hboxes:
		ahb.current_mode = ahb.MODE.Edit if ahb.current_mode == ahb.MODE.Normal else ahb.MODE.Normal
		ahb.attribute_bonus_label.visible = true if ahb.current_mode == ahb.MODE.Edit else false
		ahb.attribute_bonus_vbox.visible = true if ahb.current_mode == ahb.MODE.Edit else false
		ahb.display_attribute_amount()
	edit_attributes_button.text = "Confirm Attributes" if attribute_hboxes[0].current_mode == AttributeHBox.MODE.Edit else "Edit Attributes"
	remaining_attribute_points_label.visible = true if attribute_hboxes[0].current_mode == AttributeHBox.MODE.Edit else false
	_on_attribute_edited()

func _on_attribute_edited() -> void:
	var total_points_spent: int = 0
	for attr in DataManager.save_data.character.attributes:
		total_points_spent += attr
	remaining_attribute_points_label.text = "Remaining Attribute Points: " + str(10 - total_points_spent)

func _on_prem_up_button_pressed() -> void:
	DataManager.save_data.character.premonitions += 1
	DataManager.data_changed = true
	update_prem_amt_label()

func _on_prem_down_button_pressed() -> void:
	DataManager.save_data.character.premonitions -= 1
	DataManager.data_changed = true
	update_prem_amt_label()

func _reset_frame_damage() -> void:
	DataManager.save_data.character.current_damage = SaveData.DEFAULT_DAMAGE_ARRAY.duplicate()
	DataManager.save_data.character.current_hp = ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id].frame_hp
	var frame: Frame = ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id]
	var has_reactor: bool = false
	var largest_reactor_size: Constants.Size = Constants.Size.Ultralight
	for pi in DataManager.save_data.character.current_frame_build.frame_build_configuration:
		var part: Part = ResourceManager.part_dict[pi.part_id]
		if part.part_type == Constants.PartType.PartReactor:
			has_reactor = true
			if part.size > largest_reactor_size:
				largest_reactor_size = part.size
				
	var iter: int = 0
	for pi in DataManager.save_data.character.current_frame_build.frame_build_configuration:
		var part: Part = ResourceManager.part_dict[pi.part_id]
		if part.part_type == Constants.PartType.PartShield and part is Shield:
			var shield_capacity: int
			if !has_reactor:
				shield_capacity = 0
			elif largest_reactor_size < frame.frame_size:
				shield_capacity = part.capacity - part.capacity_modifier
			elif largest_reactor_size == frame.frame_size:
				shield_capacity = part.capacity
			else:
				shield_capacity = part.capacity + part.capacity_modifier
			if DataManager.save_data.character.current_shields.size() > iter:
				DataManager.save_data.character.current_shields[iter] = shield_capacity
			else:
				DataManager.save_data.character.current_shields.append(shield_capacity)
			iter += 1
	for i in range(DataManager.save_data.character.current_damage.size()):
		if grid_container_texture_buttons.size() > i:
			grid_container_texture_buttons[i].current_mode = GridTextureButton.Mode.Normal
			grid_container_texture_buttons[i].damage_label.visible = false
			grid_container_texture_buttons[i].disabled_label.visible = false
	hp_label.text = str(DataManager.save_data.character.current_hp) + "/" + str(ResourceManager.frame_dict[DataManager.save_data.character.current_frame_build.frame_id].frame_hp)
	for i in range(shields_interfaces.size()):
		if DataManager.save_data.character.current_shields.size() > i:
			shields_interfaces[i].set_shield_current_amount(DataManager.save_data.character.current_shields[i])

func _on_ready() -> void:
	done_loading = true

func _debug_save_stock_build() -> void:
	if frame_name_line_edit.text != "":
		DataManager.save_data.character.current_frame_build.frame_build_name = frame_name_line_edit.text
		ResourceSaver.save(DataManager.save_data.character.current_frame_build, "res://frame_builds/stock_builds/frame_build_" + DataManager.save_data.character.current_frame_build.frame_build_name.to_lower() + ".tres")

func _debug_grid_button_clicked() -> void:
	var p: Part = ResourceManager.weapons_melee[0]
	var indices: Array[int] = []
	for offset in p.part_configuration:
		indices.append(offset.y * 6 + offset.x)
	for i in range(indices.size()):
		grid_container_texture_buttons[indices[i]].texture_normal = ResourceManager.part_image_dict[p.part_id][i]
		#grid_container_texture_buttons[indices[i]].pivot_offset_ratio = Vector2(0.5, 0.5)
		#grid_container_texture_buttons[indices[i]].rotation_degrees = 90.0
