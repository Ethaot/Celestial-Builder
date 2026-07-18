extends VBoxContainer
class_name EncounterShieldsVBox

@export var name_label: Label
@export var up_button: Button
@export var capacity_label: Label
@export var down_button: Button

var encounter_data_manager: EncounterDataManager
var shield_index: int
var shield_max_amount: int

func _ready() -> void:
	up_button.button_up.connect(_on_up_button_pressed)
	down_button.button_up.connect(_on_down_button_pressed)

func set_shield_max_amount(shield_name: String, amt: int) -> void:
	name_label.text = shield_name
	shield_max_amount = amt
	set_shield_current_amount(amt)
	#current_shield_amount = amt
	#capacity_label.text = str(current_shield_amount) + "/" + str(shield_max_amount)

func set_shield_current_amount(amt: int) -> void:
	encounter_data_manager.current_combatant.current_shields[shield_index] = amt
	capacity_label.text = str(encounter_data_manager.current_combatant.current_shields[shield_index]) + "/" + str(shield_max_amount)
	
func _on_up_button_pressed() -> void:
	encounter_data_manager.current_combatant.current_shields[shield_index] += 1
	capacity_label.text = str(encounter_data_manager.current_combatant.current_shields[shield_index]) + "/" + str(shield_max_amount)
	encounter_data_manager.data_changed = true

func _on_down_button_pressed() -> void:
	encounter_data_manager.current_combatant.current_shields[shield_index] -= 1
	capacity_label.text = str(encounter_data_manager.current_combatant.current_shields[shield_index]) + "/" + str(shield_max_amount)
	encounter_data_manager.data_changed = true
