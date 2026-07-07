extends HBoxContainer
class_name AttributeHBox

enum ATTRIBUTE {Nerve, Flash, Precision, Force, Psychic}
enum MODE {Normal, Edit}

signal attribute_edited

@export var attribute_type: ATTRIBUTE
@export var attribute_name_label: Label
@export var attribute_up_button: Button
@export var attribute_total_label: Label
@export var attribute_down_button: Button
@export var attribute_bonus_label: Label
@export var attribute_bonus_vbox: VBoxContainer
@export var attribute_bonus_up_button: Button
@export var attribute_bonus_amount_label: Label
@export var attribute_bonus_down_button: Button

var current_mode: MODE = MODE.Normal

func _ready() -> void:
	match attribute_type:
		ATTRIBUTE.Nerve:
			attribute_name_label.text = "Nerve"
		ATTRIBUTE.Flash:
			attribute_name_label.text = "Flash"
		ATTRIBUTE.Precision:
			attribute_name_label.text = "Precision"
		ATTRIBUTE.Force:
			attribute_name_label.text = "Force"
		ATTRIBUTE.Psychic:
			attribute_name_label.text = "Psychic"
	attribute_up_button.button_up.connect(_on_attribute_up_button_clicked)
	attribute_down_button.button_up.connect(_on_attribute_down_button_clicked)
	attribute_bonus_up_button.button_up.connect(_on_attribute_bonus_up_button_clicked)
	attribute_bonus_down_button.button_up.connect(_on_attribute_bonus_down_button_clicked)

func display_attribute_amount() -> void:
	match current_mode:
		MODE.Normal:
			match attribute_type:
				ATTRIBUTE.Nerve:
					attribute_total_label.text = str(DataManager.save_data.character.attributes_current[0]) + "/" + str(DataManager.save_data.character.attributes[0] + DataManager.save_data.character.attribute_bonuses[0])
				ATTRIBUTE.Flash:
					attribute_total_label.text = str(DataManager.save_data.character.attributes_current[1]) + "/" + str(DataManager.save_data.character.attributes[1] + DataManager.save_data.character.attribute_bonuses[1])
				ATTRIBUTE.Precision:
					attribute_total_label.text = str(DataManager.save_data.character.attributes_current[2]) + "/" + str(DataManager.save_data.character.attributes[2] + DataManager.save_data.character.attribute_bonuses[2])
				ATTRIBUTE.Force:
					attribute_total_label.text = str(DataManager.save_data.character.attributes_current[3]) + "/" + str(DataManager.save_data.character.attributes[3] + DataManager.save_data.character.attribute_bonuses[3])
				ATTRIBUTE.Psychic:
					attribute_total_label.text = str(DataManager.save_data.character.attributes_current[4]) + "/" + str(DataManager.save_data.character.attributes[4] + DataManager.save_data.character.attribute_bonuses[4])
		MODE.Edit:
			match attribute_type:
				ATTRIBUTE.Nerve:
					attribute_total_label.text = str(DataManager.save_data.character.attributes[0])
					attribute_bonus_amount_label.text = str(DataManager.save_data.character.attribute_bonuses[0])
				ATTRIBUTE.Flash:
					attribute_total_label.text = str(DataManager.save_data.character.attributes[1])
					attribute_bonus_amount_label.text = str(DataManager.save_data.character.attribute_bonuses[1])
				ATTRIBUTE.Precision:
					attribute_total_label.text = str(DataManager.save_data.character.attributes[2])
					attribute_bonus_amount_label.text = str(DataManager.save_data.character.attribute_bonuses[2])
				ATTRIBUTE.Force:
					attribute_total_label.text = str(DataManager.save_data.character.attributes[3])
					attribute_bonus_amount_label.text = str(DataManager.save_data.character.attribute_bonuses[3])
				ATTRIBUTE.Psychic:
					attribute_total_label.text = str(DataManager.save_data.character.attributes[4])
					attribute_bonus_amount_label.text = str(DataManager.save_data.character.attribute_bonuses[4])

