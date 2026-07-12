extends Resource
class_name Frame

@export var frame_name: String
@export var frame_id: String
@export var frame_available_slots: Array[Vector2i]
@export var frame_feature_name: String
@export_multiline var frame_feature_text: String
@export var frame_feature_is_elite: bool = true
@export var frame_hp: int
@export var frame_armor_slots: Array[Vector2i]
@export var frame_reinforced_armor_slots: Array[Vector2i]
@export var frame_size: Constants.Size
@export var frame_secondary_size: Constants.Size
@export var titan: bool
@export var unusual: bool

func to_dict() -> Dictionary:
	var dict: Dictionary = {
		"frame_name": frame_name,
		"frame_id": frame_id,
		"frame_available_slots": frame_available_slots,
		"frame_feature_name": frame_feature_name,
		"frame_feature_text": frame_feature_text,
		"frame_feature_is_elite": frame_feature_is_elite,
		"frame_hp": frame_hp,
		"frame_armor_slots": frame_armor_slots,
		"frame_reinforced_armor_slots": frame_reinforced_armor_slots,
		"frame_size": frame_size,
		"frame_secondary_size": frame_secondary_size,
		"titan": titan,
		"unusual": unusual
	}
	return dict

func from_dict(dict: Dictionary) -> void:
	var regex = RegEx.new()
	regex.compile("-?\\d+")
	frame_name = dict["frame_name"]
	frame_id = dict["frame_id"]
	frame_available_slots.clear()
	for slot in dict["frame_available_slots"]:
		var matches = regex.search_all(slot)
		var x: int = matches[0].get_string().to_int()
		var y: int = matches[1].get_string().to_int()
		frame_available_slots.append(Vector2i(x,y))
	frame_feature_name = dict["frame_feature_name"]
	frame_feature_text = dict["frame_feature_text"]
	if dict.has("frame_feature_is_elite"):
		frame_feature_is_elite = dict["frame_feature_is_elite"]
	frame_hp = dict["frame_hp"]
	frame_armor_slots.clear()
	for slot in dict["frame_armor_slots"]:
		var matches = regex.search_all(slot)
		var x: int = matches[0].get_string().to_int()
		var y: int = matches[1].get_string().to_int()
		frame_armor_slots.append(Vector2i(x,y))
	frame_reinforced_armor_slots.clear()
	for slot in dict["frame_reinforced_armor_slots"]:
		var matches = regex.search_all(slot)
		var x: int = matches[0].get_string().to_int()
		var y: int = matches[1].get_string().to_int()
		frame_reinforced_armor_slots.append(Vector2i(x,y))
	frame_size = dict["frame_size"]
	if dict.has("frame_secondary_size"):
		frame_secondary_size = dict["frame_secondary_size"]
	else:
		frame_secondary_size = frame_size
	titan = dict["titan"]
	unusual = dict["unusual"]
