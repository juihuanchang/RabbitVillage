class_name InventoryEntry
extends Resource

var item_id := ""
var amount := 0
var total_obtained := 0
var first_obtained_at := 0.0
var last_obtained_at := 0.0

func to_dict() -> Dictionary:
	return {"item_id": item_id, "amount": amount, "total_obtained": total_obtained,
		"first_obtained_at": first_obtained_at, "last_obtained_at": last_obtained_at}

static func from_dict(data: Dictionary) -> InventoryEntry:
	var entry := InventoryEntry.new(); entry.item_id = str(data.get("item_id", ""))
	entry.amount = maxi(0, int(data.get("amount", 0)))
	entry.total_obtained = maxi(entry.amount, int(data.get("total_obtained", 0)))
	entry.first_obtained_at = float(data.get("first_obtained_at", 0.0))
	entry.last_obtained_at = float(data.get("last_obtained_at", 0.0)); return entry
