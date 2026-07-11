extends ScrollContainer
class_name FrameBuilderFrameTabMenu

var frame_select_dropdown_button_prefab: PackedScene = preload("res://scenes/frame_select_dropdown_button.tscn")
var label_prefab: PackedScene = preload("res://scenes/grid_label.tscn")
var grid_texture_button_prefab: PackedScene = preload("res://scenes/grid_texture_button.tscn")
var selectable_grid_frame: Texture2D = preload("res://assets/ui/EmptyGridSpace.png")
var part_effect_label_prefab: PackedScene = preload("res://scenes/part_effect_label.tscn")
var load_frame_build_button_prefab: PackedScene = preload("res://scenes/load_frame_build_button.tscn")

@export var main_script: CustomFrameBuildMode
@export var part_grid_interface: PartGridInterface
@export var frame_dropdown_button: Button
@export var frame_dropdown_panel_container: PanelContainer
@export var frame_dropdown_vbox: VBoxContainer
@export var frame_name_line_edit: LineEdit
@export var hp_label: Label
@export var grid_grid_container: GridContainer
@export var armor_grid_container: GridContainer
@export var defenses_hbox: HFlowContainer
@export var part_effects_vbox: VBoxContainer
@export var player_build_toggle: CheckButton
@export var save_frame_build_button: Button
@export var load_frame_build_button: Button
@export var load_frame_build_menu: ColorRect
@export var load_frame_build_vbox: VBoxContainer

var current_frame_build: FrameBuild

var is_dragging: bool = false
var swipe_speed = 1.0

var frame_option_dict: Dictionary[int, String]
var frame_select_panel_open: bool = false

var grid_container_texture_buttons: Array[GridTextureButton]
var shield_labels: Array[Label]

func _ready() -> void:
	populate_frame_option_button()
	_on_frame_option_chosen(0)
	frame_dropdown_button.button_up.connect(_on_frame_select_button_clicked)
	populate_grid()
	
	frame_name_line_edit.text_changed.connect(_on_frame_name_text_changed)
	save_frame_build_button.button_up.connect(_on_save_build_button_pressed)
	load_frame_build_button.button_up.connect(_on_load_build_button_pressed)

func _input(event: InputEvent) -> void:
	if frame_select_panel_open:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
				close_frame_select_panel()
				get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.index == 0:
			is_dragging = event.pressed
	if event is InputEventScreenDrag:
		if is_dragging:
			scroll_vertical -= event.relative.y * swipe_speed

func populate_frame_option_button() -> void:
	for child in frame_dropdown_vbox.get_children():
		child.queue_free()
	frame_option_dict.clear()
	for i in range(ResourceManager.frames.size()):
		#if !ResourceManager.frames[i].unusual:
		frame_option_dict[i] = ResourceManager.frames[i].frame_id
		
		var fsdb: FrameSelectDropdownButton = frame_select_dropdown_button_prefab.instantiate()
		fsdb.text = ResourceManager.frames[i].frame_name
		fsdb.idx = i
		fsdb.frame_chosen.connect(_on_frame_option_chosen)
		frame_dropdown_vbox.add_child(fsdb)

func open_frame_select_panel() -> void:
	frame_dropdown_panel_container.size = Vector2(frame_dropdown_button.size.x, frame_dropdown_vbox.size.y)
	frame_dropdown_panel_container.position = Vector2(frame_dropdown_button.global_position.x, frame_dropdown_button.size.y + frame_dropdown_button.global_position.y)
	frame_dropdown_panel_container.visible = true
	frame_select_panel_open = true

func close_frame_select_panel() -> void:
	frame_dropdown_panel_container.visible = false
	frame_select_panel_open = false

func populate_grid() -> void:
	var f: Frame = ResourceManager.frame_dict[current_frame_build.frame_id]
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

func draw_grid_cells() -> void:
	var contiguous_neighbor_offsets: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]
	var f: Frame = ResourceManager.frame_dict[current_frame_build.frame_id]
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
	for pi in current_frame_build.frame_build_configuration:
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
			
			match p.part_type:
				Constants.PartType.PartReactor:
					grid_container_texture_buttons[pi.part_instance_slots[i]].grid_gradient_rect.self_modulate = Color("8e24aa")
				Constants.PartType.PartThruster:
					grid_container_texture_buttons[pi.part_instance_slots[i]].grid_gradient_rect.self_modulate = Color("d01716")
				Constants.PartType.PartShield:
					grid_container_texture_buttons[pi.part_instance_slots[i]].grid_gradient_rect.self_modulate = Color("03a9f4")
				_:
					grid_container_texture_buttons[pi.part_instance_slots[i]].grid_gradient_rect.self_modulate = Color("e8008c")
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

