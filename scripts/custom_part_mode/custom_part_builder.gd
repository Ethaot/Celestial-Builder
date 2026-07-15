extends ColorRect
class_name CustomPartBuilder

var button_prefab: PackedScene = preload("res://scenes/load_frame_build_button.tscn")
var label_prefab: PackedScene = preload("res://scenes/grid_label.tscn")
var grid_button_prefab: PackedScene = preload("res://scenes/custom_part_builder/part_grid_texture_button.tscn")
var tag_hbox_prefab: PackedScene = preload("res://scenes/custom_part_builder/tag_h_box.tscn")
var load_component_hbox_prefab: PackedScene = preload("res://scenes/load_component_h_box.tscn")

@export var scroll_container: ScrollContainer
@export var part_name_line_edit: MobileFriendlyLineEdit
@export var part_id_line_edit: MobileFriendlyLineEdit
@export var select_image_button: Button
@export var upload_image_button: Button
@export var part_type_button: Button
@export var size_button: Button
@export var part_type_dropdown_panel: PanelContainer
@export var part_type_dropdown_vbox: VBoxContainer
@export var size_dropdown_panel: PanelContainer
@export var size_dropdown_vbox: VBoxContainer
@export var grid_grid_container: GridContainer
@export var description_text_edit: TextEdit
@export var shield_capacity_hbox: HBoxContainer
@export var shield_capacity_amount_label: Label
@export var part_tab_line_edit: LineEdit
@export var tags_vbox: VBoxContainer
@export var add_tag_button: Button
@export var connected_tags_vbox: VBoxContainer
@export var add_connected_tag_button: Button
@export var save_part_button: Button
@export var load_part_button: Button
@export var load_part_menu: ColorRect
@export var load_part_vbox: VBoxContainer
@export var choose_data_pack_button: Button
@export var select_image_file_dialog: CustomFileSelector
@export var upload_image_file_dialog: FileDialog

var _on_file_loaded_callback
var page_width: int

var current_part: Part
var grid_buttons: Array[PartGridTextureButton]
var part_icon: Texture2D

func _ready() -> void:
	current_part = Part.new()
	get_viewport().size_changed.connect(setup)
	setup()
	populate_part_type_dropdown()
	select_part_type(Constants.PartType.WeaponRanged)
	populate_size_dropdown()
	populate_grid()
	add_tag_button.button_up.connect(_on_add_tag_button_pressed)
	add_connected_tag_button.button_up.connect(_on_add_connected_tag_button_pressed)
	save_part_button.button_up.connect(save_part)
	load_part_button.button_up.connect(_on_load_part_button_pressed)
	select_image_button.button_up.connect(select_image_file_dialog.popup)
	select_image_file_dialog.path_chosen.connect(select_part_image)
	upload_image_button.button_up.connect(_on_upload_part_image_button_pressed)
	upload_image_file_dialog.file_selected.connect(upload_part_image)
	if OS.has_feature("web") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		_on_file_loaded_callback = JavaScriptBridge.create_callback(_on_file_loaded)

func setup() -> void:
	var screen_size: Vector2i
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		screen_size = DisplayServer.screen_get_size(DisplayServer.SCREEN_PRIMARY)
	else:
		screen_size = DisplayServer.window_get_size()
	#get_window().size = screen_size
	get_window().content_scale_size = screen_size
	page_width = screen_size.x
	scroll_container.custom_minimum_size.x = page_width

