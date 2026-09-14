class_name ResidentVisitHistoryEntry
extends Resource

@export var event_id := ""
@export var resident_id := ""
@export var location_id := "home"
@export var visited_at := 0.0

func to_dict() -> Dictionary:
	return {"event_id": event_id, "resident_id": resident_id, "location_id": location_id, "visited_at": visited_at}

static func from_dict(raw: Dictionary) -> ResidentVisitHistoryEntry:
	var value := ResidentVisitHistoryEntry.new()
	value.event_id = str(raw.get("event_id", raw.get("source_event_id", "")))
	value.resident_id = str(raw.get("resident_id", ""))
	value.location_id = str(raw.get("location_id", "home"))
	value.visited_at = maxf(0.0, float(raw.get("visited_at", raw.get("created_at", 0.0))))
	return value

func is_valid() -> bool:
	return not event_id.is_empty() and not resident_id.is_empty()