func _on_attribute_up_button_clicked() -> void:
	match current_mode:
		MODE.Normal:
			match attribute_type:
				ATTRIBUTE.Nerve:
					DataManager.save_data.character.attributes_current[0] += 1
				ATTRIBUTE.Flash:
					DataManager.save_data.character.attributes_current[1] += 1
				ATTRIBUTE.Precision:
					DataManager.save_data.character.attributes_current[2] += 1
				ATTRIBUTE.Force:
					DataManager.save_data.character.attributes_current[3] += 1
				ATTRIBUTE.Psychic:
					DataManager.save_data.character.attributes_current[4] += 1
		MODE.Edit:
			match attribute_type:
				ATTRIBUTE.Nerve:
					DataManager.save_data.character.attributes[0] += 1
					DataManager.save_data.character.attributes_current[0] += 1
				ATTRIBUTE.Flash:
					DataManager.save_data.character.attributes[1] += 1
					DataManager.save_data.character.attributes_current[1] += 1
				ATTRIBUTE.Precision:
					DataManager.save_data.character.attributes[2] += 1
					DataManager.save_data.character.attributes_current[2] += 1
				ATTRIBUTE.Force:
					DataManager.save_data.character.attributes[3] += 1
					DataManager.save_data.character.attributes_current[3] += 1
				ATTRIBUTE.Psychic:
					DataManager.save_data.character.attributes[4] += 1
					DataManager.save_data.character.attributes_current[4] += 1
			attribute_edited.emit()
	display_attribute_amount()
	DataManager.data_changed = true

func _on_attribute_down_button_clicked() -> void:
	match current_mode:
		MODE.Normal:
			match attribute_type:
				ATTRIBUTE.Nerve:
					DataManager.save_data.character.attributes_current[0] -= 1
				ATTRIBUTE.Flash:
					DataManager.save_data.character.attributes_current[1] -= 1
				ATTRIBUTE.Precision:
					DataManager.save_data.character.attributes_current[2] -= 1
				ATTRIBUTE.Force:
					DataManager.save_data.character.attributes_current[3] -= 1
				ATTRIBUTE.Psychic:
					DataManager.save_data.character.attributes_current[4] -= 1
		MODE.Edit:
			match attribute_type:
				ATTRIBUTE.Nerve:
					DataManager.save_data.character.attributes[0] -= 1
					DataManager.save_data.character.attributes_current[0] -= 1
				ATTRIBUTE.Flash:
					DataManager.save_data.character.attributes[1] -= 1
					DataManager.save_data.character.attributes_current[1] -= 1
				ATTRIBUTE.Precision:
					DataManager.save_data.character.attributes[2] -= 1
					DataManager.save_data.character.attributes_current[2] -= 1
				ATTRIBUTE.Force:
					DataManager.save_data.character.attributes[3] -= 1
					DataManager.save_data.character.attributes_current[3] -= 1
				ATTRIBUTE.Psychic:
					DataManager.save_data.character.attributes[4] -= 1
					DataManager.save_data.character.attributes_current[4] -= 1
			attribute_edited.emit()
	display_attribute_amount()
	DataManager.data_changed = true

func _on_attribute_bonus_up_button_clicked() -> void:
	match attribute_type:
		ATTRIBUTE.Nerve:
			DataManager.save_data.character.attribute_bonuses[0] += 1
		ATTRIBUTE.Flash:
			DataManager.save_data.character.attribute_bonuses[1] += 1
		ATTRIBUTE.Precision:
			DataManager.save_data.character.attribute_bonuses[2] += 1
		ATTRIBUTE.Force:
			DataManager.save_data.character.attribute_bonuses[3] += 1
		ATTRIBUTE.Psychic:
			DataManager.save_data.character.attribute_bonuses[4] += 1
	display_attribute_amount()
	DataManager.data_changed = true

func _on_attribute_bonus_down_button_clicked() -> void:
	match attribute_type:
		ATTRIBUTE.Nerve:
			DataManager.save_data.character.attribute_bonuses[0] -= 1
		ATTRIBUTE.Flash:
			DataManager.save_data.character.attribute_bonuses[1] -= 1
		ATTRIBUTE.Precision:
			DataManager.save_data.character.attribute_bonuses[2] -= 1
		ATTRIBUTE.Force:
			DataManager.save_data.character.attribute_bonuses[3] -= 1
		ATTRIBUTE.Psychic:
			DataManager.save_data.character.attribute_bonuses[4] -= 1
	display_attribute_amount()
	DataManager.data_changed = true
