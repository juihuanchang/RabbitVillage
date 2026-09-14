class_name ResidentLetterHistoryEntry
extends Resource

@export var event_id := ""
@export var resident_id := ""
@export var reaction_tag := ""
@export var received_at := 0.0

func to_dict() -> Dictionary:
	return {"event_id": event_id, "resident_id": resident_id, "reaction_tag": reaction_tag, "received_at": received_at}

static func from_dict(raw: Dictionary) -> ResidentLetterHistoryEntry:
	var value := ResidentLetterHistoryEntry.new()
	value.event_id = str(raw.get("event_id", raw.get("source_event_id", "")))
	value.resident_id = str(raw.get("resident_id", ""))
	value.reaction_tag = str(raw.get("reaction_tag", ""))
	value.received_at = maxf(0.0, float(raw.get("received_at", raw.get("created_at", 0.0))))
	return value

func is_valid() -> bool:
	return not event_id.is_empty() and not resident_id.is_empty()
