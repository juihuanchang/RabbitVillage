class_name ResidentSocialExperienceHistoryEntry
extends Resource

@export var source_type := ""
@export var source_id := ""
@export var resident_id := ""
@export var amount := 0
@export var created_at := 0.0

func to_dict() -> Dictionary:
	return {"source_type": source_type, "source_id": source_id, "resident_id": resident_id, "amount": amount, "created_at": created_at}

static func from_dict(raw: Dictionary) -> ResidentSocialExperienceHistoryEntry:
	var value := ResidentSocialExperienceHistoryEntry.new()
	value.source_type = str(raw.get("source_type", ""))
	value.source_id = str(raw.get("source_id", ""))
	value.resident_id = str(raw.get("resident_id", ""))
	value.amount = maxi(0, int(raw.get("amount", 0)))
	value.created_at = maxf(0.0, float(raw.get("created_at", 0.0)))
	return value

func is_valid() -> bool:
	return not source_id.is_empty() and not resident_id.is_empty() and amount > 0
