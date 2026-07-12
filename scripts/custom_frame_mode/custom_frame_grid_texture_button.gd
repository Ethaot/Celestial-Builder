extends TextureButton
class_name CustomFrameGridTextureButton

@export var grid_clipping_rect: ColorRect
@export var grid_gradient_rect: TextureRect
var index: int
var selected: bool

func _ready() -> void:
	self_modulate = Color("282828")
	button_up.connect(_on_button_pressed)

func assign_grid_gradient_texture() -> void:
	grid_gradient_rect.texture = ResourceManager.player_grid_gradient_atlastextures[index]

func _on_button_pressed() -> void:
	if selected:
		selected = false
		self_modulate = Color("282828")
		grid_gradient_rect.visible = false
	else:
		selected = true
		self_modulate = Color.WHITE
		grid_gradient_rect.visible = true
