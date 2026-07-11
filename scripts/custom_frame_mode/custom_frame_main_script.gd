extends ColorRect
class_name CustomFrameMode

enum ARMORMODE{None, Armor}

var label_prefab: PackedScene = preload("res://scenes/grid_label.tscn")
var grid_button_prefab: PackedScene = preload("res://scenes/custom_frame_mode/custom_frame_grid_texture_button.tscn")
var armor_grid_button_prefab: PackedScene = preload("res://scenes/custom_frame_mode/custom_frame_armor_grid_texture_button.tscn")

@export var signal_bus: CustomFrameModeSignalBus

@export var scroll_container: ScrollContainer
@export var frame_name_line_edit: LineEdit
@export var frame_id_line_edit: LineEdit
@export var frame_size_button: Button
@export var frame_size_popup_panel: PanelContainer
@export var frame_size_vbox: VBoxContainer
@export var frame_size_light_button: Button
@export var frame_size_medium_button: Button
@export var frame_size_heavy_button: Button
@export var frame_size_ultra_button: Button
@export var grid: GridContainer
@export var armor_grid: GridContainer
@export var customize_armor_toggle_button: Button
@export var frame_hp_label: Label
@export var frame_hp_down_button: Button
@export var frame_hp_up_button: Button
@export var frame_titan_toggle: CheckButton
@export var frame_unusual_toggle: CheckButton
@export var frame_feature_is_elite_toggle: CheckButton
@export var frame_ability_name_line_edit: LineEdit
@export var frame_ability_description_text_edit: TextEdit
@export var save_frame_button: Button
@export var load_frame_button: Button
@export var reset_frame_button: Button

var page_width: int
var grid_buttons: Array[CustomFrameGridTextureButton]
var armor_grid_buttons: Array[CustomFrameArmorGridTextureButton]
var current_armor_mode: ARMORMODE = ARMORMODE.None
var armor_array: Array[int]
var armor_pos_array: Array[Vector2i]
var reinforced_armor_pos_array: Array[Vector2i]
var frame_size: Constants.Size = Constants.Size.Light

func _ready() -> void:
	get_window().size_changed.connect(setup)
	setup()
	
	populate_grid()
	armor_array.resize(36)
	armor_array.fill(0)
	
	frame_size_button.button_up.connect(_frame_size_dropdown_button_pressed)
	frame_size_light_button.button_up.connect(choose_frame_size.bind(Constants.Size.Light))
	frame_size_medium_button.button_up.connect(choose_frame_size.bind(Constants.Size.Medium))
	frame_size_heavy_button.button_up.connect(choose_frame_size.bind(Constants.Size.Heavy))
	frame_size_ultra_button.button_up.connect(choose_frame_size.bind(Constants.Size.Ultra))
	
	customize_armor_toggle_button.button_up.connect(_customize_armor_toggle_button_pressed)
	signal_bus.armor_grid_selected.connect(update_armor_array)
	
	frame_hp_down_button.button_up.connect(_hp_down_button_pressed)
	frame_hp_up_button.button_up.connect(_hp_up_button_pressed)
	save_frame_button.button_up.connect(_save_button_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if !event.pressed:
				frame_size_popup_panel.visible = false
	if event is InputEventScreenTouch:
		if event.index == 0:
			if !event.pressed:
				frame_size_popup_panel.visible = false

func populate_grid() -> void:
	var topleft_label: Label = label_prefab.instantiate()
	grid.add_child(topleft_label)
	var a_topleft_label: Label = label_prefab.instantiate()
	armor_grid.add_child(a_topleft_label)
	for i in range(6):
		var l: Label = label_prefab.instantiate()
		l.text = str((i+1)*10)
		grid.add_child(l)
		var a_l: Label = label_prefab.instantiate()
		armor_grid.add_child(a_l)
		
	for i in range(6):
		var side_label: Label = label_prefab.instantiate()
		side_label.text = str(i+1)
		grid.add_child(side_label)
		var a_side_label: Label = label_prefab.instantiate()
		armor_grid.add_child(a_side_label)
		for n in range(6):
			var tb: CustomFrameGridTextureButton = grid_button_prefab.instantiate()
			tb.index = i*6+n
			grid_buttons.append(tb)
			grid.add_child(tb)
			
			var a_tb: CustomFrameArmorGridTextureButton = armor_grid_button_prefab.instantiate()
			a_tb.index = i*6+n
			a_tb.signal_bus = signal_bus
			armor_grid_buttons.append(a_tb)
			armor_grid.add_child(a_tb)

func update_armor_array(idx: int, mode: int) -> void:
	armor_array[idx] = mode
	var pos: Vector2i = Vector2i(idx%6, floori(float(idx)/6.0))
	match mode:
		0:
			for i in range(armor_pos_array.size()):
				if armor_pos_array[i] == pos:
					armor_pos_array.remove_at(i)
					break
			for i in range(reinforced_armor_pos_array.size()):
				if reinforced_armor_pos_array[i] == pos:
					reinforced_armor_pos_array.remove_at(i)
					break
		1:
			for i in range(armor_pos_array.size()):
				if armor_pos_array[i] == pos:
					armor_pos_array.remove_at(i)
					break
			armor_pos_array.append(pos)
			for i in range(reinforced_armor_pos_array.size()):
				if reinforced_armor_pos_array[i] == pos:
					reinforced_armor_pos_array.remove_at(i)
					break
		2:
			for i in range(armor_pos_array.size()):
				if armor_pos_array[i] == pos:
					armor_pos_array.remove_at(i)
					break
			for i in range(reinforced_armor_pos_array.size()):
				if reinforced_armor_pos_array[i] == pos:
					reinforced_armor_pos_array.remove_at(i)
					break
			reinforced_armor_pos_array.append(pos)
	draw_armor_grids()

func draw_armor_grids() -> void:
	for tb in armor_grid_buttons:
		var pos: Vector2i = Vector2i(tb.index%6, floori(float(tb.index) / 6.0))
		match tb.mode:
			tb.MODE.None:
				tb.texture_normal = null
			tb.MODE.Armor:
				tb.texture_normal = ArmorSheets.armor_atlases[ArmorSheets.get_tile_by_neighbors_array(pos, armor_pos_array, reinforced_armor_pos_array, false)]
			tb.MODE.Reinforced:
				tb.texture_normal = ArmorSheets.reinforced_armor_atlases[ArmorSheets.get_tile_by_neighbors_array(pos, armor_pos_array, reinforced_armor_pos_array, true)]
	

func setup() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.SCREEN_PRIMARY)
	#get_window().size = screen_size
	get_window().content_scale_size = screen_size
	
	if !OS.has_feature("mobile") and !OS.has_feature("web_android") and !OS.has_feature("web_ios"):
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_width = screen_size.x
	scroll_container.custom_minimum_size.x = page_width

