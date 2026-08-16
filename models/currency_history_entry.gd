class_name CurrencyHistoryEntry
extends Resource

var currency_history_id := ""
var currency_id := "coin"
var amount_before := 0
var amount_change := 0
var amount_after := 0
var source_type := ""
var source_id := ""
var created_at := 0.0

func to_dict() -> Dictionary:
	return {
		"currency_history_id": currency_history_id,
		"currency_id": currency_id,
		"amount_before": amount_before,
		"amount_change": amount_change,
		"amount_after": amount_after,
		"source_type": source_type,
		"source_id": source_id,
		"created_at": created_at
	}

static func from_dict(data: Dictionary) -> CurrencyHistoryEntry:
	var entry := CurrencyHistoryEntry.new()
	entry.currency_history_id = str(data.get("currency_history_id", ""))
	entry.currency_id = str(data.get("currency_id", "coin"))
	entry.amount_before = maxi(0, int(data.get("amount_before", 0)))
	entry.amount_after = maxi(0, int(data.get("amount_after", 0)))
	entry.amount_change = int(data.get("amount_change", entry.amount_after - entry.amount_before))
	entry.source_type = str(data.get("source_type", ""))
	entry.source_id = str(data.get("source_id", ""))
	entry.created_at = maxf(0.0, float(data.get("created_at", 0.0)))
	return entry
