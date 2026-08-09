class_name ConstructionHistoryEntry
extends Resource

@export var construction_record_id := ""
@export var building_id := ""
@export var slot_id := ""
@export var started_at := 0.0
@export var completed_at := 0.0

func to_dict() -> Dictionary:
    return {"construction_record_id": construction_record_id, "building_id": building_id, "slot_id": slot_id, "started_at": started_at, "completed_at": completed_at}

static func from_dict(data: Dictionary) -> ConstructionHistoryEntry:
    var e := ConstructionHistoryEntry.new()
    e.construction_record_id = str(data.get("construction_record_id", ""))
    e.building_id = str(data.get("building_id", ""))
    e.slot_id = str(data.get("slot_id", ""))
    e.started_at = maxf(0.0, float(data.get("started_at", 0.0)))
    e.completed_at = maxf(0.0, float(data.get("completed_at", 0.0)))
    return e
