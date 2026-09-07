class_name StageCompletionHistoryEntry
extends Resource

@export var stage_id := "stage1"
@export var completed_at := 0.0
@export var source_event_id := "village_stage1_complete_001"

func to_dict() -> Dictionary:
	return {"stage_id": stage_id, "completed_at": completed_at, "source_event_id": source_event_id}

static func from_dict(raw: Dictionary) -> StageCompletionHistoryEntry:
	var entry := StageCompletionHistoryEntry.new()
	entry.stage_id = str(raw.get("stage_id", "stage1"))
	entry.completed_at = maxf(0.0, float(raw.get("completed_at", 0.0)))
	entry.source_event_id = str(raw.get("source_event_id", "village_stage1_complete_001"))
	return entry