func populate_part_labels() -> void:
	for child in part_effects_vbox.get_children():
		child.queue_free()
	
	var frame: Frame = ResourceManager.frame_dict[current_frame_build.frame_id]
	if frame.frame_feature_name != "":
		var ffl: RichTextLabel = part_effect_label_prefab.instantiate()
		ffl.text = "[b]" + frame.frame_feature_name + ":[/b] " + frame.frame_feature_text
		part_effects_vbox.add_child(ffl) 
	
	var weapons: Array[Part]
	var parts: Array[Part]
	for p in current_frame_build.frame_build_configuration:
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
	var frame: Frame = ResourceManager.frame_dict[current_frame_build.frame_id]
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

func check_power() -> void:
	for b in grid_container_texture_buttons:
		for texr in b.power_texrects:
			texr.visible = false
	var orthogonal_neighbors: Array[Vector2i] = [Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1)]
	for pi in current_frame_build.frame_build_configuration:
		var part: Part = ResourceManager.part_dict[pi.part_id]
		var connected_tags: Array[String] = part.connected_tags
		if part.tags.has("reactor"):
			var cells_to_check: Array[Vector2i]
			var cells_to_check_next: Array[Vector2i]
			var checked_cells: Array[Vector2i]
			var current_pi: PartInstance
			var current_part: Part
			for cell in pi.part_instance_slots:
				var vector: Vector2i = Vector2i(cell % 6, floori(float(cell) / 6.0))
				cells_to_check.append(vector)
			while cells_to_check.size() > 0:
				for cell in cells_to_check:
					for p_inst in current_frame_build.frame_build_configuration:
						if p_inst.part_instance_slots.has(cell.y*6+cell.x):
							current_pi = p_inst
							current_part = ResourceManager.part_dict[p_inst.part_id]
							break
					for i in range(orthogonal_neighbors.size()):
						var checked_cell: Vector2i = cell + orthogonal_neighbors[i]
						if checked_cell.x >= 0 and checked_cell.y >= 0 and checked_cell.x < 6 and checked_cell.y < 6:
							for p_inst in current_frame_build.frame_build_configuration:
								if p_inst != current_pi:
									var slot = checked_cell.y*6+checked_cell.x
									if p_inst.part_instance_slots.has(slot):
										var checked_part: Part = ResourceManager.part_dict[p_inst.part_id]
										var anti_tags: Array[String]
										for tag in current_part.connected_tags:
											if tag.begins_with("-"):
												anti_tags.append(tag.trim_prefix("-"))
										var anti_tagged: bool = false
										for ct in checked_part.tags:
											if anti_tags.has(ct):
												anti_tagged = true
												break
										if !anti_tagged:
											for ct in current_part.connected_tags:
												if checked_part.tags.has(ct):
													if checked_part.tags.has("processor"):
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
	for sl in shield_labels:
		sl.queue_free()
	shield_labels.clear()
	var frame: Frame = ResourceManager.frame_dict[current_frame_build.frame_id]
	var has_reactor: bool = false
	var largest_reactor_size: Constants.Size = Constants.Size.Ultralight
	for pi in current_frame_build.frame_build_configuration:
		var part: Part = ResourceManager.part_dict[pi.part_id]
		if part.part_type == Constants.PartType.PartReactor:
			has_reactor = true
			if part.size > largest_reactor_size:
				largest_reactor_size = part.size
				
	for pi in current_frame_build.frame_build_configuration:
		var part: Part = ResourceManager.part_dict[pi.part_id]
		if part.part_type == Constants.PartType.PartShield and part is Shield:
			var sl: Label = label_prefab.instantiate()
			var shield_capacity: int
			if !has_reactor:
				shield_capacity = 0
			elif largest_reactor_size < frame.frame_size:
				shield_capacity = part.capacity - part.capacity_modifier_negative
			elif largest_reactor_size == frame.frame_size:
				shield_capacity = part.capacity
			else:
				shield_capacity = part.capacity + part.capacity_modifier_positive
				
			sl.text = part.part_name + ": " + str(shield_capacity)
			shield_labels.append(sl)
			defenses_hbox.add_child(sl)

func set_part_to_grid_cell(hp: HeldPart) -> void:
	var pi: PartInstance = PartInstance.new()
	var p: Part = ResourceManager.part_dict[hp.part_id]
	var indices: Array[int] = []
	var selected_cell_pos: Vector2i = Vector2i(part_grid_interface.selected_grid % 6, floori(float(part_grid_interface.selected_grid) / 6.0))
	for offset in hp.slots:
		# Make sure we don't wrap around
		if selected_cell_pos.x + offset.x > 5 or selected_cell_pos.y + offset.y > 5:
			return
		# Make sure we're placing in a legal grid space for our frame
		if !ResourceManager.frame_dict[current_frame_build.frame_id].frame_available_slots.has(selected_cell_pos + offset):
			return
		indices.append((selected_cell_pos.y + offset.y) * 6 + offset.x + selected_cell_pos.x)
	pi.part_instance_slots = indices
	pi.part_instance_name = p.part_name
	pi.part_id = p.part_id
	pi.mirrored_h = hp.mirrored_h
	pi.mirrored_v = hp.mirrored_v
	pi.times_rotated = hp.times_rotated
	
	for slot in pi.part_instance_slots:
		for i in range(current_frame_build.frame_build_configuration.size()):
			if current_frame_build.frame_build_configuration[i].part_instance_slots.has(slot):
				current_frame_build.frame_build_configuration.remove_at(i)
				break
	current_frame_build.frame_build_configuration.append(pi)
	draw_grid_cells()

