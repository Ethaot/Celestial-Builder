extends LineEdit
class_name MobileFriendlyLineEdit

func _ready() -> void:
	text_submitted.connect(_on_text_submitted)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and !event.is_pressed():
		#DisplayServer.virtual_keyboard_show(text, Rect2(0, 0, 0, 0), DisplayServer.KEYBOARD_TYPE_DEFAULT, -1, 0, text.length())
		grab_focus()

func _input(event: InputEvent) -> void:
	if has_focus():
		if event is InputEventScreenTouch and !event.is_pressed():
			release_focus()

func _on_text_submitted(_new_text: String) -> void:
	DisplayServer.virtual_keyboard_hide()
	release_focus()
