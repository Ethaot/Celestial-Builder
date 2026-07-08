extends Node

const DATA_PACKS_PATH: String = "user://data_packs/"
const TEMP_FOLDER: String = "user://tmp/"

signal check_complete
signal download_complete
signal all_downloads_complete
signal prepared_signal

var main_theme_res: Theme = preload("res://MainTheme.tres")
var player_grid_gradient: Texture2D = preload("res://assets/ui/player_grid_gradient.png")

var weapons_ranged: Array[Part]
var weapons_explosive: Array[Part]
var weapons_melee: Array[Part]
var weapons_ew: Array[Part]
var weapons_missiles: Array[Part]
var parts_reactors: Array[Part]
var parts_thrusters: Array[Part]
var parts_processors: Array[Part]
var parts_shields: Array[Part]

var frames: Array[Frame]
var frame_builds: Array[FrameBuild]

var part_dict: Dictionary[String, Part]
var part_image_dict: Dictionary[String, Array]
var frame_dict: Dictionary[String, Frame]

var player_grid_gradient_atlastextures: Array[AtlasTexture]

var http_request: HTTPRequest
var http_checker: HTTPRequest
var manifests: Array[Dictionary]
var currently_checked_modified: String
var currently_checked_etag: String
var current_package_id: String
var current_package_url: String
var packages_to_download: Dictionary[String, String]
var current_tmp_file: int = 0
var temp_files: Array

var prepared: bool = false
var downloads_complete: bool = false

func _ready() -> void:
	http_request = HTTPRequest.new()
	http_checker = HTTPRequest.new()
	add_child(http_request)
	add_child(http_checker)
	
	http_request.request_completed.connect(_on_request_completed)
	http_checker.request_completed.connect(_on_http_check_completed)
	
	if !OS.has_feature("mobile") and !OS.has_feature("web_android") and !OS.has_feature("web_ios"):
		main_theme_res.default_font_size = 32
	
	check_create_directories()
	manifests = get_data_pack_manifest()
	get_data_packs()
	#_await_response_with_timeout(all_downloads_complete, 30.0)
	if !downloads_complete:
		await all_downloads_complete
	
	update_manifest()
	#var parts_array: Array[Part] = import_parts("res://parts/", ".tres")
	
	for manifest in manifests:
		var parts_array: Array[Part] = import_parts_dicts(DATA_PACKS_PATH + manifest["package_id"] + "/")
		part_dict.assign(construct_parts_dict(parts_array))
		assign_parts_array(parse_parts(parts_array))
		
		frames = import_frames_dicts(DATA_PACKS_PATH + manifest["package_id"] + "/")
		
		frame_builds = import_frame_build_dicts(DATA_PACKS_PATH + manifest["package_id"] + "/")
		
	part_image_dict = get_part_images_dict()
	frame_dict = construct_frame_dict(frames)
	player_grid_gradient_atlastextures = create_player_grid_gradient_atlastextures()
	
	prepared = true
	prepared_signal.emit()

func check_create_directories() -> void:
	if !DirAccess.dir_exists_absolute(DATA_PACKS_PATH):
		DirAccess.make_dir_absolute(DATA_PACKS_PATH)
	if !DirAccess.dir_exists_absolute(TEMP_FOLDER):
		DirAccess.make_dir_absolute(TEMP_FOLDER)

