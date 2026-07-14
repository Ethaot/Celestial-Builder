extends LineEdit
class_name MobileFriendlyLineEdit

func _ready() -> void:
	text_submitted.connect(_on_text_submitted)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		grab_focus()
		DisplayServer.virtual_keyboard_show(text)

func _on_text_submitted(_new_text: String) -> void:
	DisplayServer.virtual_keyboard_hide()
	release_focus()
