extends Node

func generate_uuid() -> String:
	var uuid: String = ""
	for i in range(32):
		uuid += str(randi_range(0,9))
	return uuid
