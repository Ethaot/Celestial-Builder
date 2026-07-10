extends TextureButton
class_name CustomFrameArmorGridTextureButton

enum MODE{None, Armor, Reinforced}

var signal_bus: CustomFrameModeSignalBus
var index: int
var mode: MODE = MODE.None

func _ready() -> void:
	button_up.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	match mode:
		MODE.None:
			mode = MODE.Armor
		MODE.Armor:
			mode = MODE.Reinforced
		MODE.Reinforced:
			mode = MODE.None
	signal_bus.emit_armor_grid_selected(index, mode)
