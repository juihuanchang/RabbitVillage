class_name LifeEventHistoryEntry
extends Resource

var history_id := ""
var life_event_id := ""
var confirmed_at := 0.0

func to_dict() -> Dictionary:
	return {
		"history_id": history_id,
		"life_event_id": life_event_id,
		"confirmed_at": confirmed_at
	}

static func from_dict(data: Dictionary) -> LifeEventHistoryEntry:
	var entry := LifeEventHistoryEntry.new()
	entry.history_id = str(data.get("history_id", ""))
	entry.life_event_id = str(data.get("life_event_id", data.get("event_id", "")))
	entry.confirmed_at = maxf(0.0, float(data.get("confirmed_at", 0.0)))
	return entry
