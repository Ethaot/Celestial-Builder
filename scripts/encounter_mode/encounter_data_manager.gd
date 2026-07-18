extends Node
class_name EncounterDataManager

const ENCOUNTER_SAVE_PATH: String = "user://encounters/"
const SAVE_TIMER: float = 5.0

@export var encounter_signal_bus: EncounterSignalBus

var current_encounter: Encounter
var current_combatant: Character

var save_clock: float = 0.0
var data_changed: bool = false

func _ready() -> void:
	if DataManager.config.last_loaded_encounter_id.length() == 0:
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

func add_combatant(combatant: Character) -> void:
	combatant.lamplighter_id = UuidGenerator.generate_uuid()
	current_encounter.combatants.append(combatant)
	current_combatant = combatant
	data_changed = true

func update_combatant(index: int, combatant: Character) -> void:
	current_encounter.combatants[index] = combatant
	data_changed = true

func update_combatant_by_id(id: String, combatant: Character) -> void:
	for c in current_encounter.combatants:
		if c.lamplighter_id == id:
			c = combatant
			data_changed = true
			break

func delete_combatant(index: int) -> void:
	pass

func switch_combatant(index: int) -> void:
	current_combatant = current_encounter.combatants[index]

func clear_encounter() -> void:
	current_encounter.combatants.clear()
	var new_combatant: Character = Character.new()
	new_combatant.lamplighter_name = "New Combatant"
	new_combatant.current_frame_build = FrameBuild.new()
	new_combatant.current_frame_build.frame_id = ResourceManager.frames[0].frame_id
	add_combatant(new_combatant)

func create_new_encounter() -> void:
	print("Creating new encounter.")
	if current_encounter != null:
		save_encounter()
	current_encounter = Encounter.new()
	var new_combatant: Character = Character.new()
	new_combatant.lamplighter_name = "New Combatant"
	new_combatant.current_frame_build = FrameBuild.new()
	new_combatant.current_frame_build.frame_id = ResourceManager.frames[0].frame_id
	add_combatant(new_combatant)
	encounter_signal_bus.load_encounter_finished()

func save_encounter() -> void:
	print("Saving current encounter...")
	if !current_encounter.encounter_id.length() > 0:
		print("Assigning new ID to encounter.")
		current_encounter.encounter_id = UuidGenerator.generate_uuid()
	var data: Dictionary = current_encounter.to_dict()
	var json_string: String = JSON.stringify(data, "\t")
	if !DirAccess.dir_exists_absolute(ENCOUNTER_SAVE_PATH):
		print("Creating encounter save directory.")
		DirAccess.make_dir_absolute(ENCOUNTER_SAVE_PATH)
	var file = FileAccess.open(ENCOUNTER_SAVE_PATH + current_encounter.encounter_id + ".json", FileAccess.WRITE)
	if file.store_line(json_string):
		DataManager.config.last_loaded_encounter_id = current_encounter.encounter_id
		DataManager.save_config()
		print("Current encounter saved.")
	else:
		push_error("Could not save encounter.")
	file.close()
	data_changed = false

func load_encounter(path: String) -> void:
	print("Loading encounter...")
	if current_encounter != null:
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
			if current_encounter.combatants.size() > 0:
				current_combatant = current_encounter.combatants[0]
			else:
				var new_combatant: Character = Character.new()
				new_combatant.lamplighter_name = "New Combatant"
				new_combatant.current_frame_build = FrameBuild.new()
				new_combatant.current_frame_build.frame_id = ResourceManager.frames[0].frame_id
				add_combatant(new_combatant)
			encounter_signal_bus.load_encounter_finished()
			return
		else:
			push_error("Encounter data is not dictionary.")
			file.close()
			return
	else:
		push_error("Encounter file path doesn't exist.")
		return
