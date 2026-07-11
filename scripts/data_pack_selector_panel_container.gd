extends Panel
class_name DataPackSelectorPanel

var data_pack_button_prefab: PackedScene = preload("res://scenes/data_pack_button.tscn")

@export var data_pack_selector_vbox: VBoxContainer
var data_pack_dict: Dictionary[String, String]

func _ready() -> void:
	construct_data_pack_dict()

func popup() -> void:
	visible = true
	create_buttons()
	resize_panel()

func construct_data_pack_dict() -> void:
	for m in ResourceManager.manifests:
		if m["package_id"] != "celestial-bodies-core":
			data_pack_dict[m["package_id"]] = m["package_name"]
	data_pack_dict["custom"] = "Custom"

func create_buttons() -> void:
	for child in data_pack_selector_vbox.get_children():
		child.queue_free()
	for p in data_pack_dict:
		var dpb: DataPackButton = data_pack_button_prefab.instantiate()
		dpb.text = data_pack_dict[p]
		dpb.data_pack_id = p
		dpb.button_up.connect(func() -> void: 
			DataManager.currently_edited_data_pack = p
			visible = false
			)
		data_pack_selector_vbox.add_child(dpb)
	var new_pack_button: Button = data_pack_button_prefab.instantiate()
	new_pack_button.text = "+ New Data Pack"
	data_pack_selector_vbox.add_child(new_pack_button)
	var back_button: Button = data_pack_button_prefab.instantiate()
	back_button.text = "Back"
	back_button.button_up.connect(func() -> void: visible = false)
	data_pack_selector_vbox.add_child(back_button)

func resize_panel() -> void:
	size = data_pack_selector_vbox.size
