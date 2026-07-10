extends Resource
class_name Encounter

var encounter_name: String
var encounter_id: String
var combatants: Array[Character]

func to_dict() -> Dictionary:
	var combatant_dicts: Array[Dictionary]
	for c in combatants:
		combatant_dicts.append(c.to_dict())
	var dict: Dictionary = {
		"encounter_name": encounter_name,
		"encounter_id": encounter_id,
		"combatants": combatant_dicts
	}
	return dict

func from_dict(dict: Dictionary) -> void:
	encounter_name = dict["encounter_name"]
	encounter_id = dict["encounter_id"]
	for c in dict["combatants"]:
		var new_c: Character = Character.new()
		new_c.from_dict(c)
		combatants.append(new_c)