func populate_part_type_dropdown() -> void:
	var children: Array[Node] = part_type_dropdown_vbox.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()
	var weapon_ranged_button: Button = button_prefab.instantiate()
	weapon_ranged_button.text = "Ranged"
	weapon_ranged_button.button_up.connect(select_part_type.bind(Constants.PartType.WeaponRanged))
	part_type_dropdown_vbox.add_child(weapon_ranged_button)
	var weapon_explosive_button: Button = button_prefab.instantiate()
	weapon_explosive_button.text = "Explosive"
	weapon_explosive_button.button_up.connect(select_part_type.bind(Constants.PartType.WeaponExplosive))
	part_type_dropdown_vbox.add_child(weapon_explosive_button)
	var weapon_melee_button: Button = button_prefab.instantiate()
	weapon_melee_button.text = "Melee"
	weapon_melee_button.button_up.connect(select_part_type.bind(Constants.PartType.WeaponMelee))
	part_type_dropdown_vbox.add_child(weapon_melee_button)
	var weapon_ew_button: Button = button_prefab.instantiate()
	weapon_ew_button.text = "Electronic Warfare"
	weapon_ew_button.button_up.connect(select_part_type.bind(Constants.PartType.WeaponEW))
	part_type_dropdown_vbox.add_child(weapon_ew_button)
	var weapon_missile_button: Button = button_prefab.instantiate()
	weapon_missile_button.text = "Missile"
	weapon_missile_button.button_up.connect(select_part_type.bind(Constants.PartType.WeaponMissile))
	part_type_dropdown_vbox.add_child(weapon_missile_button)
	var part_reactor_button: Button = button_prefab.instantiate()
	part_reactor_button.text = "Reactor"
	part_reactor_button.button_up.connect(select_part_type.bind(Constants.PartType.PartReactor))
	part_type_dropdown_vbox.add_child(part_reactor_button)
	var part_thruster_button: Button = button_prefab.instantiate()
	part_thruster_button.text = "Thruster"
	part_thruster_button.button_up.connect(select_part_type.bind(Constants.PartType.PartThruster))
	part_type_dropdown_vbox.add_child(part_thruster_button)
	var part_processor_button: Button = button_prefab.instantiate()
	part_processor_button.text = "Processor"
	part_processor_button.button_up.connect(select_part_type.bind(Constants.PartType.PartProcessor))
	part_type_dropdown_vbox.add_child(part_processor_button)
	var part_shield_button: Button = button_prefab.instantiate()
	part_shield_button.text = "Shield"
	part_shield_button.button_up.connect(select_part_type.bind(Constants.PartType.PartShield))
	part_type_dropdown_vbox.add_child(part_shield_button)

func populate_size_dropdown() -> void:
	var children = size_dropdown_vbox.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()
	
	var ul_button: Button = button_prefab.instantiate()
	ul_button.text = "Ultra Light"
	ul_button.button_up.connect(select_size.bind(Constants.Size.Ultralight))
	size_dropdown_vbox.add_child(ul_button)
	
	var l_button: Button = button_prefab.instantiate()
	l_button.text = "Light"
	l_button.button_up.connect(select_size.bind(Constants.Size.Light))
	size_dropdown_vbox.add_child(l_button)
	
	var m_button: Button = button_prefab.instantiate()
	m_button.text = "Medium"
	m_button.button_up.connect(select_size.bind(Constants.Size.Medium))
	size_dropdown_vbox.add_child(m_button)
	
	var h_button: Button = button_prefab.instantiate()
	h_button.text = "Heavy"
	h_button.button_up.connect(select_size.bind(Constants.Size.Heavy))
	size_dropdown_vbox.add_child(h_button)
	
	var u_button: Button = button_prefab.instantiate()
	u_button.text = "Ultra"
	u_button.button_up.connect(select_size.bind(Constants.Size.Ultra))
	size_dropdown_vbox.add_child(u_button)

func populate_grid() -> void:
	var topleft_label: Label = label_prefab.instantiate()
	grid_grid_container.add_child(topleft_label)
	for i in range(6):
		var l: Label = label_prefab.instantiate()
		l.text = str((i+1)*10)
		grid_grid_container.add_child(l)
		
	for i in range(6):
		var side_label: Label = label_prefab.instantiate()
		side_label.text = str(i+1)
		grid_grid_container.add_child(side_label)
		for n in range(6):
			var tb: PartGridTextureButton = grid_button_prefab.instantiate()
			tb.index = i*6+n
			grid_buttons.append(tb)
			tb.button_up.connect(_on_grid_button_pressed.bind(i*6+n))
			tb.self_modulate = Color("#282828")
			grid_grid_container.add_child(tb)

