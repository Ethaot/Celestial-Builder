extends VBoxContainer
class_name ShieldsVBox

@export var name_label: Label
@export var up_button: Button
@export var capacity_label: Label
@export var down_button: Button

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
	DataManager.save_data.character.current_shields[shield_index] = amt
	capacity_label.text = str(DataManager.save_data.character.current_shields[shield_index]) + "/" + str(shield_max_amount)
	
func _on_up_button_pressed() -> void:
	DataManager.save_data.character.current_shields[shield_index] += 1
	capacity_label.text = str(DataManager.save_data.character.current_shields[shield_index]) + "/" + str(shield_max_amount)
	DataManager.data_changed = true

func _on_down_button_pressed() -> void:
	DataManager.save_data.character.current_shields[shield_index] -= 1
	capacity_label.text = str(DataManager.save_data.character.current_shields[shield_index]) + "/" + str(shield_max_amount)
	DataManager.data_changed = true
