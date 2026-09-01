class_name GrowthAppearanceHistoryEntry
extends Resource

@export var appearance_state_id := "normal"
@export var source_event_id := ""
@export var changed_at := 0.0

func to_dict() -> Dictionary:
	return {
		"appearance_state_id": appearance_state_id,
		"source_event_id": source_event_id,
		"changed_at": changed_at
	}

static func from_dict(data: Dictionary) -> GrowthAppearanceHistoryEntry:
	var entry := GrowthAppearanceHistoryEntry.new()
	entry.appearance_state_id = str(data.get("appearance_state_id", "normal"))
	entry.source_event_id = str(data.get("source_event_id", ""))
	entry.changed_at = maxf(0.0, float(data.get("changed_at", 0.0)))
	return entry
