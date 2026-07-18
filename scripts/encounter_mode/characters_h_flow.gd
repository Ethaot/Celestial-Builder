extends HFlowContainer
class_name EncounterCombatantsHFlowContainer

var button_prefab: PackedScene = preload("res://scenes/load_frame_build_button.tscn")

@export var encounter_data_manager: EncounterDataManager
@export var encounter_signal_bus: EncounterSignalBus
@export var add_combatant_button: MobileFriendlyButton

var combatant_buttons: Array[Button]

func _ready() -> void:
	encounter_signal_bus.combatant_added.connect(populate_combatant_buttons)
	encounter_signal_bus.encounter_cleared.connect(populate_combatant_buttons)
	encounter_signal_bus.combatant_updated.connect(populate_combatant_buttons)
	encounter_signal_bus.encounter_loaded.connect(populate_combatant_buttons)
	encounter_signal_bus.combatant_deleted.connect(populate_combatant_buttons)
	encounter_signal_bus.combatant_switched.connect(set_buttons_disabled)

func populate_combatant_buttons() -> void:
	var children: Array[Node] = get_children()
	for i in range(children.size() - 1):
		children[i].queue_free()
	combatant_buttons.clear()
	for i in range(encounter_data_manager.current_encounter.combatants.size()):
		var b: Button = button_prefab.instantiate()
		b.text = encounter_data_manager.current_encounter.combatants[i].lamplighter_name
		b.button_up.connect(encounter_signal_bus.switch_combatant.bind(i))
		combatant_buttons.append(b)
		add_child(b)
	move_child(add_combatant_button, get_children().size() - 1)
	set_buttons_disabled()

func set_buttons_disabled() -> void:
	for i in range(combatant_buttons.size()):
		if encounter_data_manager.current_encounter.combatants[i].lamplighter_id == encounter_data_manager.current_combatant.lamplighter_id:
			combatant_buttons[i].disabled = true
		else:
			combatant_buttons[i].disabled = false