func select_part_type(type: Constants.PartType) -> void:
	var old_part_dict: Dictionary = current_part.to_dict()
	current_part = Part.new()
	size_button.visible = false
	shield_capacity_hbox.visible = false
	match type:
		Constants.PartType.PartReactor:
			var reactor_part: Reactor = Reactor.new()
			current_part = reactor_part
			select_size(Constants.Size.Ultralight)
			size_button.visible = true
		Constants.PartType.PartShield:
			var shield_part: Shield = Shield.new()
			current_part = shield_part
			select_size(Constants.Size.Ultralight)
			size_button.visible = true
			shield_capacity_hbox.visible = true
	current_part.from_dict(old_part_dict)
	current_part.part_type = type
	update_part_type_button_text(type)
	part_type_dropdown_panel.visible = false

func update_part_type_button_text(part_type: Constants.PartType) -> void:
	match part_type:
		Constants.PartType.WeaponRanged:
			part_type_button.text = "Part Type: Ranged"
		Constants.PartType.WeaponExplosive:
			part_type_button.text = "Part Type: Explosive"
		Constants.PartType.WeaponMelee:
			part_type_button.text = "Part Type: Melee"
		Constants.PartType.WeaponEW:
			part_type_button.text = "Part Type: Electronic Warfare"
		Constants.PartType.WeaponMissile:
			part_type_button.text = "Part Type: Missile"
		Constants.PartType.PartReactor:
			part_type_button.text = "Part Type: Reactor"
		Constants.PartType.PartThruster:
			part_type_button.text = "Part Type: Thruster"
		Constants.PartType.PartProcessor:
			part_type_button.text = "Part Type: Processor"
		Constants.PartType.PartShield:
			part_type_button.text = "Part Type: Shield"

func select_size(s: Constants.Size) -> void:
	if current_part is Reactor or current_part is Shield:
		current_part.size = s
	size_dropdown_panel.visible = false
	update_part_size_button(s)

func update_part_size_button(s: Constants.Size) -> void:
	match s:
		Constants.Size.Ultralight:
			size_button.text = "Size: Ultralight"
		Constants.Size.Light:
			size_button.text = "Size: Light"
		Constants.Size.Medium:
			size_button.text = "Size: Medium"
		Constants.Size.Heavy:
			size_button.text = "Size: Heavy"
		Constants.Size.Ultra:
			size_button.text = "Size: Ultra"

func select_part_image(path: String) -> void:
	current_part.part_icon = path.trim_prefix(ResourceManager.DATA_PACKS_PATH)
	var img: Image = Image.load_from_file(path)
	var itex: ImageTexture = ImageTexture.create_from_image(img)
	part_icon = itex

func update_part_image_on_grid() -> void:
	for tb in grid_buttons:
		tb.part_tex_rect.texture = null
	if current_part.part_icon.length() > 0 and part_icon != null:
		var part_length: int = 1
		var part_height: int = 1
		for slot in current_part.part_configuration:
			if slot.x + 1 > part_length:
				part_length = slot.x + 1
			if slot.y + 1 > part_height:
				part_height = slot.y + 1
		var image_size: Vector2i = part_icon.get_size()
		var tile_size: Vector2i = Vector2i(floori(float(image_size.x) / part_length), floori(float(image_size.y) / part_height))
		for i in range(grid_buttons.size()):
			var slot = Vector2i(i%6, floori(float(i) / 6.0))
			if current_part.part_configuration.has(slot):
				var atex: AtlasTexture = AtlasTexture.new()
				atex.atlas = part_icon
				atex.region = Rect2(slot.x * tile_size.x, slot.y * tile_size.y, tile_size.x, tile_size.y)
				grid_buttons[i].part_tex_rect.texture = atex

func upload_part_image(path: String) -> void:
	var fna: PackedStringArray = path.rsplit("/")
	var file_name: String = fna[fna.size() - 1]
	var img: Image = Image.load_from_file(path)
	if !DirAccess.dir_exists_absolute(ResourceManager.DATA_PACKS_PATH + DataManager.currently_edited_data_pack + "/images/"):
		DirAccess.make_dir_absolute(ResourceManager.DATA_PACKS_PATH + DataManager.currently_edited_data_pack + "/images/")
	if file_name.get_extension() == "png":
		img.save_png(ResourceManager.DATA_PACKS_PATH + DataManager.currently_edited_data_pack + "/images/" + file_name)
	elif file_name.get_extension() == "jpg" or file_name.get_extension() == "jpeg":
		img.save_jpg(ResourceManager.DATA_PACKS_PATH + DataManager.currently_edited_data_pack + "/images/" + file_name)
	select_part_image(path)

