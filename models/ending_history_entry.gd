class_name EndingHistoryEntry
extends Resource

@export var ending_id := ""
@export var ending_type := ""
@export var completed_at := 0.0
@export var final_form := "none"
@export var snapshot_id := ""

func to_dict() -> Dictionary:
	return {
		"ending_id": ending_id,
		"ending_type": ending_type,
		"completed_at": completed_at,
		"final_form": final_form,
		"snapshot_id": snapshot_id
	}

static func from_dict(raw: Dictionary) -> EndingHistoryEntry:
	var entry := EndingHistoryEntry.new()
	entry.ending_id = str(raw.get("ending_id", ""))
	entry.ending_type = str(raw.get("ending_type", ""))
	entry.completed_at = maxf(0.0, float(raw.get("completed_at", 0.0)))
	entry.final_form = str(raw.get("final_form", raw.get("current_form", "none")))
	entry.snapshot_id = str(raw.get("snapshot_id", ""))
	return entry
