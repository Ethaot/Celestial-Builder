extends AspectRatioContainer

class_name AltAspectRatioContainer

var child: Control

func _ready() -> void:
	get_window().size_changed.connect(_on_window_resized)
	_on_window_resized()

func _enter_tree() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)

func _on_child_entered_tree(new_child: Node) -> void:
	if new_child is Control:
		child = new_child
		child.resized.connect(_on_child_resized)

func _on_child_exiting_tree(leaving_child: Node) -> void:
	if leaving_child == child:
		child = null
		set_custom_minimum_size(Vector2(0,0))

func _on_child_resized() -> void:
	custom_minimum_size.y = child.size.y
	#set_custom_minimum_size(Vector2(child.size.x, child.size.y))

func _on_window_resized() -> void:
	var window_size: Vector2i = get_window().size
	var min_size: int = min(window_size.x, floori(float(window_size.y) / 2.0))
	custom_minimum_size.x = min_size
	var p: MarginContainer = get_parent()
	p.add_theme_constant_override("margin_left", floori(float(window_size.x - min_size) / 2.0))
	p.add_theme_constant_override("margin_right", floori(float(window_size.x - min_size) / 2.0))
