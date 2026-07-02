extends ColorRect
class_name MainScene

const LONG_PRESS_TIMER: float = 0.75
enum Mode {Normal, Edit}

var label_prefab: PackedScene = preload("res://scenes/grid_label.tscn")
var grid_texture_button_prefab: PackedScene = preload("res://scenes/grid_texture_button.tscn")
var empty_grid_frame: Texture2D = preload("res://assets/empty_grid_frame.png")
var selectable_grid_frame: Texture2D = preload("res://assets/ui/EmptyGridSpace.png")
var part_picker_vbox_prefab: PackedScene = preload("res://scenes/part_picker_v_box.tscn")
var part_effect_label_prefab: PackedScene = preload("res://scenes/part_effect_label.tscn")
var load_frame_build_button_prefab: PackedScene = preload("res://scenes/load_frame_build_button.tscn")

@export var app_scroll_container: AppScrollContainer
@export_group("Menu")
@export var menu_scroll_container: ScrollContainer
@export var menu_load_button: Button
@export_group("Main Screen")
@export var main_scroll_container: ScrollContainer
@export var character_name_line_edit: LineEdit
@export var character_callsign_line_edit: LineEdit
@export var frame_option_button: OptionButton
@export var frame_name_line_edit: LineEdit
@export var grid_grid_container: GridContainer
@export var armor_grid_container: GridContainer
@export var part_effects_vbox: VBoxContainer
@export var save_frame_build_button: Button
@export var load_frame_build_button: Button
@export_group("Parts Screen")
@export var parts_scroll_container: ScrollContainer
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
@export var frames_tab_button: Button
@export var parts_tab_button: Button
@export var load_frame_build_menu: ColorRect
@export var load_frame_build_vbox: VBoxContainer

var save_data: SaveData

var current_frame_build: FrameBuild
var current_held_part: HeldPart

var grid_container_texture_buttons: Array[GridTextureButton]

var current_mode: Mode = Mode.Normal
var selected_grid: int
var hovered_grids: Array[int]

var frame_option_dict: Dictionary[int, String]

var button_held: bool = false
var mouse_button_pressed_timer: float = 0.0
var start_part_pickup: bool = false
var selecting_part_from_parts: bool = false

func _ready() -> void:
	save_data = SaveData.new()
	
	menu_tab_button.button_up.connect(app_scroll_container.go_to_page.bind(0))
	frames_tab_button.button_up.connect(app_scroll_container.go_to_page.bind(1))
	parts_tab_button.button_up.connect(app_scroll_container.go_to_page.bind(2))
	
	save_frame_build_button.button_up.connect(_on_save_frame_build_button_pressed)
	load_frame_build_button.button_up.connect(_on_load_frame_build_button_pressed)
	
	current_frame_build = FrameBuild.new()
	populate_frame_option_button()
	frame_option_button.item_selected.connect(_on_frame_option_chosen)
	frame_option_button.select(0)
	frame_option_button.item_selected.emit(0)
	populate_grid()
	
	weapons_ranged_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponRanged))
	weapons_explosive_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponExplosive))
	weapons_melee_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponMelee))
	weapons_ew_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponEW))
	weapons_missiles_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.WeaponMissile))
	parts_reactors_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartReactor))
	parts_thrusters_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartThruster))
	parts_processors_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartProcessor))
	parts_shields_tab_button.button_up.connect(show_parts_screen.bind(Constants.PartType.PartShield))

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
			b.button_up.connect(_on_grid_button_button_up.bind((i - 1) * 6 + n))
			if !f.frame_available_slots.has(Vector2i(n, i - 1)):
				b.self_modulate = Color("282828")
				b.disabled = true
			b.mouse_entered.connect(_on_grid_cell_hovered.bind((i - 1) * 6 + n))
			b.mouse_exited.connect(_on_grid_cell_unhovered.bind((i - 1) * 6 + n))
			b.grid_texture_button_up.connect(_on_part_dropped.bind((i - 1) * 6 + n))
			b.pivot_offset_ratio = Vector2(0.5, 0.5)
			grid_container_texture_buttons.append(b)

