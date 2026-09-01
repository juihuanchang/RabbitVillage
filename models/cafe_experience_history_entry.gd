class_name CafeExperienceHistoryEntry
extends Resource

@export var history_id := ""
@export var amount_before := 0
@export var amount_change := 0
@export var amount_after := 0
@export var source_type := ""
@export var source_id := ""
@export var created_at := 0.0

func to_dict() -> Dictionary:
	return {
		"history_id": history_id,
		"amount_before": amount_before,
		"amount_change": amount_change,
		"amount_after": amount_after,
		"source_type": source_type,
		"source_id": source_id,
		"created_at": created_at
	}

static func from_dict(data: Dictionary) -> CafeExperienceHistoryEntry:
	var entry := CafeExperienceHistoryEntry.new()
	entry.history_id = str(data.get("history_id", ""))
	entry.amount_before = maxi(0, int(data.get("amount_before", 0)))
	entry.amount_change = int(data.get("amount_change", 0))
	entry.amount_after = maxi(0, int(data.get("amount_after", entry.amount_before + entry.amount_change)))
	entry.source_type = str(data.get("source_type", ""))
	entry.source_id = str(data.get("source_id", ""))
	entry.created_at = maxf(0.0, float(data.get("created_at", 0.0)))
	return entry