func get_data_pack_manifest() -> Array[Dictionary]:
	print("Retrieving data pack manifests...")
	var data_pack_manifest_data: Array[Dictionary] = []
	#DirAccess.remove_absolute(DATA_PACKS_PATH + "data_packs_manifest.json")
	if DirAccess.dir_exists_absolute(DATA_PACKS_PATH):
		if FileAccess.file_exists(DATA_PACKS_PATH + "data_packs_manifest.json"):
			print("Manifest file found. Loading data packs...")
			var file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.READ)
			var json_string: String = file.get_as_text()
			var parsed_data = JSON.parse_string(json_string)
			if parsed_data is Array:
				if parsed_data.size() > 0:
					for d in parsed_data:
						if d is Dictionary:
							if d["package_id"] == "celestial-bodies-core":
								if d["package_url"] != "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core.zip":
									d["package_url"] = "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core.zip"
							data_pack_manifest_data.append(d)
				else:
					var core_data: Dictionary[String, String] = {
						"package_name": "Celestial Bodies Core",
						"package_id": "celestial-bodies-core",
						#"package_url": "https://drive.google.com/uc?export=download&id=1ljWT3lqiRA-prXqxJZVfp-YE9WA3XRSl",
						"package_url": "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core.zip",
						"author": "Binary Star Games",
						"version": "0.0.1",
						"etag": "ETag: big_empy"
					}
					data_pack_manifest_data.append(core_data)
			file.close()
		else:
			print("Manifest file not found. Creating new Core Data.")
			var core_data: Dictionary[String, String] = {
				"package_name": "Celestial Bodies Core",
				"package_id": "celestial-bodies-core",
				#"package_url": "https://drive.google.com/uc?export=download&id=1ljWT3lqiRA-prXqxJZVfp-YE9WA3XRSl",
				"package_url": "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core.zip",
				"author": "Binary Star Games",
				"version": "0.0.1",
				"etag": "ETag: big_empy"
				}
			data_pack_manifest_data.append(core_data)
			#var file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.WRITE)
			#var data: String = JSON.stringify(data_pack_manifest_data, "\t")
			#if file:
				#file.store_line(data)
				#file.close()
			#else:
				#push_error("Couldn't create the data packs manifest file at the destination.")
	print("Retrieved data pack manifests (" + str(data_pack_manifest_data.size()) + " manifests found).")
	return data_pack_manifest_data

func get_data_packs() -> void:
	print("Checking and downloading packages...")
	for i in range(manifests.size()):
		#http_request.download_file = TEMP_FOLDER + "tmp" + str(i) + ".zip"
		currently_checked_etag = manifests[i]["etag"]
		current_package_id = manifests[i]["package_id"]
		current_package_url = manifests[i]["package_url"]
		print("Checking package " + manifests[i]["package_id"])
		var err: Error = http_checker.request(current_package_url, [], HTTPClient.METHOD_HEAD)
		if err == OK:
			await _await_response_with_timeout(check_complete, 5.0)
			manifests[i]["etag"] = currently_checked_etag
			#await check_complete
		else:
			push_error("Error checking package url for updates. Error code: ", err)
	
	for package_id in packages_to_download:
		print("Downloading package " + package_id)
		var err: Error = http_request.request_raw(packages_to_download[package_id])
		if err == OK:
			await _await_response_with_timeout(download_complete, 15.0)
			#await download_complete
		else:
			push_error("Error downloading data pack. Error code: ", err)
	
	print("Package downloads complete.")
	all_downloads_complete.emit()
	downloads_complete = true
	#if DirAccess.dir_exists_absolute(DATA_PACKS_PATH + "celestial-bodies-core/"):
		#if !FileAccess.file_exists(DATA_PACKS_PATH + "celestial-bodies-core/manifest.json"):
			#var err: Error = http_request.request("https://drive.google.com/uc?export=download&id=1ljWT3lqiRA-prXqxJZVfp-YE9WA3XRSl")
			#if err != OK:
				#push_error("Error downloading data pack. Error code: ", err)
	#else:
		#DirAccess.make_dir_absolute(DATA_PACKS_PATH + "celestial-bodies-core/")
		#if !FileAccess.file_exists(DATA_PACKS_PATH + "celestial-bodies-core/manifest.json"):
			#var err: Error = http_request.request("https://drive.google.com/uc?export=download&id=1ljWT3lqiRA-prXqxJZVfp-YE9WA3XRSl")
			#if err != OK:
				#push_error("Error downloading data pack. Error code: ", err)

