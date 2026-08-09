class_name ActiveBuildingInteractionData
extends Resource
@export var interaction_record_id := ""
@export var building_id := ""
@export var started_at := 0.0
@export var ends_at := 0.0
@export var is_completed := false
func to_dict() -> Dictionary: return {"interaction_record_id": interaction_record_id, "building_id": building_id, "started_at": started_at, "ends_at": ends_at, "is_completed": is_completed}
