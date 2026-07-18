extends Panel
class_name DataPackToggleMenu

var data_pack_toggle_hbox_prefab: PackedScene = preload("res://scenes/data_toggle_h_box.tscn")
var button_prefab: PackedScene = preload("res://scenes/load_frame_build_button.tscn")

@export var data_packs_toggle_vbox: VBoxContainer
@export var download_pack_file_dialog: FileDialog

var data_packs_changed: bool = false

func display_data_packs() -> void:
	var children: Array[Node] = data_packs_toggle_vbox.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()
	for m in ResourceManager.manifests:
		var dthb: DataToggleHBox = data_pack_toggle_hbox_prefab.instantiate()
		var dptb: DataPackToggleButton = dthb.data_pack_toggle_button
		dptb.text = m["package_name"] + " (" + m["package_id"] + ") by " + m["author"]
		dptb.button_pressed = m["enabled"]
		dptb.pack_id = m["package_id"]
		dptb.dptm = self
		dthb.data_pack_download_button.button_up.connect(_download_package_button_pressed.bind(m["package_id"]))
		if m["package_id"] != "celestial-bodies-core":
			dthb.data_pack_delete_button.button_up.connect(delete_data_pack.bind(m["package_id"]))
		else:
			dthb.data_pack_delete_button.visible = false
		data_packs_toggle_vbox.add_child(dthb)
	var cdthb: DataToggleHBox = data_pack_toggle_hbox_prefab.instantiate()
	var cdptb: DataPackToggleButton = cdthb.data_pack_toggle_button
	cdptb.text = "Custom"
	cdptb.button_pressed = DataManager.config.custom_enabled
	cdptb.pack_id = "custom"
	cdptb.dptm = self
	cdthb.data_pack_download_button.button_up.connect(_download_package_button_pressed.bind("custom"))
	cdthb.data_pack_delete_button.visible = false
	data_packs_toggle_vbox.add_child(cdthb)
	
	var back_button: Button = button_prefab.instantiate()
	back_button.text = "Back"
	back_button.button_up.connect(close_data_packs_menu)
	data_packs_toggle_vbox.add_child(back_button)
	visible = true