func update_manifest() -> void:
	print("Updating manifests...")
	var new_manifest_data: Array[Dictionary]
	for m in manifests:
		if FileAccess.file_exists(DATA_PACKS_PATH + m["package_id"] + "/manifest.json"):
			var m_file = FileAccess.open(DATA_PACKS_PATH + m["package_id"] + "/manifest.json", FileAccess.READ)
			var m_string = m_file.get_as_text()
			var m_data = JSON.parse_string(m_string)
			if m_data is Array:
				if m_data[0] is Dictionary:
					var clean_dict: Dictionary = {
						"package_name": m_data[0]["package_name"],
						"package_id": m_data[0]["package_id"],
						"package_url": m_data[0]["package_url"],
						"author": m_data[0]["author"],
						"version": m_data[0]["version"],
						"etag": m["etag"]
					}
					new_manifest_data.append(clean_dict)
	var new_manifest_string: String = JSON.stringify(new_manifest_data, "\t")
	var file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.WRITE)
	#var json_data: String = JSON.stringify(manifests, "\t")
	file.store_line(new_manifest_string)
	file.close()
	print("Manifests updated.")
		

func make_parts_json(pa: Array[Part]) -> void:
	var dict_array: Array[Dictionary]
	for p in pa:
		var pd: Dictionary = {
			"part_name": p.part_name,
			"part_id": p.part_id,
			"part_type": p.part_type,
			"powered": p.powered,
			"part_configuration": p.part_configuration,
			"part_icon": p.part_id,
			"part_description": p.part_description,
			"requirements": p.requirements,
			"part_tab": p.part_tab
		}
		dict_array.append(pd)
	if !DirAccess.dir_exists_absolute(DATA_PACKS_PATH + "celestial-bodies-core/"):
		DirAccess.make_dir_absolute(DATA_PACKS_PATH + "celestial-bodies-core/")
	var file = FileAccess.open(DATA_PACKS_PATH + "celestial-bodies-core/parts.json", FileAccess.WRITE)
	var json_string: String = JSON.stringify(dict_array, "\t")
	if file:
		file.store_line(json_string)
		file.close()
	else:
		push_error("Couldn't make the parts json. Error code: ", FileAccess.get_open_error())

func make_frames_json(fa: Array[Frame]) -> void:
	var dict_array: Array[Dictionary]
	for f in fa:
		var fd: Dictionary = {
			"frame_name": f.frame_name,
			"frame_id": f.frame_id,
			"frame_available_slots": f.frame_available_slots,
			"frame_feature_name": f.frame_feature_name,
			"frame_feature_text": f.frame_feature_text,
			"frame_hp": f.frame_hp,
			"frame_armor_slots": f.frame_armor_slots,
			"frame_reinforced_armor_slots": f.frame_reinforced_armor_slots,
			"frame_size": f.frame_size,
			"titan": false,
			"unusual": false
		}
		dict_array.append(fd)
	if !DirAccess.dir_exists_absolute(DATA_PACKS_PATH + "celestial-bodies-core/"):
		DirAccess.make_dir_absolute(DATA_PACKS_PATH + "celestial-bodies-core/")
	var file = FileAccess.open(DATA_PACKS_PATH + "celestial-bodies-core/frames.json", FileAccess.WRITE)
	var json_string: String = JSON.stringify(dict_array, "\t")
	if file:
		file.store_line(json_string)
		file.close()
	else:
		push_error("Couldn't make the frames json. Error code: ", FileAccess.get_open_error())

