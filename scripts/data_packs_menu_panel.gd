extends Panel
class_name DataPacksMenuPanel

@export var data_pack_load_dialog: FileDialog

var _on_file_loaded_callback

func _ready() -> void:
	data_pack_load_dialog.file_selected.connect(load_data_pack_from_zip)
	if OS.has_feature("web") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		_on_file_loaded_callback = JavaScriptBridge.create_callback(_on_file_loaded)

func load_data_pack_from_zip(path: String) -> void:
	if path.contains(".zip"):
		print("Preparing to unzip data pack file...")
		var reader: ZIPReader = ZIPReader.new()
		#var zip_file = body
		if reader.open(path) == OK:
			var dest_dir = DirAccess.open(ResourceManager.DATA_PACKS_PATH)
			for file_path in reader.get_files():
				if file_path.ends_with("/"):
					dest_dir.make_dir_recursive(file_path)
					continue
				var data = reader.read_file(file_path)
				var file = FileAccess.open(ResourceManager.DATA_PACKS_PATH + file_path, FileAccess.WRITE)
				file.store_buffer(data)
				file.close()
				if file_path.contains("/manifest.json"):
					ResourceManager.add_manifest(file_path)
			reader.close()
			print("File unzipped successfully.")
			ResourceManager.refresh_all_packs()
		else:
			push_error("Couldn't open zip file.")
	else:
		push_error("Attempted to open a non-zip file.")

func trigger_web_upload() -> void:
	var js_code = """
	(function() {
		let input = document.getElementById('godot-file-uploader');
		if (!input) {
			input = document.createElement('input');
			input.id = 'godot-file-uploader';
			input.type = 'file';
			input.style.display = 'none';
			input.accept = '.zip';
			document.body.appendChild(input);
		}
		
		input.onchange = function(e) {
			let file = e.target.files[0];
			if (!file) return;
			
			let reader = new FileReader();
			reader.onload = function(evt) {
				let arrayBuffer = evt.target.result;
				let uint8Array = new Uint8Array(arrayBuffer);
				window.godot_file_handler(file.name, uint8Array);
			};
			reader.readAsArrayBuffer(file);
		};
		input.click();
	})();
	"""
	
	var window = JavaScriptBridge.get_interface("window")
	window.godot_file_handler = _on_file_loaded_callback
	JavaScriptBridge.eval(js_code)

func _on_file_loaded(args: Array) -> void:
	print("Preparing to create zip file...")
	var file_name = args[0]
	print(file_name)
	var file_data: PackedByteArray
	var length = int(args[1].length)
	file_data.resize(length)
	for i in range(length):
		file_data[i] = args[1][i]
	print("Successfully uploaded " + file_name)
	var file = FileAccess.open(ResourceManager.TEMP_FOLDER + file_name, FileAccess.WRITE)
	file.store_buffer(file_data)
	file.close()
	#var packer: ZIPPacker = ZIPPacker.new()
	#var err = packer.open(ResourceManager.TEMP_FOLDER + file_name)
	#if err != OK:
		#push_error("Couldn't parse upload into zip file.")
		#return
	#
	#packer.start_file(file_name)
	#packer.write_file(file_data)
	#packer.close_file()
	#packer.close()
	#print("Successfully created temporary ZIP file.")
	load_data_pack_from_zip(ResourceManager.TEMP_FOLDER + file_name)
	print("Preparing to delete temporary file...")
	if FileAccess.file_exists(ResourceManager.TEMP_FOLDER + file_name):
		DirAccess.remove_absolute(ResourceManager.TEMP_FOLDER + file_name)
		print("Temporary file deleted.")
	else:
		push_error("Couldn't delete temporary file.")
