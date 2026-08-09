class_name BuildingUseHistoryEntry
extends Resource

@export var building_use_record_id := ""
@export var building_id := ""
@export var started_at := 0.0
@export var completed_at := 0.0
@export var use_count := 0

func to_dict() -> Dictionary:
    return {"building_use_record_id": building_use_record_id, "building_id": building_id, "started_at": started_at, "completed_at": completed_at, "use_count": use_count}

static func from_dict(data: Dictionary) -> BuildingUseHistoryEntry:
    var e := BuildingUseHistoryEntry.new()
    e.building_use_record_id = str(data.get("building_use_record_id", data.get("interaction_record_id", "")))
    e.building_id = str(data.get("building_id", ""))
    e.started_at = maxf(0.0, float(data.get("started_at", 0.0)))
    e.completed_at = maxf(0.0, float(data.get("completed_at", 0.0)))
    e.use_count = maxi(0, int(data.get("use_count", 0)))
    return e