func import_parts_dicts(path: String) -> Array[Part]:
	print("Importing parts...")
	var loaded_parts: Array[Part]
	if !DirAccess.dir_exists_absolute(path):
		push_error("Failed to open parts directory. (resource_manager)")
		return loaded_parts
	var file_name: String = path + "parts.json"
	if FileAccess.file_exists(file_name):
		var file  = FileAccess.open(file_name, FileAccess.READ)
		if !file:
			push_error("Error opening parts JSON. (resource_manager)")
			return loaded_parts
		var json_string = file.get_as_text()
		file.close()
		var parsed_data = JSON.parse_string(json_string)
		if parsed_data is Array:
			for d in parsed_data:
				if d is Dictionary:
					var part: Part
					if d["part_type"] == Constants.PartType.PartReactor:
						part = Reactor.new()
					elif d["part_type"] == Constants.PartType.PartShield:
						part = Shield.new()
					else:
						part = Part.new()
					part.part_name = d["part_name"]
					part.part_id = d["part_id"]
					part.part_type = d["part_type"]
					part.powered = d["powered"]
					var regex = RegEx.new()
					regex.compile("-?\\d+")
					for i in range(d["part_configuration"].size()):
						var matches = regex.search_all(d["part_configuration"][i])
						var x: int = matches[0].get_string().to_int()
						var y: int = matches[1].get_string().to_int()
						part.part_configuration.append(Vector2i(x, y))
					part.part_icon = d["part_icon"]
					part.part_description = d["part_description"]
					part.requirements = d["requirements"]
					part.part_tab = d["part_tab"]
					if part.part_type == Constants.PartType.PartReactor:
						part.size = d["size"]
					if part.part_type == Constants.PartType.PartShield:
						part.capacity = d["capacity"]
						part.capacity_modifier = d["capacity_modifier"]
					loaded_parts.append(part)
	print("Parts imported.")
	return loaded_parts
		

func import_parts(path: String, extension: String) -> Array[Part]:
	var loaded_parts: Array[Part]
	var dir: DirAccess = DirAccess.open(path)
	if !dir:
		push_error("Failed to open parts directory. (resource_manager)")
		return loaded_parts
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			var sub_folder_path: String = full_path + "/"
			loaded_parts.append_array(import_parts(sub_folder_path, extension))
		else:
			var clean_path: String = full_path.replace(".remap", "")
			if clean_path.ends_with(extension):
				var res: Resource = load(clean_path)
				if res is Part:
					loaded_parts.append(res)
		
		file_name = dir.get_next()
	return loaded_parts
	
func construct_parts_dict(parts_array: Array[Part]) -> Dictionary[String, Part]:
	var dict: Dictionary[String, Part] = {}
	for p in parts_array:
		dict[p.part_id] = p
	return dict
	
func parse_parts(parts_array: Array[Part]) -> Array[Array]:
	var array_to_return: Array[Array]
	array_to_return.resize(9)
	for part in parts_array:
		match part.part_type:
			Constants.PartType.WeaponRanged:
				array_to_return[0].append(part)
			Constants.PartType.WeaponExplosive:
				array_to_return[1].append(part)
			Constants.PartType.WeaponMelee:
				array_to_return[2].append(part)
			Constants.PartType.WeaponEW:
				array_to_return[3].append(part)
			Constants.PartType.WeaponMissile:
				array_to_return[4].append(part)
			Constants.PartType.PartReactor:
				array_to_return[5].append(part)
			Constants.PartType.PartThruster:
				array_to_return[6].append(part)
			Constants.PartType.PartProcessor:
				array_to_return[7].append(part)
			Constants.PartType.PartShield:
				array_to_return[8].append(part)
	return array_to_return

func assign_parts_array(parts_array: Array[Array]) -> void:
	weapons_ranged.append_array(parts_array[0])
	weapons_explosive.append_array(parts_array[1])
	weapons_melee.append_array(parts_array[2])
	weapons_ew.append_array(parts_array[3])
	weapons_missiles.append_array(parts_array[4])
	parts_reactors.append_array(parts_array[5])
	parts_thrusters.append_array(parts_array[6])
	parts_processors.append_array(parts_array[7])
	parts_shields.append_array(parts_array[8])

