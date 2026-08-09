class_name BuildingUseResult
extends Resource

@export var building_use_record_id := ""
@export var interaction_record_id := ""
@export var building_id := ""
@export var started_at := 0.0
@export var completed_at := 0.0
@export var energy_change := 0
@export var mood_change := 0
@export var intimacy_change := 0
@export var use_count := 0
@export var is_first_use := false

func to_dict() -> Dictionary:
    return {
        "building_use_record_id": building_use_record_id,
        "interaction_record_id": interaction_record_id,
        "building_id": building_id,
        "started_at": started_at,
        "completed_at": completed_at,
        "energy_change": energy_change,
        "mood_change": mood_change,
        "intimacy_change": intimacy_change,
        "use_count": use_count,
        "is_first_use": is_first_use
    }
