class_name ShopEventHistoryEntry
extends Resource

var history_id := ""
var shop_event_id := ""
var confirmed_at := 0.0

func to_dict() -> Dictionary:
	return {"history_id": history_id, "shop_event_id": shop_event_id, "confirmed_at": confirmed_at}

static func from_dict(data: Dictionary) -> ShopEventHistoryEntry:
	var entry := ShopEventHistoryEntry.new()
	entry.history_id = str(data.get("history_id", ""))
	entry.shop_event_id = str(data.get("shop_event_id", ""))
	entry.confirmed_at = maxf(0.0, float(data.get("confirmed_at", 0.0)))
	return entry