func get_part_images_dict() -> Dictionary[String, Array]:
	var dict: Dictionary[String, Array] = {}
	for key in part_dict:
		var img: Image =  Image.load_from_file(DATA_PACKS_PATH + part_dict[key].part_icon)
		if is_instance_valid(img):
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			var tiles_x: int = 1
			var tiles_y: int = 1
			for pc in part_dict[key].part_configuration:
				if pc.x + 1 > tiles_x:
					tiles_x = pc.x + 1
				if pc.y + 1 > tiles_y:
					tiles_y = pc.y + 1
			var tile_size_x: int = floori(float(img.get_size().x) / tiles_x)
			var tile_size_y: int = floori(float(img.get_size().y) / tiles_y)
			var tile_size: Vector2i = Vector2i(tile_size_x, tile_size_y)
			var at_array: Array[AtlasTexture]
			for y in tiles_y:
				for x in tiles_x:
					var tile_pos: Vector2i = Vector2i(x, y)
					if part_dict[key].part_configuration.has(tile_pos):
						var at: AtlasTexture = AtlasTexture.new()
						at.atlas = tex
						at.region = Rect2(tile_pos * tile_size, tile_size)
						at_array.append(at)
			dict[part_dict[key].part_id] = at_array
		else:
			push_error("Couldn't load image at " + part_dict[key].part_icon)
	return dict

func import_frames(path: String, extension: String) -> Array[Frame]:
	var loaded_frames: Array[Frame]
	var dir: DirAccess = DirAccess.open(path)
	if !dir:
		push_error("Failed to open frames directory (resource_manager).")
		return loaded_frames
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			var sub_folder_path: String = full_path + "/"
			loaded_frames.append_array(import_frames(sub_folder_path, extension))
		else:
			var clean_path: String = full_path.replace(".remap", "")
			if clean_path.ends_with(extension):
				var res: Resource = load(clean_path)
				if res is Frame:
					loaded_frames.append(res)
		
		file_name = dir.get_next()
	return loaded_frames

func import_frames_dicts(path: String) -> Array[Frame]:
	print("Importing frames...")
	var loaded_frames: Array[Frame]
	if !DirAccess.dir_exists_absolute(path):
		push_error("Failed to open frames directory. (resource_manager)")
		return loaded_frames
	var file_name: String = path + "frames.json"
	if FileAccess.file_exists(file_name):
		var file  = FileAccess.open(file_name, FileAccess.READ)
		if !file:
			push_error("Error opening frames JSON. (resource_manager)")
			return loaded_frames
		var json_string = file.get_as_text()
		file.close()
		var parsed_data = JSON.parse_string(json_string)
		if parsed_data is Array:
			for d in parsed_data:
				if d is Dictionary:
					var regex = RegEx.new()
					regex.compile("-?\\d+")
					var f: Frame = Frame.new()
					f.frame_name = d["frame_name"]
					f.frame_id = d["frame_id"]
					for i in range(d["frame_available_slots"].size()):
						var matches = regex.search_all(d["frame_available_slots"][i])
						var x: int = matches[0].get_string().to_int()
						var y: int = matches[1].get_string().to_int()
						f.frame_available_slots.append(Vector2i(x,y))
					f.frame_feature_name = d["frame_feature_name"]
					f.frame_feature_text = d["frame_feature_text"]
					f.frame_hp = d["frame_hp"]
					for i in range(d["frame_armor_slots"].size()):
						var matches = regex.search_all(d["frame_armor_slots"][i])
						var x: int = matches[0].get_string().to_int()
						var y: int = matches[1].get_string().to_int()
						f.frame_armor_slots.append(Vector2i(x,y))
					for i in range(d["frame_reinforced_armor_slots"].size()):
						var matches = regex.search_all(d["frame_reinforced_armor_slots"][i])
						var x: int = matches[0].get_string().to_int()
						var y: int = matches[1].get_string().to_int()
						f.frame_reinforced_armor_slots.append(Vector2i(x,y))
					f.frame_size = d["frame_size"]
					f.titan = d["titan"]
					f.unusual = d["unusual"]
					loaded_frames.append(f)
	print("Frames imported.")
	return loaded_frames

func construct_frame_dict(fr: Array[Frame]) -> Dictionary[String, Frame]:
	var dict: Dictionary[String, Frame] = {}
	for f in fr:
		dict[f.frame_id] = f
	return dict

