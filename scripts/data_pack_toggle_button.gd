extends CheckButton
class_name DataPackToggleButton

var dptm: DataPackToggleMenu

var pack_id: String

func _ready() -> void:
	toggled.connect(_on_button_toggled)

func _on_button_toggled(toggled_on: bool) -> void:
	for m in ResourceManager.manifests:
		if m["package_id"] == pack_id:
			m["enabled"] = toggled_on
			ResourceManager.update_manifest()
			dptm.data_packs_changed = true
			break
