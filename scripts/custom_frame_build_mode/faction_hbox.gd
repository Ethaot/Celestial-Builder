extends HBoxContainer
class_name FactionHBox

@export var faction_line_edit: LineEdit
@export var delete_button: Button

func _ready() -> void:
	delete_button.button_up.connect(_on_delete_button_pressed)

func _on_delete_button_pressed() -> void:
	queue_free()
