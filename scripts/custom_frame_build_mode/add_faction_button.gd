extends Button
class_name AddFactionButton

var faction_hbox_prefab: PackedScene = preload("res://scenes/custom_frame_build_mode/faction_hbox.tscn")

@export var factions_vbox: VBoxContainer

func _ready() -> void:
	button_up.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	var fhb: FactionHBox = faction_hbox_prefab.instantiate()
	factions_vbox.add_child(fhb)
	factions_vbox.move_child(self, factions_vbox.get_children().size() - 1)
