extends PanelContainer
class_name CustomFileSelector

signal path_chosen(path: String)

var directory_hbox_prefab: PackedScene = preload("res://scenes/custom_file_selector/directory_h_box.tscn")
var file_hbox_prefab: PackedScene = preload("res://scenes/custom_file_selector/file_h_box.tscn")

@export var directory_vbox: VBoxContainer
@export var root_directory: String
@export var valid_file_extensions: Array[String]
@export var close_button: Button

func _ready() -> void:
	close_button.button_up.connect(func() -> void: visible = false)

func popup() -> void:
	for child in directory_vbox.get_children():
		if child != close_button:
			child.queue_free()
	var data: Array[Array]
	if root_directory.length() > 0:
		if DirAccess.dir_exists_absolute(root_directory):
			data = get_directories_at_path(root_directory)
		else:
			data = get_directories_at_path(ResourceManager.DATA_PACKS_PATH)
	else:
		data = get_directories_at_path(ResourceManager.DATA_PACKS_PATH)
	make_buttons(ResourceManager.DATA_PACKS_PATH, data, directory_vbox)
	directory_vbox.move_child(close_button, directory_vbox.get_children().size()-1)
	visible = true

func get_directories_at_path(path: String) -> Array[Array]:
	var directories: Array[String]
	var files: Array[String]
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				directories.append(file_name)
			else:
				for fe in valid_file_extensions:
					if file_name.get_extension() == fe:
						files.append(file_name)
						break
			file_name = dir.get_next()
	return [directories, files]

func make_buttons(current_path: String, data: Array[Array], parent_node: Node) -> void:
	for dir in data[0]:
		var dhb: DirectoryHBox = directory_hbox_prefab.instantiate()
		dhb.directory_button.text = dir
		dhb.directory_button.button_up.connect(func() -> void:
			var children: Array[Node] = dhb.sub_directory_vbox.get_children()
			if children.size() <= 1:
				make_buttons(current_path + dir + "/", get_directories_at_path(current_path + dir + "/"), dhb.sub_directory_vbox)
			else:
				for i in range(1, children.size()):
					children[i].visible = false if children[i].visible else true
			)
		parent_node.add_child(dhb)
		
	for file: String in data[1]:
		var fhb: FileHBox = file_hbox_prefab.instantiate()
		fhb.file_button.text = file
		var extension = file.get_extension()
		if extension == "png" or extension == "jpg" or extension == "jpeg":
			var img: Image = Image.load_from_file(current_path + file)
			if is_instance_valid(img):
				var itex: ImageTexture = ImageTexture.create_from_image(img)
				fhb.file_image.texture = itex
				fhb.file_image.visible = true
			else:
				push_error("Image does not exist at path " + current_path + file)
		fhb.file_button.button_up.connect(choose_path.bind(current_path + file))
		fhb.file_delete_button.button_up.connect(func() -> void:
			delete_file(current_path + file)
			fhb.queue_free()
			)
		parent_node.add_child(fhb)
	
func choose_path(path: String) -> void:
	path_chosen.emit(path)
	print(path)
	visible = false

func delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
