extends Panel
class_name EncounterLoadFrameBuildPanel

var load_frame_build_button_prefab: PackedScene = preload("res://scenes/load_frame_build_button.tscn")
var load_faction_hbox_prefab: PackedScene = preload("res://scenes/custom_frame_build_mode/load_faction_h_box.tscn")

@export var encounter_data_manager: EncounterDataManager
@export var encounter_signal_bus: EncounterSignalBus
@export var vbox: VBoxContainer

func popup() -> void:
	populate_load_vbox()
	visible = true

func dismiss() -> void:
	visible = false

func populate_load_vbox() -> void:
	for child in vbox.get_children():
		child.queue_free()
	var faction_frame_dict: Dictionary[String, Array]
	for fb in ResourceManager.frame_builds:
		for fact in fb.factions:
			if !faction_frame_dict.has(fact):
				faction_frame_dict[fact] = [fb]
			else:
				faction_frame_dict[fact].append(fb)
	for fact in faction_frame_dict:
		var fac_button: Button = load_frame_build_button_prefab.instantiate()
		fac_button.text = fact
		fac_button.add_theme_color_override("font_color", Color("#e8008c"))
		vbox.add_child(fac_button)
		var lfhb: LoadFactionHBox = load_faction_hbox_prefab.instantiate()
		vbox.add_child(lfhb)
		lfhb.visible = false
		fac_button.button_up.connect(func() -> void: lfhb.visible = false if lfhb.visible else true)
		for fb: FrameBuild in faction_frame_dict[fact]:
			var fbb: Button = load_frame_build_button_prefab.instantiate()
			fbb.text = fb.frame_build_name
			lfhb.frame_vbox.add_child(fbb)
			fbb.button_up.connect(func() -> void:
				encounter_signal_bus.change_frame_build(fb)
				encounter_signal_bus.request_redraw_grid()
				dismiss()
				)
