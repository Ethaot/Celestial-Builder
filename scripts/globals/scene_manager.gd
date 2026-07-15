extends Node

const MAIN_SCENE: String = "res://scenes/main_scene.tscn"
const ENCOUNTER_SCENE: String = "res://scenes/encounter_mode/encounter_mode.tscn"
const CUSTOM_FRAME_SCENE: String = "res://scenes/custom_frame_builder.tscn"
const CUSTOM_FRAME_BUILDER_SCENE: String = "res://scenes/custom_frame_build_mode/custom_frame_build_builder.tscn"
const CUSTOM_PART_SCENE: String = "res://scenes/custom_part_builder/custom_part_builder.tscn"
const DATA_MANAGER_SCENE: String = "res://scenes/data_manager_menu/data_manager_menu.tscn"

func switch_scene(scene: String) -> void:
	var new_packed_scene: PackedScene = load(scene)
	get_tree().change_scene_to_packed(new_packed_scene)
	#var new_scene: Node = new_packed_scene.instantiate()
	#get_tree().root.add_child(new_scene)
	#current_scene.queue_free()
