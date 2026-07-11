extends Resource
class_name FrameBuild

@export var frame_build_name: String
@export var frame_id: String
@export var frame_build_configuration: Array[PartInstance]
@export var player_build: bool

func to_dict() -> Dictionary:
	var dict: Dictionary = {}
	dict["frame_build_name"] = frame_build_name
	dict["frame_id"] = frame_id
	var pi_array: Array[Dictionary]
	for pi in frame_build_configuration:
		pi_array.append(pi.to_dict())
	dict["frame_build_configuration"] = pi_array
	dict["player_build"] = player_build
	return dict

func from_dict(dict: Dictionary) -> void:
	if dict.has("frame_build_name"):
		frame_build_name = dict["frame_build_name"]
	else:
		frame_build_name = "New Frame Build"
	if dict.has("frame_id"):
		frame_id = dict["frame_id"]
	else:
		if ResourceManager.frames.size() > 0:
			frame_id = ResourceManager.frames[0].frame_id
		else:
			push_error("Resource Manager has no frames and frame build has no id, cannot import frame build")
			return
	for pid in dict["frame_build_configuration"]:
		if pid is Dictionary:
			var pi: PartInstance = PartInstance.new()
			pi.from_dict(pid)
			frame_build_configuration.append(pi)
		else:
			push_error("Cannot parse PartInstance in frame build configuration.")
			return
	if dict.has("player_build"):
		player_build = dict["player_build"]