func toggle_frame_size_popup() -> void:
	if !frame_size_popup_panel.visible:
		frame_size_popup_panel.size = Vector2(frame_size_button.size.x, frame_size_vbox.size.y)
		frame_size_popup_panel.position = Vector2(frame_size_button.global_position.x, frame_size_button.global_position.y + frame_size_button.size.y)
		frame_size_popup_panel.visible = true
	else:
		frame_size_popup_panel.visible = false

func choose_frame_size(new_size: Constants.Size) -> void:
	frame_size = new_size
	match new_size:
		Constants.Size.Light:
			frame_size_button.text = "Frame Size: Light"
		Constants.Size.Medium:
			frame_size_button.text = "Frame Size: Medium"
		Constants.Size.Heavy:
			frame_size_button.text = "Frame Size: Heavy"
		Constants.Size.Ultra:
			frame_size_button.text = "Frame Size: Ultra"

func toggle_armor_mode() -> void:
	if current_armor_mode == ARMORMODE.None:
		current_armor_mode = ARMORMODE.Armor
		for tb in armor_grid_buttons:
			tb.mouse_filter = Control.MOUSE_FILTER_STOP
		customize_armor_toggle_button.text = "Customize Slots"
	else:
		current_armor_mode = ARMORMODE.None
		for tb in armor_grid_buttons:
			tb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		customize_armor_toggle_button.text = "Customize Armor"

func save_frame_data() -> void:
	if frame_name_line_edit.text.length() > 0 and frame_id_line_edit.text.length() > 0:
		var frame: Frame = Frame.new()
		frame.frame_name = frame_name_line_edit.text
		frame.frame_id = frame_id_line_edit.text
		for tb in grid_buttons:
			if tb.selected:
				frame.frame_available_slots.append(Vector2i(tb.index%6, floori(float(tb.index) / 6.0)))
		frame.frame_feature_name = frame_ability_name_line_edit.text
		frame.frame_feature_text = frame_ability_description_text_edit.text
		frame.frame_feature_is_elite = frame_feature_is_elite_toggle.button_pressed
		frame.frame_hp = frame_hp_label.text.to_int()
		frame.frame_armor_slots = armor_pos_array
		frame.frame_reinforced_armor_slots = reinforced_armor_pos_array
		frame.frame_size = frame_size
		frame.unusual = frame_unusual_toggle.button_pressed
		frame.titan = frame_titan_toggle.button_pressed
		
		ResourceManager.save_frame_to_frames_json("custom", frame)

func _frame_size_dropdown_button_pressed() -> void:
	toggle_frame_size_popup()

func _customize_armor_toggle_button_pressed() -> void:
	toggle_armor_mode()

func _hp_down_button_pressed() -> void:
	frame_hp_label.text = str(frame_hp_label.text.to_int() - 1)
	
func _hp_up_button_pressed() -> void:
	frame_hp_label.text = str(frame_hp_label.text.to_int() + 1)

func _save_button_pressed() -> void:
	save_frame_data()
