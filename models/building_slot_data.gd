class_name BuildingSlotData
extends Resource

@export var slot_id := ""
@export var building_id := ""
@export var state := "empty"

func to_dict() -> Dictionary: return {"slot_id": slot_id, "building_id": building_id, "state": state}
