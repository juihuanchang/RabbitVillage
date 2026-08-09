class_name BuildingUseResult
extends Resource
@export var interaction_record_id := ""
@export var building_id := ""
@export var completed_at := 0.0
@export var energy_change := 0
@export var mood_change := 0
@export var intimacy_change := 0
@export var use_count := 0
func to_dict() -> Dictionary: return {"interaction_record_id": interaction_record_id, "building_id": building_id, "completed_at": completed_at, "energy_change": energy_change, "mood_change": mood_change, "intimacy_change": intimacy_change, "use_count": use_count}
