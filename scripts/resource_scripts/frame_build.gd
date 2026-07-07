extends Resource
class_name FrameBuild

@export var frame_build_name: String
@export var frame_id: String
@export var frame_build_configuration: Array[PartInstance]

func to_dict() -> Dictionary:
	var dict: Dictionary = {}
	dict["frame_build_name"] = frame_build_name
	dict["frame_id"] = frame_id
	var pi_array: Array[Dictionary]
	for pi in frame_build_configuration:
		pi_array.append(pi.to_dict())
	dict["frame_build_configuration"] = pi_array
	return dict

func from_dict(dict: Dictionary) -> void:
	frame_build_name = dict["frame_build_name"]
	frame_id = dict["frame_id"]
	for pid in dict["frame_build_configuration"]:
		var pi: PartInstance = PartInstance.new()
		pi.from_dict(pid)
		frame_build_configuration.append(pi)
