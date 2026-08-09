class_name BuildingResult
extends Resource
@export var ok := false
@export var reason := ""
@export var building_id := ""
@export var slot_id := ""
func to_dict() -> Dictionary: return {"ok": ok, "reason": reason, "building_id": building_id, "slot_id": slot_id}
