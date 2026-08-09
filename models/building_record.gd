class_name BuildingRecord
extends Resource

@export var building_id := ""
@export var slot_id := ""
@export var state := "placed"
@export var placed_at := 0.0
@export var completed_at := 0.0
@export var use_count := 0
@export var last_used_at := 0.0

func to_dict() -> Dictionary:
	return {"building_id": building_id, "slot_id": slot_id, "state": state, "placed_at": placed_at,
		"completed_at": completed_at, "use_count": use_count, "last_used_at": last_used_at}

static func from_dict(data: Dictionary) -> BuildingRecord:
	var r := BuildingRecord.new()
	for key in ["building_id", "slot_id", "state"]: r.set(key, str(data.get(key, r.get(key))))
	r.placed_at = float(data.get("placed_at", 0.0)); r.completed_at = float(data.get("completed_at", 0.0))
	r.use_count = int(data.get("use_count", 0)); r.last_used_at = float(data.get("last_used_at", 0.0))
	return r
