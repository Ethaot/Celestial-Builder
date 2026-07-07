extends Node

const CONFIG_DIR: String = "user://cfg/"
const SAVE_DIR: String = "user://saves/"
const SAVE_CYCLE_TIMER: float = 5.0

signal save_data_loaded

var save_data: SaveData
var config: Config
var save_clock: float = 0.0
var data_changed: bool = false

func _ready() -> void:
	load_config()
	load_save_data(config.last_loaded_save_id)

func _process(delta: float) -> void:
	save_clock += delta
	if save_clock > SAVE_CYCLE_TIMER:
		save_clock = 0.0
		if data_changed:
			save_save_data()

func save_config() -> void:
	if !DirAccess.dir_exists_absolute(CONFIG_DIR):
		DirAccess.make_dir_absolute(CONFIG_DIR)
	var cfg_dict: Dictionary[String, String] = {"last_loaded_save_id": config.last_loaded_save_id}
	var file = FileAccess.open(CONFIG_DIR + "config.json", FileAccess.WRITE)
	var cfg_string: String = JSON.stringify(cfg_dict, "\t")
	file.store_line(cfg_string)
	file.close()
	
func load_config() -> void:
	save_save_data()
	if DirAccess.dir_exists_absolute(CONFIG_DIR):
		if FileAccess.file_exists(CONFIG_DIR + "config.json"):
			var file = FileAccess.open(CONFIG_DIR + "config.json", FileAccess.READ)
			var cfg_string: String = file.get_as_text()
			var json_string = JSON.parse_string(cfg_string)
			if json_string is Dictionary:
				var loaded_cfg: Config = Config.new()
				if json_string["last_loaded_save_id"].length() > 0:
					loaded_cfg.last_loaded_save_id = json_string["last_loaded_save_id"]
				config = loaded_cfg
			file.close()
		else:
			config = Config.new()
			save_config()
	else:
		config = Config.new()
		save_config()

func save_save_data() -> void:
	if is_instance_valid(save_data):
		if save_data.character.lamplighter_name != "":
			if save_data.save_id == "":
				save_data.save_id = UuidGenerator.generate_uuid()
			if !DirAccess.dir_exists_absolute(SAVE_DIR):
				DirAccess.make_dir_absolute(SAVE_DIR)
			var sd_dict: Dictionary = save_data.to_dict()
			var file = FileAccess.open(SAVE_DIR + save_data.save_id + ".json", FileAccess.WRITE)
			var json_string = JSON.stringify(sd_dict, "\t")
			file.store_line(json_string)
			file.close()
			data_changed = false
			print("Data Saved. (data_manager)")

func load_save_data(save_id: String) -> void:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		if FileAccess.file_exists(SAVE_DIR + save_id + ".json"):
			var file = FileAccess.open(SAVE_DIR + save_id + ".json", FileAccess.READ)
			var json_string: String = file.get_as_text()
			var parsed_data = JSON.parse_string(json_string)
			if parsed_data is Dictionary:
				var sd: SaveData = SaveData.new()
				sd.from_dict(parsed_data)
				save_data = sd
				config.last_loaded_save_id = save_id
				save_config()
				save_data_loaded.emit()
			file.close()
		else:
			save_data = SaveData.new()
	else:
		DirAccess.make_dir_absolute(SAVE_DIR)
		save_data = SaveData.new()
		

func delete_save_data(save_id: String) -> void:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		if FileAccess.file_exists(SAVE_DIR + save_id + ".json"):
			var file = FileAccess.open(SAVE_DIR + save_id + ".json",FileAccess.READ)
			var json_string: String = file.get_as_text()
			var data = JSON.parse_string(json_string)
			file.close()
			if data is Dictionary:
				if data["save_id"] == save_id:
					DirAccess.remove_absolute(SAVE_DIR + save_id + ".json")

func get_saves_dicts() -> Array[Dictionary]:
	var saves_dict_array: Array[Dictionary] = []
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		var dir: DirAccess = DirAccess.open(SAVE_DIR)
		if !dir:
			push_error("Failed to open saves directory. (data_manager)")
			return saves_dict_array
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		if file_name != "":
			var full_path: String = SAVE_DIR.path_join(file_name)
			var clean_path = full_path.replace(".remap", "")
			if clean_path.ends_with(".json"):
				var file = FileAccess.open(clean_path, FileAccess.READ)
				var json_string: String = file.get_as_text()
				var data = JSON.parse_string(json_string)
				if data is Dictionary:
					var dict: Dictionary[String, String] = {data["save_id"]: data["character"]["lamplighter_name"]}
					saves_dict_array.append(dict)
	return saves_dict_array
