extends Node

const TOPLEFT: int = 1
const TOPCENTER: int = 2
const TOPRIGHT: int = 4
const CENTERLEFT: int = 8
const CENTER: int = 16
const CENTERRIGHT: int = 32
const BOTTOMLEFT: int = 64
const BOTTOMCENTER: int = 128
const BOTTOMRIGHT: int = 256
const LEFTSOLO: int = 512
const RIGHTSOLO: int = 1024
const TOPSOLO: int = 2048
const BOTTOMSOLO: int = 4196
const CENTERSOLO: int = 8192
const HORIZONTALCENTER: int = 16384
const VERTICALCENTER: int = 32768

var armor_sheet: Texture2D = preload("res://assets/ui/armor_sheet.png")
var reinforced_armor_sheet: Texture2D = preload("res://assets/ui/heavy_armor_sheet.png")
var neighbor_bits: Array[int] = [1,2,4,8] #Left, Up, Right, Down

var armor_atlases: Array[AtlasTexture]
var reinforced_armor_atlases: Array[AtlasTexture]

var armor_dict: Dictionary[int, int] = {
	1: 0,
	2: 1,
	4: 2,
	8: 4,
	16: 15,
	32: 6,
	64: 8,
	128: 9,
	256: 10,
	512: 12,
	1024: 13,
	2048: 3,
	4196: 7,
	8192: 5,
	16384: 14,
	32768: 11
}

func _ready() -> void:
	create_atlases()

func create_atlases() -> void:
	for y in range(4):
		for x in range(4):
			var start_pos: Vector2i = Vector2i(x*16, y*16)
			var size: Vector2i = Vector2i(16, 16)
			var armor_atlas: AtlasTexture = AtlasTexture.new()
			var reinforced_armor_atlas: AtlasTexture = AtlasTexture.new()
			armor_atlas.atlas = armor_sheet
			reinforced_armor_atlas.atlas = reinforced_armor_sheet
			armor_atlas.region = Rect2(start_pos, size)
			reinforced_armor_atlas.region = Rect2(start_pos, size)
			armor_atlases.append(armor_atlas)
			reinforced_armor_atlases.append(reinforced_armor_atlas)

var contiguous_offsets: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1,0), Vector2i(0,1)]

func get_tile_by_neighbors(tile_pos: Vector2i, frame: Frame, reinforced: bool) -> int:
	var neighbor_bit: int = 0
	for i in range(contiguous_offsets.size()):
		if reinforced:
			if frame.frame_reinforced_armor_slots.has(contiguous_offsets[i] + tile_pos):
				neighbor_bit += neighbor_bits[i]
		elif frame.frame_armor_slots.has(contiguous_offsets[i] + tile_pos) or frame.frame_reinforced_armor_slots.has(contiguous_offsets[i] + tile_pos):
			neighbor_bit += neighbor_bits[i]
	match neighbor_bit:
		0: return armor_dict[CENTERSOLO]
		1: return armor_dict[RIGHTSOLO]
		2: return armor_dict[BOTTOMSOLO]
		3: return armor_dict[BOTTOMRIGHT]
		4: return armor_dict[LEFTSOLO]
		5: return armor_dict[HORIZONTALCENTER]
		6: return armor_dict[BOTTOMLEFT]
		7: return armor_dict[BOTTOMCENTER]
		8: return armor_dict[TOPSOLO]
		9: return armor_dict[TOPRIGHT]
		10: return armor_dict[VERTICALCENTER]
		11: return armor_dict[CENTERRIGHT]
		12: return armor_dict[TOPLEFT]
		13: return armor_dict[TOPCENTER]
		14: return armor_dict[CENTERLEFT]
		15: return armor_dict[CENTER]
	return CENTER