func show_parts_screen(part_type: Constants.PartType) -> void:
	switch_to_parts_view()
	populate_parts_screen(part_type)

func populate_parts_screen(part_type: Constants.PartType) -> void:
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
		
		var held_part: HeldPart = HeldPart.new()
		held_part.part_id = part.part_id
		held_part.slots = part.part_configuration
		held_part.part_icons = part.part_icons
		match part.part_type:
			Constants.PartType.PartProcessor:
				draw_part(held_part, false, false, 0)
			Constants.PartType.WeaponRanged, Constants.PartType.WeaponExplosive, Constants.PartType.WeaponMelee, Constants.PartType.WeaponEW, Constants.PartType.WeaponMissile:
				for i in range(4):
					var hp: HeldPart = held_part.duplicate(true)
					match i:
						0:
							draw_part(hp, false, false, 0)
						1:
							hp = mirror_slots_horizontally(hp)
							draw_part(hp, true, false, 0)
						2:
							hp = mirror_slots_vertically(hp)
							draw_part(hp, false, true, 0)
						3:
							hp = mirror_slots_horizontally(mirror_slots_vertically(hp))
							draw_part(hp, true, true, 0)
			Constants.PartType.PartReactor, Constants.PartType.PartThruster, Constants.PartType.PartShield:
				for i in range(4):
					var hp: HeldPart = held_part.duplicate(true)
					match i:
						0:
							draw_part(hp, false, false, 0)
						1:
							rotate_slots(hp)
							draw_part(hp, false, false, 1)
						2:
							rotate_slots(rotate_slots(hp))
							draw_part(hp, false, false, 2)
						3:
							rotate_slots(rotate_slots(rotate_slots(hp)))
							draw_part(hp, false, false, 3)
		
		

func draw_part(hp: HeldPart, mirrored_horizontally: bool, mirrored_vertically: bool, times_rotated: int) -> void:
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
	#ppvb.name_button.button_down.connect(_on_part_grabbed.bind(hp))
	ppvb.part_picker_button_down.connect(_on_part_grab_started.bind(hp))
	parts_grid_container.add_child(ppvb)

func mirror_slots_horizontally(hp: HeldPart) -> HeldPart:
	#var p: HeldPart = hp.duplicate(true)
	var part_size: Vector2i
	var new_part_icons: Array[Texture2D]
	var new_slots: Array[Vector2i]
	var slot_icon_dict: Dictionary[Vector2i, Texture2D]
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
	var new_part_icons: Array[Texture2D]
	var new_slots: Array[Vector2i]
	var slot_icon_dict: Dictionary[Vector2i, Texture2D]
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
	var slot_icon_dict: Dictionary[Vector2i, Texture2D]
	var new_part_icons: Array[Texture2D]
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
		if !ResourceManager.frame_dict[current_frame_build.frame_id].frame_available_slots.has(selected_cell_pos + offset):
			return
		indices.append((selected_cell_pos.y + offset.y) * 6 + offset.x + selected_cell_pos.x)
	pi.part_instance_slots = indices
	pi.part_instance_name = p.part_name
	pi.part_id = p.part_id
	pi.mirrored_h = hp.mirrored_h
	pi.mirrored_v = hp.mirrored_v
	pi.times_rotated = hp.times_rotated
	pi.part_instance_id = UuidGenerator.generate_uuid()
	
	for slot in pi.part_instance_slots:
		for i in range(current_frame_build.frame_build_configuration.size()):
			if current_frame_build.frame_build_configuration[i].part_instance_slots.has(slot):
				current_frame_build.frame_build_configuration.remove_at(i)
				break
	current_frame_build.frame_build_configuration.append(pi)
	draw_grid_cells()

