extends Resource
class_name Part

@export var part_name: String
@export var part_id: String
@export var part_type: Constants.PartType
@export var powered: bool
@export var part_configuration: Array[Vector2i]
@export var part_icon: String
@export_multiline var part_description: String
@export var requirements: String
@export var part_tab: String
@export var tags: Array[String]
@export var connected_tags: Array[String]

func from_dict(dict: Dictionary) -> void:
	var regex = RegEx.new()
	regex.compile("-?\\d+")
	
	part_name = dict["part_name"]
	part_id = dict["part_id"]
	part_type = dict["part_type"]
	powered = dict["powered"]
	for slot in dict["part_configuration"]:
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
