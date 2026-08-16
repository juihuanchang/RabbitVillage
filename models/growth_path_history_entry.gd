class_name GrowthPathHistoryEntry
extends Resource

var history_id := ""
var growth_path := ""
var old_stage := 0
var new_stage := 0
var source_event_id := ""
var changed_at := 0.0

func to_dict() -> Dictionary:
	return {
		"history_id": history_id,
		"growth_path": growth_path,
		"old_stage": old_stage,
		"new_stage": new_stage,
		"source_event_id": source_event_id,
		"changed_at": changed_at
	}

static func from_dict(data: Dictionary) -> GrowthPathHistoryEntry:
	var entry := GrowthPathHistoryEntry.new()
	entry.history_id = str(data.get("history_id", ""))
	entry.growth_path = str(data.get("growth_path", ""))
	entry.old_stage = maxi(0, int(data.get("old_stage", 0)))
	entry.new_stage = maxi(0, int(data.get("new_stage", 0)))
	entry.source_event_id = str(data.get("source_event_id", ""))
	entry.changed_at = maxf(0.0, float(data.get("changed_at", 0.0)))
	return entry
