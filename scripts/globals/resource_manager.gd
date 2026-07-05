extends Node

var main_theme_res: Theme = preload("res://MainTheme.tres")

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
var frame_dict: Dictionary[String, Frame]

func _ready() -> void:
	if !OS.has_feature("mobile"):
		main_theme_res.default_font_size = 32
	
	var parts_array: Array[Part] = import_parts("res://parts/", ".tres")
	part_dict = construct_parts_dict(parts_array)
	assign_parts_array(parse_parts(parts_array))
	frames = import_frames("res://frames/", ".tres")
	frame_dict = construct_frame_dict(frames)
	frame_builds = import_frame_builds("res://frame_builds/", ".tres")

func import_parts(path: String, extension: String) -> Array[Part]:
	var loaded_parts: Array[Part]
	var dir: DirAccess = DirAccess.open(path)
	if !dir:
		push_error("Failed to open parts directory (resource_manager).")
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