func import_frame_builds(path: String, extension: String) -> Array[FrameBuild]:
	var loaded_builds: Array[FrameBuild]
	var dir: DirAccess = DirAccess.open(path)
	if !dir:
		push_error("Failed to open frame builds directory (resource_manager).")
		return loaded_builds
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		var full_path: String = path.path_join(file_name)
		if dir.current_is_dir():
			var sub_folder_path: String = full_path + "/"
			loaded_builds.append_array(import_frame_builds(sub_folder_path, extension))
		else:
			var clean_path: String = full_path.replace(".remap", "")
			if clean_path.ends_with(extension):
				var res: Resource = load(clean_path)
				if res is FrameBuild:
					loaded_builds.append(res)
		
		file_name = dir.get_next()
	return loaded_builds

func import_frame_build_dicts(path: String) -> Array[FrameBuild]:
	print("Importing frame builds...")
	var loaded_frame_builds: Array[FrameBuild]
	if !DirAccess.dir_exists_absolute(path):
		push_error("Failed to open frame builds directory. (resource_manager)")
		return loaded_frame_builds
	var file_name: String = path + "frame_builds.json"
	if FileAccess.file_exists(file_name):
		var file  = FileAccess.open(file_name, FileAccess.READ)
		if !file:
			push_error("Error opening frame builds JSON. (resource_manager)")
			return loaded_frame_builds
		var json_string = file.get_as_text()
		file.close()
		var parsed_data = JSON.parse_string(json_string)
		if parsed_data is Array:
			for d in parsed_data:
				if d is Dictionary:
					var regex = RegEx.new()
					regex.compile("-?\\d+")
					var fb: FrameBuild = FrameBuild.new()
					var pi_array: Array[PartInstance] = []
					for pid in d["frame_build_configuration"]:
						var pi: PartInstance = PartInstance.new()
						pi.part_instance_name = pid["part_instance_name"]
						pi.part_id = pid["part_id"]
						#pi.part_instance_slots = pid["part_instance_slots"]
						for slot in pid["part_instance_slots"]:
							pi.part_instance_slots.append(slot)
						#for slot in pid["part_instance_slots"]:
							#var matches = regex.search_all(slot)
							#var x: int = matches[0].get_string().to_int()
							#var y: int = matches[1].get_string().to_int()
							#pi.part_instance_slots.append(Vector2i(x,y))
						pi.mirrored_h = pid["mirrored_h"]
						pi.mirrored_v = pid["mirrored_v"]
						pi.times_rotated = pid["times_rotated"]
						pi_array.append(pi)
					fb.frame_build_name = d["frame_build_name"]
					fb.frame_id = d["frame_id"]
					fb.frame_build_configuration = pi_array
					loaded_frame_builds.append(fb)
	print("Frame builds imported.")
	return loaded_frame_builds

func make_frame_builds_json(fba: Array[FrameBuild]) -> void:
	var dict_array: Array[Dictionary]
	for fb in fba:
		var pi_dict_array: Array[Dictionary] = []
		for pi in fb.frame_build_configuration:
			pi_dict_array.append({
				"part_instance_name": pi.part_instance_name,
				"part_id": pi.part_id,
				"part_instance_slots": pi.part_instance_slots,
				"mirrored_h": pi.mirrored_h,
				"mirrored_v": pi.mirrored_v,
				"times_rotated": pi.times_rotated
			})
		var fd: Dictionary = {
			"frame_build_name": fb.frame_build_name,
			"frame_id": fb.frame_id,
			"frame_build_configuration": pi_dict_array
		}
		dict_array.append(fd)
	if !DirAccess.dir_exists_absolute(DATA_PACKS_PATH + "celestial-bodies-core/"):
		DirAccess.make_dir_absolute(DATA_PACKS_PATH + "celestial-bodies-core/")
	var file = FileAccess.open(DATA_PACKS_PATH + "celestial-bodies-core/frame_builds.json", FileAccess.WRITE)
	var json_string: String = JSON.stringify(dict_array, "\t")
	if file:
		file.store_line(json_string)
		file.close()
	else:
		push_error("Couldn't make the frame builds json. Error code: ", FileAccess.get_open_error())