func draw_grid_cells() -> void:
	var f: Frame = ResourceManager.frame_dict[current_frame_build.frame_id]
	for i in range(grid_container_texture_buttons.size()):
		grid_container_texture_buttons[i].texture_normal = selectable_grid_frame
		if !f.frame_available_slots.has(Vector2i(i % 6, floori(float(i) / 6.0))):
			grid_container_texture_buttons[i].self_modulate = Color("282828")
			grid_container_texture_buttons[i].disabled = true
		else:
			grid_container_texture_buttons[i].self_modulate = Color.WHITE
			grid_container_texture_buttons[i].disabled = false
	for pi in current_frame_build.frame_build_configuration:
		var hp: HeldPart = HeldPart.new()
		var p: Part = ResourceManager.part_dict[pi.part_id]
		hp.part_icons = p.part_icons
		hp.slots = p.part_configuration
		if pi.mirrored_h:
			hp = mirror_slots_horizontally(hp)
		if pi.mirrored_v:
			hp = mirror_slots_vertically(hp)
		for i in range(pi.times_rotated):
			hp = rotate_slots(hp)
		for i in range(pi.part_instance_slots.size()):
			grid_container_texture_buttons[pi.part_instance_slots[i]].texture_normal = hp.part_icons[i]
			if hp.mirrored_h: 
				grid_container_texture_buttons[pi.part_instance_slots[i]].flip_h = true
			if hp.mirrored_v: 
				grid_container_texture_buttons[pi.part_instance_slots[i]].flip_v = true
			grid_container_texture_buttons[pi.part_instance_slots[i]].rotation_degrees = hp.times_rotated * 90.0
	populate_part_labels()
	draw_armor_grids()

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

func switch_to_main_view() -> void:
	app_scroll_container.go_to_page(1)
	#main_scroll_container.visible = true
	#parts_scroll_container.visible = false

func switch_to_parts_view() -> void:
	app_scroll_container.go_to_page(2)
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
	for pi in current_frame_build.frame_build_configuration:
		if pi.part_instance_slots.has(idx):
			change_mode(Mode.Edit)
			part = ResourceManager.part_dict[pi.part_id]
			current_held_part = HeldPart.new()
			current_held_part.part_id = part.part_id
			current_held_part.slots = part.part_configuration
			dragged_part.assign_part(current_held_part)
			current_frame_build.frame_build_configuration.remove_at(iter)
			draw_grid_cells()
			break
		else:
			iter += 1
			

func _on_frame_option_chosen(idx: int) -> void:
	current_frame_build = FrameBuild.new()
	current_frame_build.frame_id = frame_option_dict[idx]
	draw_grid_cells()

func _on_grid_button_clicked(index: int) -> void:
	selected_grid = index
	match current_mode:
		Mode.Normal:
			start_part_pickup = true
		Mode.Edit:
			pass

func _on_grid_button_button_up(index: int) -> void:
	if !button_held:
		grid_container_texture_buttons[index].cycle_labels()

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
		for fb in save_data.frame_builds:
			if fb.frame_build_name == frame_name_line_edit.text:
				fb = current_frame_build
				saved_fb = true
				break
		if !saved_fb:
			current_frame_build.frame_build_name = frame_name_line_edit.text
			save_data.frame_builds.append(current_frame_build.duplicate(true))

func _on_load_frame_build_button_pressed() -> void:
	# Make a menu here with all the frame builds in the save data
	for child in load_frame_build_vbox.get_children():
		child.queue_free()
	for fb in save_data.frame_builds:
		var lfbb: Button = load_frame_build_button_prefab.instantiate()
		lfbb.text = fb.frame_build_name
		lfbb.button_up.connect(_on_frame_build_load.bind(fb))
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
	current_frame_build = fb
	draw_grid_cells()
	load_frame_build_menu.visible = false

func _debug_grid_button_clicked() -> void:
	var p: Part = ResourceManager.weapons_melee[0]
	var indices: Array[int] = []
	for offset in p.part_configuration:
		indices.append(offset.y * 6 + offset.x)
	for i in range(indices.size()):
		grid_container_texture_buttons[indices[i]].texture_normal = p.part_icons[i]
		#grid_container_texture_buttons[indices[i]].pivot_offset_ratio = Vector2(0.5, 0.5)
		#grid_container_texture_buttons[indices[i]].rotation_degrees = 90.0
