class_name BuildingUnlockHistoryEntry
extends Resource

@export var building_id := ""
@export var unlocked_at := 0.0
@export var source_event_id := ""

func to_dict() -> Dictionary:
	return {
		"building_id": building_id,
		"unlocked_at": unlocked_at,
		"source_event_id": source_event_id
	}

static func from_dict(data: Dictionary) -> BuildingUnlockHistoryEntry:
	var entry := BuildingUnlockHistoryEntry.new()
	entry.building_id = str(data.get("building_id", ""))
	entry.unlocked_at = maxf(0.0, float(data.get("unlocked_at", 0.0)))
	entry.source_event_id = str(data.get("source_event_id", ""))
	return entry