func pickup_placed_part(idx: int) -> void:
	var part: Part
	var iter: int = 0
	for pi in current_frame_build.frame_build_configuration:
		if pi.part_instance_slots.has(idx):
			part_grid_interface.change_mode(part_grid_interface.Mode.Edit)
			part = ResourceManager.part_dict[pi.part_id]
			part_grid_interface.current_held_part = HeldPart.new()
			part_grid_interface.current_held_part.part_id = part.part_id
			part_grid_interface.current_held_part.part_icons = ResourceManager.part_image_dict[part.part_id]
			part_grid_interface.current_held_part.slots = part.part_configuration
			if pi.mirrored_h:
				part_grid_interface.current_held_part = mirror_slots_horizontally(part_grid_interface.current_held_part)
			if pi.mirrored_v:
				part_grid_interface.current_held_part = mirror_slots_vertically(part_grid_interface.current_held_part)
			for i in range(pi.times_rotated):
				part_grid_interface.current_held_part = rotate_slots(part_grid_interface.current_held_part)
			
			part_grid_interface.dragged_part.assign_part(part_grid_interface.current_held_part)
			current_frame_build.frame_build_configuration.remove_at(iter)
			draw_grid_cells()
			break
		else:
			iter += 1

func save_build() -> void:
	if frame_name_line_edit.text != "":
		ResourceManager.save_frame_build_to_frame_builds_json(DataManager.currently_edited_data_pack, current_frame_build)

func load_build(fb: FrameBuild) -> void:
	var frame_idx: int
	for i in range(ResourceManager.frames.size()):
		if ResourceManager.frames[i].frame_id == fb.frame_id:
			frame_idx = i
			break
	_on_frame_option_chosen(frame_idx)
	current_frame_build = fb
	frame_name_line_edit.text = fb.frame_build_name
	player_build_toggle.button_pressed = fb.player_build
	draw_grid_cells()
	load_frame_build_menu.visible = false

func populate_load_frame_build_menu() -> void:
	for child in load_frame_build_vbox.get_children():
		child.queue_free()
	for fb in ResourceManager.get_frame_builds_from_pack(DataManager.currently_edited_data_pack):
		var lfbb: Button = load_frame_build_button_prefab.instantiate()
		lfbb.text = fb.frame_build_name
		lfbb.button_up.connect(_on_frame_build_load.bind(fb))
		load_frame_build_vbox.add_child(lfbb)
	var back_button: Button = load_frame_build_button_prefab.instantiate()
	back_button.text = "Back"
	back_button.button_up.connect(func() -> void: load_frame_build_menu.visible = false)
	load_frame_build_vbox.add_child(back_button)
	load_frame_build_menu.visible = true

func switch_to_main_view() -> void:
	main_script.go_to_page(1)

func _on_frame_option_chosen(idx: int) -> void:
	close_frame_select_panel()
	current_frame_build = FrameBuild.new()
	current_frame_build.frame_id = frame_option_dict[idx]
	hp_label.text = "HP: " + str(ResourceManager.frame_dict[current_frame_build.frame_id].frame_hp)
	frame_dropdown_button.text = ResourceManager.frame_dict[frame_option_dict[idx]].frame_name
	draw_grid_cells()

func _on_grid_button_clicked(index: int) -> void:
	part_grid_interface.selected_grid = index
	part_grid_interface.start_part_pickup = true

func _on_grid_cell_hovered(idx: int) -> void:
	part_grid_interface.hovered_grids.append(idx)

func _on_grid_cell_unhovered(idx: int) -> void:
	for i in range(part_grid_interface.hovered_grids.size()):
		if part_grid_interface.hovered_grids[i] == idx:
			part_grid_interface.hovered_grids.remove_at(i)
			break

func _on_part_dropped(idx: int) -> void:
	part_grid_interface.selected_grid = idx
	set_part_to_grid_cell(part_grid_interface.current_held_part)

func _on_frame_select_button_clicked() -> void:
	if frame_dropdown_panel_container.visible:
		close_frame_select_panel()
	else:
		open_frame_select_panel()

func _on_frame_name_text_changed(new_text: String) -> void:
	current_frame_build.frame_build_name = new_text

func _on_save_build_button_pressed() -> void:
	save_build()

func _on_load_build_button_pressed() -> void:
	populate_load_frame_build_menu()

func _on_frame_build_load(fb: FrameBuild) -> void:
	load_build(fb)
