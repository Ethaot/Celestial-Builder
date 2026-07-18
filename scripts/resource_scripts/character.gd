extends Resource
class_name Character

const DEFAULT_DAMAGE_ARRAY: Array[int] = [
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0
	]

@export var lamplighter_name: String
@export var lamplighter_id: String
@export var callsign: String
@export var attributes: Array[int] = [0,0,0,0,0]
@export var attribute_bonuses: Array[int] = [0,0,0,0,0]
@export var attributes_current: Array[int] = [0,0,0,0,0]
@export var premonitions: int
@export var current_frame_build: FrameBuild = FrameBuild.new()
@export var current_damage: Array[int] = [
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0
	]
@export var current_hp: int
@export var current_shields: Array[int]

func to_dict() -> Dictionary:
	var dict: Dictionary
	dict["lamplighter_name"] = lamplighter_name
	dict["lamplighter_id"] = lamplighter_id
	dict["callsign"] = callsign
	dict["attributes"] = attributes
	dict["attribute_bonuses"] = attribute_bonuses
	dict["attributes_current"] = attributes_current
	dict["premonitions"] = premonitions
	dict["current_frame_build"] = current_frame_build.to_dict()
	dict["current_damage"] = current_damage
	dict["current_hp"] = current_hp
	dict["current_shields"] = current_shields
	return dict

func from_dict(dict: Dictionary) -> void:
	lamplighter_name = dict["lamplighter_name"]
	if dict.has("lamplighter_id"):
		lamplighter_id = dict["lamplighter_id"]
	callsign = dict["callsign"]
	attributes.clear()
	for attr in dict["attributes"]:
		attributes.append(attr)
	attribute_bonuses.clear()
	for attr in dict["attribute_bonuses"]:
		attribute_bonuses.append(attr)
	attributes_current.clear()
	for attr in dict["attributes_current"]:
		attributes_current.append(attr)
	premonitions = dict["premonitions"]
	var cfb: FrameBuild = FrameBuild.new()
	cfb.from_dict(dict["current_frame_build"])
	current_frame_build = cfb
	current_damage.clear()
	for dmg in dict["current_damage"]:
		current_damage.append(dmg)
	current_hp = dict["current_hp"]
	for shield in dict["current_shields"]:
		current_shields.append(shield)
