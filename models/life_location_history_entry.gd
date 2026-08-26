class_name LifeLocationHistoryEntry
extends Resource

var location_record_id := ""
var location_id := ""
var activity_id := ""
var result: Dictionary = {}
var completed_at := 0.0
var date_key := ""

func to_dict() -> Dictionary:
	return {
		"location_record_id": location_record_id,
		"location_id": location_id,
		"activity_id": activity_id,
		"result": result.duplicate(true),
		"completed_at": completed_at,
		"date_key": date_key
	}

static func from_dict(data: Dictionary) -> LifeLocationHistoryEntry:
	var entry := LifeLocationHistoryEntry.new()
	entry.location_record_id = str(data.get("location_record_id", data.get("life_location_record_id", "")))
	entry.location_id = str(data.get("location_id", ""))
	entry.activity_id = str(data.get("activity_id", ""))
	if data.get("result", {}) is Dictionary:
		entry.result = data.get("result", {}).duplicate(true)
	entry.completed_at = maxf(0.0, float(data.get("completed_at", 0.0)))
	entry.date_key = str(data.get("date_key", ""))
	return entry
