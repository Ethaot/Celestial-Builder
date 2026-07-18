extends Node
class_name EncounterSignalBus

signal redraw_grid
signal frame_build_changed(new_frame_build: FrameBuild)
signal combatant_added
signal combatant_updated
signal combatant_deleted()
signal combatant_switched(index: int)
signal encounter_cleared
signal encounter_loaded

@export var encounter_data_manager: EncounterDataManager

func request_redraw_grid() -> void:
	redraw_grid.emit()

func change_frame_build(frame_build: FrameBuild) -> void:
	var f: Frame = ResourceManager.frame_dict[frame_build.frame_id]
	encounter_data_manager.current_combatant.current_frame_build = frame_build
	encounter_data_manager.current_combatant.lamplighter_name = frame_build.frame_build_name
	encounter_data_manager.current_combatant.current_hp = f.frame_hp
	encounter_data_manager.current_combatant.current_damage = Character.DEFAULT_DAMAGE_ARRAY.duplicate()
	frame_build_changed.emit(frame_build)
	combatant_updated.emit()

func add_new_combatant(combatant: Character) -> void:
	encounter_data_manager.add_combatant(combatant)
	combatant_added.emit()

func delete_combatant(index: int) -> void:
	encounter_data_manager.delete_combatant(index)
	combatant_deleted.emit()

func switch_combatant(index: int) -> void:
	encounter_data_manager.switch_combatant(index)
	combatant_switched.emit()

func clear_encounter() -> void:
	encounter_data_manager.clear_encounter()
	encounter_cleared.emit()

func load_encounter_finished() -> void:
	encounter_loaded.emit()
