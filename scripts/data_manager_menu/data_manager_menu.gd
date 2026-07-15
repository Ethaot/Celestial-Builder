extends Panel
class_name DataManagerMenu

var data_pack_vbox_prefab: PackedScene = preload("res://scenes/data_manager_menu/data_pack_v_box.tscn")
var data_pack_category_vbox_prefab: PackedScene = preload("res://scenes/data_manager_menu/data_pack_category_v_box.tscn")
var data_pack_item_hbox_prefab: PackedScene = preload("res://scenes/data_manager_menu/data_pack_item_h_box.tscn")
var horizontal_rule_prefab: PackedScene = preload("res://scenes/data_manager_menu/horizontal_rule.tscn")
var data_pack_panel_container_prefab: PackedScene = preload("res://scenes/data_manager_menu/data_pack_panel_container.tscn")
var button_prefab: PackedScene = preload("res://scenes/load_frame_build_button.tscn")

@export var menu_vbox: VBoxContainer
@export var copy_to_panel: Panel
@export var copy_to_vbox_container: VBoxContainer
@export var back_button: Button

var clipboard_item: Dictionary

func _ready() -> void:
	populate_menu()

func populate_menu() -> void:
	var children: Array[Node] = menu_vbox.get_children()
	for i in range(1, children.size() - 1):
		children[i].queue_free()
	for m in ResourceManager.manifests:
		if m["package_id"] != "celestial-bodies-core":
			load_data_pack(m["package_id"])
	load_data_pack("custom")
	menu_vbox.move_child(back_button, menu_vbox.get_children().size() - 1)

func load_data_pack(pack_id: String) -> void:
	var base_path: String = ResourceManager.DATA_PACKS_PATH + pack_id + "/"
	if DirAccess.dir_exists_absolute(base_path):
		var p: PanelContainer = data_pack_panel_container_prefab.instantiate()
		var dpvb: DataPackVBox = data_pack_vbox_prefab.instantiate()
		dpvb.data_pack_button.text = pack_id
		menu_vbox.add_child(p)
		p.add_child(dpvb)
		if FileAccess.file_exists(base_path + "frames.json"):
			var dpcvb: DataPackCategoryVBox = data_pack_category_vbox_prefab.instantiate()
			dpcvb.data_pack_category_button.text = "Frames"
			dpvb.data_pack_categories_vbox.add_child(dpcvb)
			var file = FileAccess.open(base_path + "frames.json", FileAccess.READ)
			var json_string: String = file.get_as_text()
			var data = JSON.parse_string(json_string)
			if data is Array:
				for dict in data:
					if dict is Dictionary:
						var dpihb: DataPackItemHBox = data_pack_item_hbox_prefab.instantiate()
						dpihb.data_pack_item_label.text = dict["frame_id"]
						dpihb.data_pack_item_copy_button.button_up.connect(prepare_to_copy.bind(dict, "frame"))
						dpihb.data_pack_item_delete_button.button_up.connect(delete_item.bind(pack_id, "frame", dict["frame_id"], dpihb))
						dpcvb.data_pack_item_vbox.add_child(dpihb)
			var hr: Panel = horizontal_rule_prefab.instantiate()
			dpvb.data_pack_categories_vbox.add_child(hr)
		if FileAccess.file_exists(base_path + "frame_builds.json"):
			var dpcvb: DataPackCategoryVBox = data_pack_category_vbox_prefab.instantiate()
			dpcvb.data_pack_category_button.text = "Frame Builds"
			dpvb.data_pack_categories_vbox.add_child(dpcvb)
			var file = FileAccess.open(base_path + "frame_builds.json", FileAccess.READ)
			var json_string: String = file.get_as_text()
			var data = JSON.parse_string(json_string)
			if data is Array:
				for dict in data:
					if dict is Dictionary:
						var dpihb: DataPackItemHBox = data_pack_item_hbox_prefab.instantiate()
						dpihb.data_pack_item_label.text = dict["frame_build_name"]
						dpihb.data_pack_item_copy_button.button_up.connect(prepare_to_copy.bind(dict, "frame_build"))
						dpihb.data_pack_item_delete_button.button_up.connect(delete_item.bind(pack_id, "frame_build", dict["frame_build_name"], dpihb))
						dpcvb.data_pack_item_vbox.add_child(dpihb)
			var hr: Panel = horizontal_rule_prefab.instantiate()
			dpvb.data_pack_categories_vbox.add_child(hr)
		if FileAccess.file_exists(base_path + "parts.json"):
			var dpcvb: DataPackCategoryVBox = data_pack_category_vbox_prefab.instantiate()
			dpcvb.data_pack_category_button.text = "Parts"
			dpvb.data_pack_categories_vbox.add_child(dpcvb)
			var file = FileAccess.open(base_path + "parts.json", FileAccess.READ)
			var json_string: String = file.get_as_text()
			var data = JSON.parse_string(json_string)
			if data is Array:
				for dict in data:
					if dict is Dictionary:
						var dpihb: DataPackItemHBox = data_pack_item_hbox_prefab.instantiate()
						dpihb.data_pack_item_label.text = dict["part_id"]
						dpihb.data_pack_item_copy_button.button_up.connect(prepare_to_copy.bind(dict, "part"))
						dpihb.data_pack_item_delete_button.button_up.connect(delete_item.bind(pack_id, "part", dict["part_id"], dpihb))
						dpcvb.data_pack_item_vbox.add_child(dpihb)

