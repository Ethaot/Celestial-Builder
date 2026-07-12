extends Panel
class_name DataPackSelectorPanel

signal new_data_pack_selected(new_data_pack_id: String)

var data_pack_button_prefab: PackedScene = preload("res://scenes/data_pack_button.tscn")

@export var data_pack_selector_menu: ScrollContainer
@export var data_pack_selector_vbox: VBoxContainer
@export var currently_modifying_label: Label
@export var new_data_pack_menu: ScrollContainer
@export_group("New Data Pack Components", "new_data_pack_")
@export var new_data_pack_name_label: Label
@export var new_data_pack_name_line_edit: LineEdit
@export var new_data_pack_id_label: Label
@export var new_data_pack_id_line_edit: LineEdit
@export var new_data_pack_author_label: Label
@export var new_data_pack_author_line_edit: LineEdit
@export var new_data_pack_source_name_label: Label
@export var new_data_pack_source_name_line_edit: LineEdit
@export var new_data_pack_version_label: Label
@export var new_data_pack_version_line_edit: LineEdit
@export var new_data_pack_confirm_button: Button
@export var new_data_pack_back_button: Button

var data_pack_dict: Dictionary[String, String]

func _ready() -> void:
	construct_data_pack_dict()
	new_data_pack_confirm_button.button_up.connect(confirm_new_data_pack_button_pressed)
	new_data_pack_back_button.button_up.connect(close_new_data_pack_menu)
	currently_modifying_label.text = "Currently Modifying: " + DataManager.currently_edited_data_pack

func popup() -> void:
	visible = true
	create_buttons()
	#resize_panel()

func refresh() -> void:
	construct_data_pack_dict()
	create_buttons()

func construct_data_pack_dict() -> void:
	data_pack_dict.clear()
	for m in ResourceManager.manifests:
		if m["package_id"] != "celestial-bodies-core":
			data_pack_dict[m["package_id"]] = m["package_name"]
	data_pack_dict["custom"] = "Custom"

func create_buttons() -> void:
	var children: Array[Node] = data_pack_selector_vbox.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()
	for p in data_pack_dict:
		var dpb: DataPackButton = data_pack_button_prefab.instantiate()
		dpb.text = data_pack_dict[p]
		dpb.data_pack_id = p
		dpb.button_up.connect(func() -> void: 
			DataManager.currently_edited_data_pack = p
			currently_modifying_label.text = "Currently Modifying: " + DataManager.currently_edited_data_pack
			DataManager.save_config()
			new_data_pack_selected.emit(p)
			visible = false
			)
		data_pack_selector_vbox.add_child(dpb)
	var new_pack_button: Button = data_pack_button_prefab.instantiate()
	new_pack_button.text = "+ New Data Pack"
	new_pack_button.button_up.connect(popup_new_data_pack_menu)
	data_pack_selector_vbox.add_child(new_pack_button)
	var back_button: Button = data_pack_button_prefab.instantiate()
	back_button.text = "Back"
	back_button.button_up.connect(func() -> void: visible = false)
	data_pack_selector_vbox.add_child(back_button)

func resize_panel() -> void:
	size = data_pack_selector_vbox.size

func popup_new_data_pack_menu() -> void:
	new_data_pack_name_line_edit.text = ""
	new_data_pack_id_line_edit.text = ""
	new_data_pack_author_line_edit.text = ""
	new_data_pack_source_name_line_edit.text = ""
	new_data_pack_version_line_edit.text = ""
	new_data_pack_menu.visible = true
	data_pack_selector_menu.visible = false

func confirm_new_data_pack_button_pressed() -> void:
	var unfinished: bool = false
	if new_data_pack_name_line_edit.text.length() == 0:
		new_data_pack_name_label.add_theme_color_override("font_color", Color.RED)
		unfinished = true
	else:
		new_data_pack_name_label.remove_theme_color_override("font_color")
	if new_data_pack_id_line_edit.text.length() == 0:
		new_data_pack_id_label.add_theme_color_override("font_color", Color.RED)
		unfinished = true
	else:
		new_data_pack_id_label.remove_theme_color_override("font_color")
	if new_data_pack_author_line_edit.text.length() == 0:
		new_data_pack_author_label.add_theme_color_override("font_color", Color.RED)
		unfinished = true
	else:
		new_data_pack_author_label.remove_theme_color_override("font_color")
	if new_data_pack_source_name_line_edit.text.length() == 0:
		new_data_pack_source_name_label.add_theme_color_override("font_color", Color.RED)
		unfinished = true
	else:
		new_data_pack_source_name_label.remove_theme_color_override("font_color")
	if new_data_pack_version_line_edit.text.length() == 0:
		new_data_pack_version_label.add_theme_color_override("font_color", Color.RED)
		unfinished = true
	else:
		new_data_pack_version_label.remove_theme_color_override("font_color")
	if !unfinished:
		ResourceManager.add_data_pack({
			"package_name": new_data_pack_name_line_edit.text,
			"package_id": new_data_pack_id_line_edit.text,
			"package_url": "",
			"author": new_data_pack_author_line_edit.text,
			"source_name": new_data_pack_source_name_line_edit.text,
			"source_url": "",
			"version": new_data_pack_version_line_edit.text
		})
		#ResourceManager.refresh_all_packs()
		DataManager.currently_edited_data_pack = new_data_pack_id_line_edit.text
		new_data_pack_selected.emit(DataManager.currently_edited_data_pack)
		close_new_data_pack_menu()
		refresh()

func close_new_data_pack_menu() -> void:
	new_data_pack_menu.visible = false
	data_pack_selector_menu.visible = true
