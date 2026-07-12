extends VBoxContainer
class_name DataPackCategoryVBox

@export var data_pack_category_button: Button
@export var data_pack_item_vbox: VBoxContainer

func _ready() -> void:
	data_pack_category_button.button_up.connect(toggle_data_pack_category)

func toggle_data_pack_category() -> void:
	data_pack_item_vbox.visible = false if data_pack_item_vbox.visible else true
