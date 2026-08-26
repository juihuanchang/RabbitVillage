class_name ProductUnlockHistoryEntry
extends Resource

var product_id := ""
var unlocked_at := 0.0
var source_type := ""
var source_id := ""

func to_dict() -> Dictionary:
	return {"product_id": product_id, "unlocked_at": unlocked_at, "source_type": source_type, "source_id": source_id}

static func from_dict(data: Dictionary) -> ProductUnlockHistoryEntry:
	var entry := ProductUnlockHistoryEntry.new()
	entry.product_id = str(data.get("product_id", ""))
	entry.unlocked_at = maxf(0.0, float(data.get("unlocked_at", 0.0)))
	entry.source_type = str(data.get("source_type", ""))
	entry.source_id = str(data.get("source_id", ""))
	return entry