func create_player_grid_gradient_atlastextures() -> Array[AtlasTexture]:
	var arr: Array[AtlasTexture] = []
	var tile_size: Vector2i = Vector2i(floori(player_grid_gradient.get_size().x / 6.0), floori(player_grid_gradient.get_size().y / 6.0)) 
	for y in range(6):
		for x in range(6):
			var pos: Vector2i = Vector2i(x,y) * tile_size
			var at: AtlasTexture = AtlasTexture.new()
			at.atlas = player_grid_gradient
			at.region = Rect2(pos, tile_size)
			arr.append(at)
	return arr

func _on_http_check_completed(result: int, response_code: int, headers: PackedStringArray, _body: PackedByteArray) -> void:
	print("Got response code " + str(response_code))
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Could not reach manifest URL. (resource_manager) ", result)
		return
	
	var current_etag: String = ""
	var current_modified: String = ""
	
	for header in headers:
		if header.to_lower().begins_with("etag:"):
			current_etag = header.split(":", false, 1)[1].strip_edges()
			print("ETag found: " + current_etag)
			break
		elif header.begins_with("Last-Modified:"):
			current_modified = header.trim_prefix("Last-Modified: ").strip_edges()
	#if current_modified != currently_checked_modified:
	if response_code != 404:
		if currently_checked_etag != current_etag:
			print("File has changed. Adding to download queue.")
			packages_to_download[current_package_id] = current_package_url
		else:
			print("File has not changed. Continuing.")
			check_complete.emit()
			return
		currently_checked_modified = current_modified
		currently_checked_etag = current_etag
	else:
		push_error("Manifest URL returned 404.")
	check_complete.emit()

func _on_request_completed(result, _response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Data Pack could not be downloaded. (resource_manager)")
		return
	
	#if OS.has_feature("web"):
	var tmp_file = FileAccess.open(TEMP_FOLDER + "tmp" + str(current_tmp_file) + ".zip", FileAccess.WRITE)
	if tmp_file:
		tmp_file.store_buffer(body)
		tmp_file.close()
	
	print("Preparing to unzip tmp file " + str(current_tmp_file) + "...")
	var reader: ZIPReader = ZIPReader.new()
	#var zip_file = body
	if reader.open(TEMP_FOLDER + "tmp" + str(current_tmp_file) + ".zip") == OK:
		var dest_dir = DirAccess.open(DATA_PACKS_PATH)
		for file_path in reader.get_files():
			if file_path.ends_with("/"):
				dest_dir.make_dir_recursive(file_path)
				continue
			var data = reader.read_file(file_path)
			var file = FileAccess.open(DATA_PACKS_PATH + file_path, FileAccess.WRITE)
			file.store_buffer(data)
		reader.close()
		print("File unzipped successfully.")
		DirAccess.remove_absolute(TEMP_FOLDER + "tmp" + str(current_tmp_file) + ".zip")
		print("Temporary file deleted.")
	current_tmp_file += 1
	download_complete.emit()
	
func _await_response_with_timeout(target_signal: Signal, timeout_seconds: float) -> bool:
	var wrapper = RefCounted.new()
	wrapper.add_user_signal("finished", [{"name": "was_successful", "type": TYPE_BOOL}])
	
	var on_signal_fired = func():
		wrapper.emit_signal("finished", true)
	var on_timeout = func():
		wrapper.emit_signal("finished", false)
	
	target_signal.connect(on_signal_fired, CONNECT_ONE_SHOT)
	get_tree().create_timer(timeout_seconds).timeout.connect(on_timeout, CONNECT_ONE_SHOT)
	
	var result_array = await Signal(wrapper, "finished")
	
	if target_signal.is_connected(on_signal_fired):
		target_signal.disconnect(on_signal_fired)
	if result_array == false:
		print("Timed out waiting for response.")
	
	return result_array
