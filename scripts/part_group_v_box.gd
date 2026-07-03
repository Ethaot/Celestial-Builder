extends VBoxContainer
class_name PartGroupVBox

@export var group_tab_button: Button
@export var group_tab_grid_container: GridContainer

func _ready() -> void:
	group_tab_button.button_up.connect(toggle_group_tab)

func toggle_group_tab() -> void:
	if group_tab_grid_container.visible:
		group_tab_grid_container.visible = false
	else:
		group_tab_grid_container.visible = true
