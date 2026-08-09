class_name VillageEventResult
extends Resource
@export var event_id := ""
@export var unlocked_building_id := ""
@export var applied_at := 0.0
func to_dict() -> Dictionary: return {"event_id": event_id, "unlocked_building_id": unlocked_building_id, "applied_at": applied_at}
