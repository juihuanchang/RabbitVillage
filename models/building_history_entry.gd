class_name BuildingHistoryEntry
extends Resource

@export var building_id := ""
@export var slot_id := ""
@export var unlocked_at := 0.0
@export var placed_at := 0.0
@export var construction_started_at := 0.0
@export var completed_at := 0.0
@export var first_used_at := 0.0
@export var last_used_at := 0.0
@export var use_count := 0
@export var is_legacy_test_data := false

func to_dict() -> Dictionary:
    return {
        "building_id": building_id,
        "slot_id": slot_id,
        "unlocked_at": unlocked_at,
        "placed_at": placed_at,
        "construction_started_at": construction_started_at,
        "completed_at": completed_at,
        "first_used_at": first_used_at,
        "last_used_at": last_used_at,
        "use_count": use_count,
        "is_legacy_test_data": is_legacy_test_data
    }

static func from_dict(data: Dictionary) -> BuildingHistoryEntry:
    var e := BuildingHistoryEntry.new()
    e.building_id = str(data.get("building_id", ""))
    e.slot_id = str(data.get("slot_id", ""))
    e.unlocked_at = maxf(0.0, float(data.get("unlocked_at", 0.0)))
    e.placed_at = maxf(0.0, float(data.get("placed_at", 0.0)))
    e.construction_started_at = maxf(0.0, float(data.get("construction_started_at", 0.0)))
    e.completed_at = maxf(0.0, float(data.get("completed_at", 0.0)))
    e.first_used_at = maxf(0.0, float(data.get("first_used_at", 0.0)))
    e.last_used_at = maxf(0.0, float(data.get("last_used_at", 0.0)))
    e.use_count = maxi(0, int(data.get("use_count", 0)))
    e.is_legacy_test_data = bool(data.get("is_legacy_test_data", false))
    return e
