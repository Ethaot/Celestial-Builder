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
	ResourceSaver.save(config, CONFIG_DIR + "config.tres")
	
func load_config() -> void:
	save_save_data()
	if DirAccess.dir_exists_absolute(CONFIG_DIR):
		if FileAccess.file_exists(CONFIG_DIR + "config.tres"):
			var res: Resource = ResourceLoader.load(CONFIG_DIR + "config.tres")
			if res is Config:
				config = res
		else:
			config = Config.new()
			save_config()
	else:
		config = Config.new()
		save_config()

func save_save_data() -> void:
	if is_instance_valid(save_data):
		if save_data.lamplighter_name != "":
			if save_data.save_id == "":
				save_data.save_id = UuidGenerator.generate_uuid()
			if !DirAccess.dir_exists_absolute(SAVE_DIR):
				DirAccess.make_dir_absolute(SAVE_DIR)
			ResourceSaver.save(save_data, SAVE_DIR + save_data.save_id + ".tres")
			data_changed = false
			print("Data Saved. (data_manager)")

func load_save_data(save_id: String) -> void:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		if FileAccess.file_exists(SAVE_DIR + save_id + ".tres"):
			var res: Resource = ResourceLoader.load(SAVE_DIR + save_id + ".tres")
			if res is SaveData:
				save_data = res
				config.last_loaded_save_id = save_id
				save_config()
				save_data_loaded.emit()
		else:
			save_data = SaveData.new()
	else:
		DirAccess.make_dir_absolute(SAVE_DIR)
		save_data = SaveData.new()
		

func delete_save_data(save_id: String) -> void:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		if FileAccess.file_exists(SAVE_DIR + save_id + ".tres"):
			var res: Resource = ResourceLoader.load(SAVE_DIR + save_id + ".tres")
			if res is SaveData:
				if res.save_id == save_id:
					DirAccess.remove_absolute(SAVE_DIR + save_id + ".tres")

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
			if clean_path.ends_with(".tres"):
				var res: Resource = load(clean_path)
				if res is SaveData:
					var dict: Dictionary[String, String] = {res.save_id: res.lamplighter_name}
					saves_dict_array.append(dict)
	return saves_dict_array
