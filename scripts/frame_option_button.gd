extends OptionButton
class_name FrameOptionButton

@onready var popup: PopupMenu = get_popup()

func _ready() -> void:
	if OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile"):
		popup.set_script(load("res://scripts/mobile_friendly_popupmenu.gd"))
		#gui_input.connect(_on_gui_input)
	#popup.gui_input.connect(_on_popup_gui_input)
	
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and !event.pressed:
		accept_event()
		show_popup()

#func _on_popup_gui_input(event: InputEvent) -> void:
	#if event is InputEventScreenTouch and event.pressed:
		#var local_pos = event.position - global_position
		#var item_idx = _get_item_index_at_position(local_pos)
		#
		#if item_idx != -1 and !popup.is_item_disabled(item_idx):
			#accept_event()
			#selected = item_idx
			#item_selected.emit(item_idx)
			#popup.hide()
