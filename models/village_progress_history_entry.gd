class_name VillageProgressHistoryEntry
extends Resource

@export var history_id := ""
@export var village_progress_event_id := ""
@export var old_level := 0
@export var new_level := 0
@export var old_experience := 0
@export var new_experience := 0
@export var changed_at := 0.0

func to_dict() -> Dictionary:
	return {
		"history_id": history_id,
		"village_progress_event_id": village_progress_event_id,
		"old_level": old_level,
		"new_level": new_level,
		"old_experience": old_experience,
		"new_experience": new_experience,
		"changed_at": changed_at
	}

static func from_dict(data: Dictionary) -> VillageProgressHistoryEntry:
	var entry := VillageProgressHistoryEntry.new()
	entry.history_id = str(data.get("history_id", ""))
	entry.village_progress_event_id = str(data.get("village_progress_event_id", data.get("source_event_id", "")))
	entry.old_level = maxi(0, int(data.get("old_level", 0)))
	entry.new_level = maxi(0, int(data.get("new_level", 0)))
	entry.old_experience = maxi(0, int(data.get("old_experience", 0)))
	entry.new_experience = maxi(0, int(data.get("new_experience", 0)))
	entry.changed_at = maxf(0.0, float(data.get("changed_at", 0.0)))
	return entry
