extends Resource
class_name SaveData

const DEFAULT_DAMAGE_ARRAY: Array[int] = [
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0
	]

@export var save_id: String
@export var lamplighter_name: String
@export var callsign: String
@export var attributes: Array[int] = [0,0,0,0,0]
@export var attribute_bonuses: Array[int] = [0,0,0,0,0]
@export var attributes_current: Array[int] = [0,0,0,0,0]
@export var premonitions: int
@export var frame_builds: Array[FrameBuild]
@export var current_frame_build: FrameBuild = FrameBuild.new()
@export var current_damage: Array[int] = [
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0,
	0,0,0,0,0,0
	]
@export var current_hp: int
@export var current_shields: Array[int]