func download_package(path: String, package_id: String) -> void:
	if path.contains("."):
		path = path.split(".")[0] + ".zip"
	print("Preparing to write zip at path: " + path)
	var zip_packer: ZIPPacker = ZIPPacker.new()
	var error: Error = zip_packer.open(path)
	if error != OK:
		push_error("Could not open zip archive.")
		return
	if FileAccess.file_exists(ResourceManager.DATA_PACKS_PATH + package_id + "/manifest.json"):
		print("Preparing to pack manifest.json...")
		zip_packer.start_file("manifest.json")
		var file = FileAccess.open(ResourceManager.DATA_PACKS_PATH + package_id + "/manifest.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		var data = json_string.to_utf8_buffer()
		file.close()
		zip_packer.write_file(data)
		zip_packer.close_file()
		print("manifest.json packed.")
	if FileAccess.file_exists(ResourceManager.DATA_PACKS_PATH + package_id + "/frames.json"):
		print("Preparing to pack frames.json...")
		zip_packer.start_file("frames.json")
		var file = FileAccess.open(ResourceManager.DATA_PACKS_PATH + package_id + "/frames.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		var data = json_string.to_utf8_buffer()
		file.close()
		zip_packer.write_file(data)
		zip_packer.close_file()
		print("frames.json packed.")
	if FileAccess.file_exists(ResourceManager.DATA_PACKS_PATH + package_id + "/frame_builds.json"):
		print("Preparing to pack frame_builds.json...")
		zip_packer.start_file("frame_builds.json")
		var file = FileAccess.open(ResourceManager.DATA_PACKS_PATH + package_id + "/frame_builds.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		var data = json_string.to_utf8_buffer()
		file.close()
		zip_packer.write_file(data)
		zip_packer.close_file()
		print("frame_builds.json packed.")
	if FileAccess.file_exists(ResourceManager.DATA_PACKS_PATH + package_id + "/parts.json"):
		print("Preparing to pack parts.json...")
		zip_packer.start_file("parts.json")
		var file = FileAccess.open(ResourceManager.DATA_PACKS_PATH + package_id + "/parts.json", FileAccess.READ)
		var json_string: String = file.get_as_text()
		var data = json_string.to_utf8_buffer()
		file.close()
		zip_packer.write_file(data)
		zip_packer.close_file()
		print("parts.json packed.")
	zip_packer.close()
	print("Zip file written.")
		
	#download_pack_file_dialog.visible = false

func delete_data_pack(package_id: String) -> void:
	print("Attempting to remove package " + package_id + "...")
	if DirAccess.dir_exists_absolute(ResourceManager.DATA_PACKS_PATH + package_id + "/"):
		remove_recursive(ResourceManager.DATA_PACKS_PATH + package_id + "/")
		ResourceManager.remove_manifest(package_id)
		print("Package removed.")
		ResourceManager.refresh_all_packs()
		display_data_packs()
		if DataManager.currently_edited_data_pack == package_id:
			DataManager.currently_edited_data_pack = "custom"

func remove_recursive(path: String) -> void:
	if !DirAccess.dir_exists_absolute(path):
		return
	
	for dir_name in DirAccess.get_directories_at(path):
		var sub_dir_path = path.path_join(dir_name)
		remove_recursive(sub_dir_path)
		
	for file_name in DirAccess.get_files_at(path):
		var file_path = path.path_join(file_name)
		DirAccess.remove_absolute(file_path)
	
	DirAccess.remove_absolute(path)

func close_data_packs_menu() -> void:
	if data_packs_changed:
		ResourceManager.refresh_all_packs()
	visible = false

func _download_package_button_pressed(package_id: String) -> void:
	if OS.has_feature("web") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		# Initiate a download
		print("Preparing zip for download...")
		var zip_packer: ZIPPacker = ZIPPacker.new()
		var error: Error = zip_packer.open(ResourceManager.TEMP_FOLDER + package_id + ".zip")
		if error != OK:
			push_error("Could not open zip archive.")
			return
		zip_packer.add_directory(package_id + "/")
		if FileAccess.file_exists(ResourceManager.DATA_PACKS_PATH + package_id + "/manifest.json"):
			print("Preparing to pack manifest.json...")
			zip_packer.start_file(package_id + "/manifest.json")
			var file = FileAccess.open(ResourceManager.DATA_PACKS_PATH + package_id + "/manifest.json", FileAccess.READ)
			var json_string: String = file.get_as_text()
			var data = json_string.to_utf8_buffer()
			file.close()
			zip_packer.write_file(data)
			zip_packer.close_file()
			print("manifest.json packed.")
		if FileAccess.file_exists(ResourceManager.DATA_PACKS_PATH + package_id + "/frames.json"):
			print("Preparing to pack frames.json...")
			zip_packer.start_file(package_id + "/frames.json")
			var file = FileAccess.open(ResourceManager.DATA_PACKS_PATH + package_id + "/frames.json", FileAccess.READ)
			var json_string: String = file.get_as_text()
			var data = json_string.to_utf8_buffer()
			file.close()
			zip_packer.write_file(data)
			zip_packer.close_file()
			print("frames.json packed.")
		if FileAccess.file_exists(ResourceManager.DATA_PACKS_PATH + package_id + "/frame_builds.json"):
			print("Preparing to pack frame_builds.json...")
			zip_packer.start_file(package_id + "/frame_builds.json")
			var file = FileAccess.open(ResourceManager.DATA_PACKS_PATH + package_id + "/frame_builds.json", FileAccess.READ)
			var json_string: String = file.get_as_text()
			var data = json_string.to_utf8_buffer()
			file.close()
			zip_packer.write_file(data)
			zip_packer.close_file()
			print("frame_builds.json packed.")
		if FileAccess.file_exists(ResourceManager.DATA_PACKS_PATH + package_id + "/parts.json"):
			print("Preparing to pack parts.json...")
			zip_packer.start_file(package_id + "/parts.json")
			var file = FileAccess.open(ResourceManager.DATA_PACKS_PATH + package_id + "/parts.json", FileAccess.READ)
			var json_string: String = file.get_as_text()
			var data = json_string.to_utf8_buffer()
			file.close()
			zip_packer.write_file(data)
			zip_packer.close_file()
			print("parts.json packed.")
		if DirAccess.dir_exists_absolute(ResourceManager.DATA_PACKS_PATH + package_id + "/images/"):
			zip_packer.add_directory(package_id + "/images/")
			var source_dir: String = ResourceManager.DATA_PACKS_PATH + package_id + "/images/"
			add_dir_to_zip_recursive(ResourceManager.DATA_PACKS_PATH, source_dir, zip_packer)
		zip_packer.close()
		print("Zip file written.")
		var downloadable_zip = FileAccess.open(ResourceManager.TEMP_FOLDER + package_id + ".zip", FileAccess.READ)
		var downloadable_data: PackedByteArray = downloadable_zip.get_buffer(downloadable_zip.get_length())
		downloadable_zip.close()
		
		# Prepare the Uint8Array to hold raw bytes
		var js_array = JavaScriptBridge.create_object("Uint8Array", downloadable_data.size())
		for i in range(downloadable_data.size()):
			js_array[i] = downloadable_data[i]
		
		# Make the blob with the right MIME
		var blob_properties = JavaScriptBridge.create_object("Object")
		blob_properties["type"] = "application/zip"
		var blob_parts = JavaScriptBridge.create_object("Array")
		blob_parts.push(js_array)
		var blob = JavaScriptBridge.create_object("Blob", blob_parts, blob_properties)
		
		# Hacky way to make a false click
		var window = JavaScriptBridge.get_interface("window")
		var document = JavaScriptBridge.get_interface("document")
		var url_interface = JavaScriptBridge.get_interface("URL")
		var blob_url = url_interface.createObjectURL(blob)
		var link = document.createElement("a")
		link.href = blob_url
		link.download = package_id + ".zip"
		
		# Now trigger the download and clean up memory
		document.body.appendChild(link)
		link.click()
		document.body.removeChild(link)
		url_interface.revokeObjectURL(blob_url)
		
	else:
		if download_pack_file_dialog.file_selected.get_connections().size() > 0:
			download_pack_file_dialog.file_selected.disconnect(download_package)
		download_pack_file_dialog.file_selected.connect(download_package.bind(package_id))
		download_pack_file_dialog.current_file = package_id + ".zip"
		download_pack_file_dialog.popup_file_dialog()

func add_dir_to_zip_recursive(base_dir: String, current_dir: String, packer: ZIPPacker) -> void:
	var dir = DirAccess.open(current_dir)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		var full_path: String = current_dir.path_join(file_name)
		if dir.current_is_dir():
			add_dir_to_zip_recursive(base_dir, full_path, packer)
		else:
			var relative_path: String = full_path.trim_prefix(base_dir)
			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var buffer = file.get_buffer(file.get_length())
				file.close()
				
				packer.start_file(relative_path)
				packer.write_file(buffer)
				packer.close_file()
		file_name = dir.get_next()
	dir.list_dir_end()