func save_part() -> void:
	current_part.part_name = part_name_line_edit.text
	current_part.part_id = part_id_line_edit.text
	current_part.part_description = description_text_edit.text
	current_part.part_tab = part_tab_line_edit.text
	if current_part is Shield:
		current_part.capacity = shield_capacity_amount_label.text.to_int()
	current_part.tags.clear()
	current_part.connected_tags.clear()
	var tag_hboxes: Array[Node] = tags_vbox.get_children()
	for i in range(1, tag_hboxes.size() - 1):
		if tag_hboxes[i] is TagHBox:
			current_part.tags.append(tag_hboxes[i].line_edit.text)
	var connected_tag_hboxes: Array[Node] = connected_tags_vbox.get_children()
	for i in range(1, connected_tag_hboxes.size() - 1):
		if connected_tag_hboxes[i] is TagHBox:
			current_part.connected_tags.append(connected_tag_hboxes[i].line_edit.text)
	ResourceManager.save_part_to_parts_json(DataManager.currently_edited_data_pack, current_part)

func populate_load_part_menu() -> void:
	for child in load_part_vbox.get_children():
		child.queue_free()
	for p in ResourceManager.get_parts_from_pack(DataManager.currently_edited_data_pack):
		var lchb: LoadComponentHBox = load_component_hbox_prefab.instantiate()
		lchb.load_button.text = p.part_id
		lchb.load_button.button_up.connect(_on_load_part.bind(p))
		lchb.delete_button.button_up.connect(func() -> void:
			ResourceManager.remove_part_from_parts_json(DataManager.currently_edited_data_pack, p.part_id)
			lchb.queue_free()
			)
		load_part_vbox.add_child(lchb)
	var back_button: Button = button_prefab.instantiate()
	back_button.text = "Back"
	back_button.button_up.connect(func() -> void: load_part_menu.visible = false)
	load_part_vbox.add_child(back_button)

func populate_all_components() -> void:
	part_name_line_edit.text = current_part.part_name
	part_id_line_edit.text = current_part.part_id
	part_tab_line_edit.text = current_part.part_tab
	description_text_edit.text = current_part.part_description
	update_part_type_button_text(current_part.part_type)
	if current_part is Reactor or current_part is Shield:
		update_part_size_button(current_part.size)
		size_button.visible = true
		if current_part is Shield:
			shield_capacity_amount_label.text = str(current_part.capacity)
			shield_capacity_hbox.visible = true
		update_part_size_button(current_part.size)
	else:
		size_button.visible = false
		shield_capacity_hbox.visible = false
	
	for gb in grid_buttons:
		if current_part.part_configuration.has(Vector2i(gb.index%6, floori(float(gb.index) / 6.0))):
			gb.selected = true
			gb.self_modulate = Color.WHITE
		else:
			gb.selected = false
			gb.self_modulate = Color("#282828")
	
	if FileAccess.file_exists(ResourceManager.DATA_PACKS_PATH + current_part.part_icon):
		var img: Image = Image.load_from_file(ResourceManager.DATA_PACKS_PATH + current_part.part_icon)
		var itex: ImageTexture = ImageTexture.create_from_image(img)
		part_icon = itex
	update_part_image_on_grid()
	
	var tag_children: Array[Node] = tags_vbox.get_children()
	for i in range(1, tag_children.size() - 1):
		tag_children[i].queue_free()
	var connected_tag_children: Array[Node] = connected_tags_vbox.get_children()
	for i in range(1, connected_tag_children.size() - 1):
		connected_tag_children[i].queue_free()
	
	for t in current_part.tags:
		var thb: TagHBox = tag_hbox_prefab.instantiate()
		thb.line_edit.text = t
		tags_vbox.add_child(thb)
		tags_vbox.move_child(add_tag_button, tags_vbox.get_children().size() - 1)
	for t in current_part.connected_tags:
		var thb: TagHBox = tag_hbox_prefab.instantiate()
		thb.line_edit.text = t
		connected_tags_vbox.add_child(thb)
		connected_tags_vbox.move_child(add_connected_tag_button, connected_tags_vbox.get_children().size() - 1)