func prepare_to_copy(item: Dictionary, type: String) -> void:
	clipboard_item = item
	populate_copy_container(type)
	copy_to_panel.visible = true

func populate_copy_container(type: String) -> void:
	for child in copy_to_vbox_container.get_children():
		child.queue_free()
	for m in ResourceManager.manifests:
		if m["package_id"] != "celestial-bodies-core":
			var b: Button = button_prefab.instantiate()
			b.text = m["package_id"]
			b.button_up.connect(confirm_copy.bind(m["package_id"], type))
			copy_to_vbox_container.add_child(b)
	var custom_button: Button = button_prefab.instantiate()
	custom_button.text = "custom"
	custom_button.button_up.connect(confirm_copy.bind("custom", type))
	copy_to_vbox_container.add_child(custom_button)
	var back_button: Button = button_prefab.instantiate()
	back_button.text = "Cancel"
	back_button.button_up.connect(func() -> void: copy_to_panel.visible = false)
	copy_to_vbox_container.add_child(back_button)

func confirm_copy(package_id: String, type: String) -> void:
	var data: Array[Dictionary]
	var path: String
	match type:
		"frame":
			path = ResourceManager.DATA_PACKS_PATH + package_id + "/frames.json"
		"frame_build":
			path = ResourceManager.DATA_PACKS_PATH + package_id + "/frame_builds.json"
		"part":
			path = ResourceManager.DATA_PACKS_PATH + package_id + "/parts.json"
		_: 
			return
	if FileAccess.file_exists(path):
		var extant_file = FileAccess.open(path, FileAccess.READ)
		var extant_json_string: String = extant_file.get_as_text()
		data = JSON.parse_string(extant_json_string)
		extant_file.close()
	data.append(clipboard_item)
	var file = FileAccess.open(path, FileAccess.WRITE)
	var json_string: String = JSON.stringify(data, "\t")
	file.store_line(json_string)
	file.close()
	
	populate_menu()
	copy_to_panel.visible = false

func delete_item(package_id: String, type: String, item_id: String, dpihb: DataPackItemHBox) -> void:
	var path: String
	var match_key: String
	match type:
		"frame":
			path = ResourceManager.DATA_PACKS_PATH + package_id + "/frames.json"
			match_key = "frame_id"
		"frame_build":
			path = ResourceManager.DATA_PACKS_PATH + package_id + "/frame_builds.json"
			match_key = "frame_build_name"
		"part":
			path = ResourceManager.DATA_PACKS_PATH + package_id + "/parts.json"
			match_key = "part_id"
		_: 
			return
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ_WRITE)
		var json_string: String = file.get_as_text()
		var read_data = JSON.parse_string(json_string)
		var write_data: Array[Dictionary]
		if read_data is Array:
			for dict in read_data:
				if dict is Dictionary:
					if dict[match_key] != item_id:
						write_data.append(dict)
		if write_data.size() > 0:
			var write_string: String = JSON.stringify(write_data, "\t")
			file.store_line(write_string)
			file.close()
		else:
			file.close()
			DirAccess.remove_absolute(path)
		dpihb.queue_free()
