extends Part
class_name Shield

@export var size: Constants.Size
@export var capacity: int
@export var capacity_modifier_positive: int
@export var capacity_modifier_negative: int

func to_dict() -> Dictionary:
	var dict: Dictionary
	dict["part_name"] = part_name
	dict["part_id"] = part_id
	dict["part_type"] = part_type
	dict["powered"] = powered
	dict["part_configuration"] = part_configuration
	dict["part_icon"] = part_icon
	dict["part_description"] = part_description
	dict["requirements"] = requirements
	dict["part_tab"] = part_tab
	dict["tags"] = tags
	dict["connected_tags"] = connected_tags
	dict["size"] = size
	dict["capacity"] = capacity
	dict["capacity_modifier_positive"] = capacity_modifier_positive
	dict["capacity_modifier_negative"] = capacity_modifier_negative
	return dict

func from_dict(dict: Dictionary) -> void:
	var regex = RegEx.new()
	regex.compile("-?\\d+")
	
	part_name = dict["part_name"]
	part_id = dict["part_id"]
	part_type = dict["part_type"]
	powered = dict["powered"]
	for slot in dict["part_configuration"]:
		if slot is Vector2i:
			part_configuration.append(slot)
		elif slot is String:
			var matches = regex.search_all(slot)
			var x: int = matches[0].get_string().to_int()
			var y: int = matches[1].get_string().to_int()
			part_configuration.append(Vector2i(x, y))
	part_icon = dict["part_icon"]
	part_description = dict["part_description"]
	requirements = dict["requirements"]
	part_tab = dict["part_tab"]
	for tag in dict["tags"]:
		tags.append(tag)
	for tag in dict["connected_tags"]:
		connected_tags.append(tag)
	if dict.has("size"):
		size = dict["size"]
	if dict.has("capacity"):
		capacity = dict["capacity"]
	if dict.has("capacity_modifier_positive"):
		capacity_modifier_positive = dict["capacity_modifier_positive"]
	if dict.has("capacity_modifier_negative"):
		capacity_modifier_negative = dict["capacity_modifier_negative"]
