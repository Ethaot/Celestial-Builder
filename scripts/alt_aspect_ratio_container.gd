extends AspectRatioContainer

class_name AltAspectRatioContainer

var child: Control

func _ready() -> void:
	custom_minimum_size.x = get_window().size.x

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
