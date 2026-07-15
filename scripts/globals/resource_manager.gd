extends Node

const DATA_PACKS_PATH: String = "user://data_packs/"
const CUSTOM_PACK_PATH: String = DATA_PACKS_PATH + "custom/"
const TEMP_FOLDER: String = "user://tmp/"

signal check_complete
signal download_complete
signal all_downloads_complete
signal prepared_signal
signal packs_imported
signal refreshing

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
var packs_ready: bool = false

func _ready() -> void:
	http_request = HTTPRequest.new()
	http_checker = HTTPRequest.new()
	add_child(http_request)
	add_child(http_checker)
	
	http_request.request_completed.connect(_on_request_completed)
	http_checker.request_completed.connect(_on_http_check_completed)
	
	if !OS.has_feature("mobile") and !OS.has_feature("web_android") and !OS.has_feature("web_ios"):
		main_theme_res.default_font_size = 32
	
	refresh_all_packs()
	if !packs_ready:
		await packs_imported
	
	player_grid_gradient_atlastextures = create_player_grid_gradient_atlastextures()
	
	prepared = true
	prepared_signal.emit()

func refresh_all_packs() -> void:
	refreshing.emit()
	packs_ready = false
	downloads_complete = false
	
	weapons_ranged.clear()
	weapons_explosive.clear()
	weapons_melee.clear()
	weapons_ew.clear()
	weapons_missiles.clear()
	parts_reactors.clear()
	parts_thrusters.clear()
	parts_processors.clear()
	parts_shields.clear()
	frames.clear()
	frame_builds.clear()
	part_dict.clear()
	part_image_dict.clear()
	frame_dict.clear()
	
	check_create_directories()
	manifests = get_data_pack_manifest()
	get_data_packs()
	#_await_response_with_timeout(all_downloads_complete, 30.0)
	if !downloads_complete:
		await all_downloads_complete
	
	update_manifest()
	#var parts_array: Array[Part] = import_parts("res://parts/", ".tres")
	
	for manifest in manifests:
		if manifest["enabled"]:
			var parts_array: Array[Part] = import_parts_dicts(DATA_PACKS_PATH + manifest["package_id"] + "/")
			part_dict.merge(construct_parts_dict(parts_array))
			assign_parts_array(parse_parts(parts_array))
			
			var frames_array: Array[Frame] = import_frames_dicts(DATA_PACKS_PATH + manifest["package_id"] + "/")
			frames.append_array(frames_array)
			
			var frame_builds_array: Array[FrameBuild] = import_frame_build_dicts(DATA_PACKS_PATH + manifest["package_id"] + "/")
			frame_builds.append_array(frame_builds_array)
		
	# Custom folder
	var custom_parts_array: Array[Part] = import_parts_dicts(CUSTOM_PACK_PATH)
	part_dict.merge(construct_parts_dict(custom_parts_array))
	assign_parts_array(parse_parts(custom_parts_array))
	
	frames.append_array(import_frames_dicts(CUSTOM_PACK_PATH))
	frame_builds.append_array(import_frame_build_dicts(CUSTOM_PACK_PATH))
	
	# Final Dict Construction
	part_image_dict.merge(get_part_images_dict())
	frame_dict.merge(construct_frame_dict(frames))
	
	packs_ready = true
	packs_imported.emit()

func check_create_directories() -> void:
	if !DirAccess.dir_exists_absolute(DATA_PACKS_PATH):
		DirAccess.make_dir_absolute(DATA_PACKS_PATH)
	if !DirAccess.dir_exists_absolute(CUSTOM_PACK_PATH):
		DirAccess.make_dir_absolute(CUSTOM_PACK_PATH)
	if !DirAccess.dir_exists_absolute(TEMP_FOLDER):
		DirAccess.make_dir_absolute(TEMP_FOLDER)

func add_data_pack(pack_dict: Dictionary) -> void:
	if pack_dict["package_id"] != "celestial-bodies-core":
		print("Creating new Data Pack...")
		if !DirAccess.dir_exists_absolute(DATA_PACKS_PATH + pack_dict["package_id"] + "/"):
			DirAccess.make_dir_absolute(DATA_PACKS_PATH + pack_dict["package_id"] + "/")
		var json_string = JSON.stringify(pack_dict, "\t")
		var file = FileAccess.open(DATA_PACKS_PATH + pack_dict["package_id"] + "/manifest.json", FileAccess.WRITE)
		file.store_line(json_string)
		file.close()
		if FileAccess.file_exists(DATA_PACKS_PATH + "data_packs_manifest.json"):
			var mani_file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.READ)
			var mani_json_string: String = mani_file.get_as_text()
			mani_file.close()
			var data = JSON.parse_string(mani_json_string)
			var manis: Array[Dictionary]
			if data is Array:
				for d in data:
					if d is Dictionary:
						manis.append(d)
			var new_mani = pack_dict.duplicate()
			new_mani["etag"] = "Etag: Null"
			new_mani["enabled"] = true
			manis.append(new_mani)
			var write_string = JSON.stringify(manis, "\t")
			mani_file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.WRITE)
			mani_file.store_line(write_string)
			mani_file.close()
		DataManager.config.last_modified_data_pack_id = pack_dict["package_id"]
		refresh_all_packs()

