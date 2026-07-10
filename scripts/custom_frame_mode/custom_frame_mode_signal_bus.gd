extends Node
class_name CustomFrameModeSignalBus

signal armor_grid_selected(idx: int, mode: int)

func emit_armor_grid_selected(idx: int, mode: int) -> void:
	armor_grid_selected.emit(idx, mode)
