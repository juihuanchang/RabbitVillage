class_name BuildingUnlockData
extends Resource
@export var building_id := ""
@export var unlocked_at := 0.0
func to_dict() -> Dictionary: return {"building_id": building_id, "unlocked_at": unlocked_at}
