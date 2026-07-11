extends Panel
class_name DataPackToggleMenu

var data_pack_toggle_button_prefab: PackedScene = preload("res://scenes/data_pack_toggle_button.tscn")
var button_prefab: PackedScene = preload("res://scenes/load_frame_build_button.tscn")

@export var data_packs_toggle_vbox: VBoxContainer

var data_packs_changed: bool = false

func display_data_packs() -> void:
	var children: Array[Node] = data_packs_toggle_vbox.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()
	for m in ResourceManager.manifests:
		var dptb: DataPackToggleButton = data_pack_toggle_button_prefab.instantiate()
		dptb.text = m["package_name"] + " (" + m["package_id"] + ") by " + m["author"]
		dptb.button_pressed = m["enabled"]
		dptb.pack_id = m["package_id"]
		dptb.dptm = self
		data_packs_toggle_vbox.add_child(dptb)
	var back_button: Button = button_prefab.instantiate()
	back_button.text = "Back"
	back_button.button_up.connect(close_data_packs_menu)
	data_packs_toggle_vbox.add_child(back_button)
	visible = true

func close_data_packs_menu() -> void:
	if data_packs_changed:
		ResourceManager.refresh_all_packs()
	visible = false