func trigger_web_upload() -> void:
	var js_code = """
	(function() {
		let input = document.getElementById('godot-file-uploader');
		if (!input) {
			input = document.createElement('input');
			input.id = 'godot-file-uploader';
			input.type = 'file';
			input.style.display = 'none';
			input.accept = '.png';
			document.body.appendChild(input);
		}
		
		input.onchange = function(e) {
			let file = e.target.files[0];
			if (!file) return;
			
			let reader = new FileReader();
			reader.onload = function(evt) {
				let arrayBuffer = evt.target.result;
				let uint8Array = new Uint8Array(arrayBuffer);
				window.godot_file_handler(file.name, uint8Array);
			};
			reader.readAsArrayBuffer(file);
		};
		input.click();
	})();
	"""
	
	var window = JavaScriptBridge.get_interface("window")
	window.godot_file_handler = _on_file_loaded_callback
	JavaScriptBridge.eval(js_code)

func _on_grid_button_pressed(idx: int) -> void:
	var pos: Vector2i = Vector2i(idx%6, floori(float(idx) / 6.0))
	if grid_buttons[idx].selected:
		for i in range(current_part.part_configuration.size()):
			if current_part.part_configuration[i] == pos:
				current_part.part_configuration.remove_at(i)
				break
		grid_buttons[idx].self_modulate = Color("#282828")
	else:
		current_part.part_configuration.append(pos)
		current_part.part_configuration.sort_custom(sort_grid_by_x)
		current_part.part_configuration.sort_custom(sort_grid_by_y)
		grid_buttons[idx].self_modulate = Color.WHITE
	grid_buttons[idx].selected = false if grid_buttons[idx].selected else true
	update_part_image_on_grid()

func sort_grid_by_y(a: Vector2i, b: Vector2i) -> bool:
	if a.y < b.y:
		return true
	return false
	
func sort_grid_by_x(a: Vector2i, b: Vector2i) -> bool:
	if a.x < b.x:
		return true
	return false

func _on_upload_part_image_button_pressed() -> void:
	if OS.has_feature("web") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		trigger_web_upload()
	else:
		upload_image_file_dialog.popup_file_dialog()

func _on_file_loaded(args: Array) -> void:
	print("Preparing to create image file...")
	var file_name: String = args[0]
	print(file_name)
	var file_data: PackedByteArray
	var length = int(args[1].length)
	file_data.resize(length)
	for i in range(length):
		file_data[i] = args[1][i]
	print("Successfully uploaded " + file_name)
	var img: Image = Image.new()
	var err: Error
	if file_name.get_extension() == "png":
		err = img.load_png_from_buffer(file_data)
	elif file_name.get_extension() == "jpg" or file_name.get_extension() == "jpeg":
		err = img.load_jpg_from_buffer(file_data)
	if err != OK:
		push_error("Couldn't upload file " + file_name)
	else:
		if !DirAccess.dir_exists_absolute(ResourceManager.DATA_PACKS_PATH + DataManager.currently_edited_data_pack + "/images/"):
			DirAccess.make_dir_absolute(ResourceManager.DATA_PACKS_PATH + DataManager.currently_edited_data_pack + "/images/")
		img.save_png(ResourceManager.DATA_PACKS_PATH + DataManager.currently_edited_data_pack + "/images/" + file_name)
		print("Image file saved.")
		select_part_image(ResourceManager.DATA_PACKS_PATH + DataManager.currently_edited_data_pack + "/images/" + file_name)

func _on_add_tag_button_pressed() -> void:
	var thb: TagHBox = tag_hbox_prefab.instantiate()
	tags_vbox.add_child(thb)
	tags_vbox.move_child(add_tag_button, tags_vbox.get_children().size() - 1)

func _on_add_connected_tag_button_pressed() -> void:
	var thb: TagHBox = tag_hbox_prefab.instantiate()
	connected_tags_vbox.add_child(thb)
	connected_tags_vbox.move_child(add_connected_tag_button, connected_tags_vbox.get_children().size() - 1)

func _on_load_part_button_pressed() -> void:
	populate_load_part_menu()
	load_part_menu.visible = true

func _on_load_part(p: Part) -> void:
	current_part = p
	populate_all_components()
	load_part_menu.visible = false
