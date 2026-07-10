extends Node
class_name EncounterDataManager

const ENCOUNTER_SAVE_PATH: String = "user://encounters/"
const SAVE_TIMER: float = 5.0

var current_encounter: Encounter

var save_clock: float = 0.0
var data_changed: bool = false

func _ready() -> void:
	if DataManager.config.last_loaded_encounter_id == "":
		create_new_encounter()
	elif FileAccess.file_exists(ENCOUNTER_SAVE_PATH + DataManager.config.last_loaded_encounter_id + ".json"):
		load_encounter(ENCOUNTER_SAVE_PATH + DataManager.config.last_loaded_encounter_id + ".json")
	else:
		create_new_encounter()
		

func _process(delta: float) -> void:
	save_clock += delta
	if save_clock > SAVE_TIMER:
		save_clock = 0.0
		if data_changed:
			save_encounter()

func create_new_encounter() -> void:
	current_encounter = Encounter.new()

func save_encounter() -> void:
	print("Saving current encounter...")
	var data: Dictionary = current_encounter.to_dict()
	var json_string: String = JSON.stringify(data)
	var file = FileAccess.open(ENCOUNTER_SAVE_PATH + current_encounter.encounter_id + ".json", FileAccess.WRITE)
	if file.store_line(json_string):
		print("Current encounter saved.")
	else:
		push_error("Could not save encounter.")
	file.close()
	data_changed = false

func load_encounter(path: String) -> void:
	print("Loading encounter...")
	save_encounter()
	current_encounter = Encounter.new()
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_string = file.get_as_text()
		var data = JSON.parse_string(json_string)
		if data is Dictionary:
			current_encounter.from_dict(data)
			file.close()
			print("Encounter loaded.")
			return
		else:
			push_error("Encounter data is not dictionary.")
			file.close()
			return
	else:
		push_error("Encounter file path doesn't exist.")
		return
