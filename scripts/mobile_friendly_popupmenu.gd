extends PopupMenu
class_name MobileFriendlyPopupMenu

func _init() -> void:
	exclusive = false

func _input(event: InputEvent) -> void:
	if visible:
		if event is InputEventScreenTouch and event.pressed:
			print("bloop")
			if item_count == 0:
				return
				
			var total_height: float = size.y
			var estimated_item_height: float = total_height / item_count
			
			var clicked_idx: int = int(event.position.y / estimated_item_height)
			if clicked_idx >= 0 and clicked_idx < item_count:
				index_pressed.emit(clicked_idx)
				var item_id = get_item_id(clicked_idx)
				id_pressed.emit(item_id)
				hide()

#func _gui_input(event: InputEvent) -> void:
	
		
