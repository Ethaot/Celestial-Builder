extends Resource
class_name SaveData

const DEFAULT_DAMAGE_ARRAY: Array[int] = [
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0
	]

@export var save_id: String
@export var frame_builds: Array[FrameBuild]
@export var character: Character = Character.new()

func to_dict() -> Dictionary:
	var fba: Array[Dictionary]
	for fb in frame_builds:
		fba.append(fb.to_dict())
	var dict: Dictionary = {
		"save_id": save_id,
		"frame_builds": fba,
		"character": character.to_dict()
	}
	return dict
	
func from_dict(dict: Dictionary) -> void:
	save_id = dict["save_id"]
	for fbd in dict["frame_builds"]:
		var fb: FrameBuild = FrameBuild.new()
		fb.from_dict(fbd)
		frame_builds.append(fb)
	character = Character.new()
	character.from_dict(dict["character"])
