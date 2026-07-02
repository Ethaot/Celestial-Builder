extends TextureButton
class_name GridTextureButton

enum Mode {Normal, Damaged, Disabled}

signal grid_texture_button_up

@export var damage_label: Label
@export var disabled_label: Label

var current_mode: Mode = Mode.Normal

var hovered: bool = false

func _ready() -> void:
	if !OS.has_feature("mobile"):
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		var touch_pos = event.position
		if get_global_rect().has_point(touch_pos):
			hovered = true
		else:
			hovered = false
	if hovered:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if !event.pressed:
					grid_texture_button_up.emit()
					#accept_event()

func cycle_labels() -> void:
	match current_mode:
		Mode.Normal:
			damage_label.visible = true
			disabled_label.visible = false
			current_mode = Mode.Damaged
		Mode.Damaged:
			damage_label.visible = false
			disabled_label.visible = true
			current_mode = Mode.Disabled
		Mode.Disabled:
			damage_label.visible = false
			disabled_label.visible = false
			current_mode = Mode.Normal
			
func _on_mouse_entered() -> void:
	hovered = true

func _on_mouse_exited() -> void:
	hovered = false
