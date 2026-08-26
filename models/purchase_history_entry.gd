class_name PurchaseHistoryEntry
extends Resource

var purchase_record_id := ""
var product_id := ""
var item_id := ""
var quantity := 0
var unit_price := 0
var total_price := 0
var purchased_at := 0.0
var date_key := ""

func to_dict() -> Dictionary:
	return {
		"purchase_record_id": purchase_record_id,
		"product_id": product_id,
		"item_id": item_id,
		"quantity": quantity,
		"unit_price": unit_price,
		"total_price": total_price,
		"purchased_at": purchased_at,
		"date_key": date_key
	}

static func from_dict(data: Dictionary) -> PurchaseHistoryEntry:
	var entry := PurchaseHistoryEntry.new()
	entry.purchase_record_id = str(data.get("purchase_record_id", ""))
	entry.product_id = str(data.get("product_id", ""))
	entry.item_id = str(data.get("item_id", ""))
	entry.quantity = maxi(0, int(data.get("quantity", 0)))
	entry.unit_price = maxi(0, int(data.get("unit_price", 0)))
	entry.total_price = maxi(0, int(data.get("total_price", entry.unit_price * entry.quantity)))
	entry.purchased_at = maxf(0.0, float(data.get("purchased_at", 0.0)))
	entry.date_key = str(data.get("date_key", ""))
	return entry
