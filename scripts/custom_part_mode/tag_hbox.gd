extends HBoxContainer
class_name TagHBox

@export var line_edit: LineEdit
@export var delete_button: Button

func _ready() -> void:
	delete_button.button_up.connect(func() -> void: queue_free())
	
