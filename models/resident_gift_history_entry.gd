class_name ResidentGiftHistoryEntry
extends Resource

@export var event_id := ""
@export var resident_id := ""
@export var item_id := ""
@export var amount := 0
@export var received_at := 0.0

func to_dict() -> Dictionary:
	return {"event_id": event_id, "resident_id": resident_id, "item_id": item_id, "amount": amount, "received_at": received_at}

static func from_dict(raw: Dictionary) -> ResidentGiftHistoryEntry:
	var value := ResidentGiftHistoryEntry.new()
	value.event_id = str(raw.get("event_id", raw.get("source_event_id", "")))
	value.resident_id = str(raw.get("resident_id", ""))
	value.item_id = str(raw.get("item_id", ""))
	value.amount = maxi(0, int(raw.get("amount", 0)))
	value.received_at = maxf(0.0, float(raw.get("received_at", raw.get("created_at", 0.0))))
	return value

func is_valid() -> bool:
	return not event_id.is_empty() and not resident_id.is_empty() and not item_id.is_empty() and amount > 0
