extends TextureButton
class_name EncounterGridTextureButton

enum Mode {Normal, Damaged, Disabled, Both}

signal grid_texture_button_up

@export var texrect: TextureRect
@export var damage_label: Label
@export var disabled_label: Label
@export var power_texrects: Array[TextureRect]
@export var grid_clipping_rect: ColorRect
@export var grid_gradient_rect: TextureRect

var encounter_data_manager: EncounterDataManager

var grid_index: int
var current_mode: Mode = Mode.Normal

var hovered: bool = false

func _ready() -> void:
	if !OS.has_feature("mobile"):
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	resized.connect(_on_resized)

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
		if event is InputEventScreenTouch:
			if event.index == 0:
				if !event.pressed:
					grid_texture_button_up.emit()

func cycle_labels() -> void:
	match current_mode:
		Mode.Normal:
			damage_label.visible = true
			disabled_label.visible = false
			current_mode = Mode.Damaged
			encounter_data_manager.current_combatant.current_damage[grid_index] = 1
		Mode.Damaged:
			damage_label.visible = false
			disabled_label.visible = true
			current_mode = Mode.Disabled
			encounter_data_manager.current_combatant.current_damage[grid_index] = 2
		Mode.Disabled:
			damage_label.visible = true
			disabled_label.visible = true
			current_mode = Mode.Both
			encounter_data_manager.current_combatant.current_damage[grid_index] = 3
		Mode.Both:
			damage_label.visible = false
			disabled_label.visible = false
			current_mode = Mode.Normal
			encounter_data_manager.current_combatant.current_damage[grid_index] = 0
	encounter_data_manager.data_changed = true

func clear_damage() -> void:
	damage_label.visible = false
	disabled_label.visible = false
	current_mode = Mode.Normal

func _on_resized() -> void:
	for ptr in power_texrects:
		ptr.custom_minimum_size = size / 2.0

func _on_mouse_entered() -> void:
	hovered = true

func _on_mouse_exited() -> void:
	hovered = false
