extends VBoxContainer
class_name DataPackVBox

@export var data_pack_button: Button
@export var data_pack_categories_vbox: VBoxContainer

func _ready() -> void:
	data_pack_button.button_up.connect(toggle_data_pack)

func toggle_data_pack() -> void:
	data_pack_categories_vbox.visible = false if data_pack_categories_vbox.visible else true
