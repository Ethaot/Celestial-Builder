extends Resource
class_name PartInstance

@export var part_instance_name: String
@export var part_id: String
@export var part_instance_slots: Array[int]
@export var mirrored_h: bool
@export var mirrored_v: bool
@export var times_rotated: int

func to_dict() -> Dictionary:
	var dict: Dictionary = {
		"part_instance_name": part_instance_name,
		"part_id": part_id,
		"part_instance_slots": part_instance_slots,
		"mirrored_h": mirrored_h,
		"mirrored_v": mirrored_v,
		"times_rotated": times_rotated
	}
	return dict

func from_dict(dict: Dictionary) -> void:
	part_instance_name = dict["part_instance_name"]
	part_id = dict["part_id"]
	for pis in dict["part_instance_slots"]:
		part_instance_slots.append(pis)
	mirrored_h = dict["mirrored_h"]
	mirrored_v = dict["mirrored_v"]
	times_rotated = dict["times_rotated"]
