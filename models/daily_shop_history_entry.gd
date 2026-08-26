class_name DailyShopHistoryEntry
extends Resource

var day_key := ""
var offers: Array[Dictionary] = []
var refreshed_at := 0.0
var refresh_count := 0
var purchase_counts: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"day_key": day_key,
		"offers": offers.duplicate(true),
		"refreshed_at": refreshed_at,
		"refresh_count": refresh_count,
		"purchase_counts": purchase_counts.duplicate(true)
	}

static func from_dict(data: Dictionary) -> DailyShopHistoryEntry:
	var entry := DailyShopHistoryEntry.new()
	entry.day_key = str(data.get("day_key", ""))
	for raw: Variant in data.get("offers", []):
		if raw is Dictionary:
			entry.offers.append(raw.duplicate(true))
	entry.refreshed_at = maxf(0.0, float(data.get("refreshed_at", 0.0)))
	entry.refresh_count = maxi(0, int(data.get("refresh_count", 0)))
	if data.get("purchase_counts", {}) is Dictionary:
		entry.purchase_counts = data.get("purchase_counts", {}).duplicate(true)
	return entry