func add_manifest(local_path: String) -> void:
	var full_path: String = DATA_PACKS_PATH + local_path
	var file = FileAccess.open(full_path, FileAccess.READ)
	var json_string: String = file.get_as_text()
	var data = JSON.parse_string(json_string)
	file.close()
	if FileAccess.file_exists(DATA_PACKS_PATH + "data_packs_manifest.json"):
		var mani_file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.READ)
		var mani_json_string: String = mani_file.get_as_text()
		var mani_data = JSON.parse_string(mani_json_string)
		var manis: Array[Dictionary]
		if mani_data is Array:
			for d in mani_data:
				if d is Dictionary:
					manis.append(d)
		mani_file.close()
		if data is Dictionary:
			mani_file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.WRITE)
			var new_mani: Dictionary = data.duplicate()
			new_mani["etag"] = "ETag: Null"
			new_mani["enabled"] = true
			manis.append(new_mani)
			var mani_string: String = JSON.stringify(manis, "\t")
			mani_file.store_line(mani_string)
			mani_file.close()
		# Don't refresh the packs here because the manifest may be added before the rest of the data. Let the method calling this refresh the packs.
		#refresh_all_packs()

func remove_manifest(package_id: String) -> void:
	if FileAccess.file_exists(DATA_PACKS_PATH + "data_packs_manifest.json"):
		var write_data: Array[Dictionary]
		var file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.READ)
		var read_string: String = file.get_as_text()
		var read_data = JSON.parse_string(read_string)
		if read_data is Array:
			print("READ DATA IS ARRAY")
			for d in read_data:
				if d is Dictionary:
					print("VALUE IS DICTIONARY")
					if d["package_id"] != package_id:
						write_data.append(d)
						print("WRITE DATA APPENDED TO")
		var write_string: String = JSON.stringify(write_data, "\t")
		file.close()
		file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.WRITE)
		file.store_line(write_string)
		file.close()

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
								if d["package_url"] != "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core-v0-0-4.zip":
									d["package_url"] = "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core-v0-0-4.zip"
								if !d.has("enabled"):
									d["enabled"] = true
							data_pack_manifest_data.append(d)
				else:
					var core_data: Dictionary = {
						"package_name": "Celestial Bodies Core",
						"package_id": "celestial-bodies-core",
						#"package_url": "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core.zip",
						"package_url": "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core-v0-0-4.zip",
						"author": "Binary Star & Charlotte Laskowski",
						"source_name": "Celestial Bodies Technical Handbook",
						"source_url": "https://selkie.itch.io/celestial-bodies",
						"version": "0.0.1",
						"etag": "ETag: Null",
						"enabled": true
					}
					data_pack_manifest_data.append(core_data)
			file.close()
		else:
			print("Manifest file not found. Creating new Core Data.")
			var core_data: Dictionary = {
				"package_name": "Celestial Bodies Core",
				"package_id": "celestial-bodies-core",
				#"package_url": "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core.zip",
				"package_url": "https://ethaot.github.io/celestial-builder-data-packs/celestial-bodies-core-v0-0-4.zip",
				"author": "Binary Star & Charlotte Laskowski",
				"source_name": "Celestial Bodies Technical Handbook",
				"source_url": "https://selkie.itch.io/celestial-bodies",
				"version": "0.0.1",
				"etag": "ETag: Null",
				"enabled": true
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
		if current_package_url.length() > 0:
			var err: Error = http_checker.request(current_package_url + "?timestamp=" + str(Time.get_unix_time_from_system()), [], HTTPClient.METHOD_HEAD)
			if err == OK:
				await _await_response_with_timeout(check_complete, 5.0)
				manifests[i]["etag"] = currently_checked_etag
				#await check_complete
			else:
				push_error("Error checking package url for updates. Error code: ", err)
		else:
			print("Data package is local. Continuing.")
	
	for package_id in packages_to_download:
		print("Downloading package " + package_id)
		var err: Error = http_request.request_raw(packages_to_download[package_id] + "?timestamp=" + str(Time.get_unix_time_from_system()))
		if err == OK:
			await _await_response_with_timeout(download_complete, 15.0)
			#await download_complete
		else:
			push_error("Error downloading data pack. Error code: ", err)
	
	print("Package downloads complete.")
	all_downloads_complete.emit()
	downloads_complete = true

func update_manifest() -> void:
	print("Updating manifests...")
	var new_manifest_data: Array[Dictionary]
	for m in manifests:
		if FileAccess.file_exists(DATA_PACKS_PATH + m["package_id"] + "/manifest.json"):
			var m_file = FileAccess.open(DATA_PACKS_PATH + m["package_id"] + "/manifest.json", FileAccess.READ)
			var m_string: String = m_file.get_as_text()
			var m_data = JSON.parse_string(m_string)
			if m_data is Dictionary:
				var clean_dict: Dictionary = {
					"package_name": m_data["package_name"],
					"package_id": m_data["package_id"],
					"package_url": m_data["package_url"],
					"author": m_data["author"],
					"version": m_data["version"],
					#"dependencies": m_data["dependencies"],
					"etag": m["etag"],
					"enabled": m["enabled"]
				}
				new_manifest_data.append(clean_dict)
				print(str(new_manifest_data.size()))
			m_file.close()
	var new_manifest_string: String = JSON.stringify(new_manifest_data, "\t")
	var file = FileAccess.open(DATA_PACKS_PATH + "data_packs_manifest.json", FileAccess.WRITE)
	#var json_data: String = JSON.stringify(manifests, "\t")
	file.store_line(new_manifest_string)
	file.close()
	print("Manifests updated.")
			

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
					part.from_dict(d)
					if part.part_type == Constants.PartType.PartReactor:
						part.size = d["size"]
					if part.part_type == Constants.PartType.PartShield:
						part.capacity = d["capacity"]
						part.capacity_modifier_positive = d["capacity_modifier_positive"]
						part.capacity_modifier_negative = d["capacity_modifier_negative"]
					loaded_parts.append(part)
	print("Parts imported.")
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
		if FileAccess.file_exists(DATA_PACKS_PATH + part_dict[key].part_icon):
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
					var f: Frame = Frame.new()
					f.from_dict(d)
					loaded_frames.append(f)
	print("Frames imported.")
	return loaded_frames

func construct_frame_dict(fr: Array[Frame]) -> Dictionary[String, Frame]:
	var dict: Dictionary[String, Frame] = {}
	for f in fr:
		dict[f.frame_id] = f
	return dict

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
					var fb: FrameBuild = FrameBuild.new()
					fb.from_dict(d)
					loaded_frame_builds.append(fb)
	print("Frame builds imported.")
	return loaded_frame_builds

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

func save_part_to_parts_json(data_pack_id: String, part: Part) -> void:
	if FileAccess.file_exists(DATA_PACKS_PATH + data_pack_id + "/parts.json"):
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/parts.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		file.close()
		var data = JSON.parse_string(json_string)
		var data_had_part: bool = false
		if data is Array:
			for dict in data:
				if dict is Dictionary:
					if dict["part_id"] == part.part_id:
						dict.assign(part.to_dict())
						data_had_part = true
			if !data_had_part:
				data.append(part.to_dict())
		file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/parts.json", FileAccess.WRITE)
		json_string = JSON.stringify(data, "\t")
		file.store_line(json_string)
		file.close()
	else:
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/parts.json", FileAccess.WRITE)
		var data: Array = [part.to_dict()]
		var json_string: String = JSON.stringify(data, "\t")
		file.store_line(json_string)
		file.close()

func remove_part_from_parts_json(data_pack_id: String, part_id: String) -> void:
	print("Deleting part " + part_id + "...")
	if FileAccess.file_exists(DATA_PACKS_PATH + data_pack_id + "/parts.json"):
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/parts.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		file.close()
		var data = JSON.parse_string(json_string)
		var new_data: Array[Dictionary]
		if data is Array:
			for dict in data:
				if dict is Dictionary:
					if dict["part_id"] != part_id:
						new_data.append(dict)
		json_string = JSON.stringify(new_data, "\t")
		file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/parts.json", FileAccess.WRITE)
		file.store_line(json_string)
		file.close()
		print("Part deleted.")
	else:
		push_error("Parts JSON does not exist for data pack " + data_pack_id + ".")

func save_frame_to_frames_json(data_pack_id: String, frame: Frame) -> void:
	if FileAccess.file_exists(DATA_PACKS_PATH + data_pack_id + "/frames.json"):
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/frames.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		file.close()
		var data = JSON.parse_string(json_string)
		var data_had_frame: bool = false
		if data is Array:
			for dict in data:
				if dict is Dictionary:
					if dict["frame_id"] == frame.frame_id:
						dict.assign(frame.to_dict())
						data_had_frame = true
			if !data_had_frame:
				data.append(frame.to_dict())
		json_string = JSON.stringify(data, "\t")
		file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/frames.json", FileAccess.WRITE)
		file.store_line(json_string)
		file.close()
	else:
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/frames.json", FileAccess.WRITE)
		var data: Array = [frame.to_dict()]
		var json_string: String = JSON.stringify(data, "\t")
		file.store_line(json_string)
		file.close()

func save_frame_build_to_frame_builds_json(data_pack_id: String, fb: FrameBuild) -> void:
	if FileAccess.file_exists(DATA_PACKS_PATH + data_pack_id + "/frame_builds.json"):
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/frame_builds.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		file.close()
		var data = JSON.parse_string(json_string)
		var data_had_frame_build: bool = false
		if data is Array:
			for dict in data:
				if dict is Dictionary:
					if dict["frame_build_id"] == fb.frame_build_id:
						dict.assign(fb.to_dict())
						data_had_frame_build = true
			if !data_had_frame_build:
				data.append(fb.to_dict())
		json_string = JSON.stringify(data, "\t")
		file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/frame_builds.json", FileAccess.WRITE)
		file.store_line(json_string)
		file.close()
	else:
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/frame_builds.json", FileAccess.WRITE)
		var data: Array = [fb.to_dict()]
		var json_string: String = JSON.stringify(data, "\t")
		file.store_line(json_string)
		file.close()

func get_parts_from_pack(data_pack_id: String) -> Array[Part]:
	var arr: Array[Part]
	if FileAccess.file_exists(DATA_PACKS_PATH + data_pack_id + "/parts.json"):
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/parts.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		var data = JSON.parse_string(json_string)
		if data is Array:
			for dict in data:
				if dict is Dictionary:
					var p: Part
					match int(dict["part_type"]):
						Constants.PartType.PartReactor:
							p = Reactor.new()
						Constants.PartType.PartShield:
							p = Shield.new()
						_:
							p = Part.new()
					p.from_dict(dict)
					arr.append(p)
	return arr

func get_frames_from_pack(data_pack_id: String) -> Array[Frame]:
	var arr: Array[Frame]
	if FileAccess.file_exists(DATA_PACKS_PATH + data_pack_id + "/frames.json"):
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/frames.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		var data = JSON.parse_string(json_string)
		if data is Array:
			for dict in data:
				if dict is Dictionary:
					var f: Frame = Frame.new()
					f.from_dict(dict)
					arr.append(f)
	return arr

func get_frame_builds_from_pack(data_pack_id: String) -> Array[FrameBuild]:
	var arr: Array[FrameBuild]
	if FileAccess.file_exists(DATA_PACKS_PATH + data_pack_id + "/frame_builds.json"):
		var file = FileAccess.open(DATA_PACKS_PATH + data_pack_id + "/frame_builds.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		var data = JSON.parse_string(json_string)
		if data is Array:
			for dict in data:
				if dict is Dictionary:
					var fb: FrameBuild = FrameBuild.new()
					fb.from_dict(dict)
					arr.append(fb)
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
		elif current_etag == "":
			print("No etag passed from the repository.")
			packages_to_download[current_package_id] = current_package_url
			check_complete.emit()
			return
		else:
			print("File has not changed. Continuing.")
			check_complete.emit()
			return
		currently_checked_modified = current_modified
		currently_checked_etag = current_etag
	else:
		push_error("Manifest URL returned 404.")
	check_complete.emit()

func _on_request_completed(result, _response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Data Pack could not be downloaded. (resource_manager)")
		return
	
	var current_etag: String = ""
	for header in headers:
		if header.to_lower().begins_with("etag:"):
			current_etag = header.split(":", false, 1)[1].strip_edges()
			print("ETag found: " + current_etag)
			currently_checked_etag = current_etag
			break
	
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
			file.close()
		reader.close()
		print("File unzipped successfully.")
		DirAccess.remove_absolute(TEMP_FOLDER + "tmp" + str(current_tmp_file) + ".zip")
		print("Temporary file deleted.")
	else:
		push_error("Couldn't unzip tmp file.")
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
