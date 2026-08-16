class_name ItemCollectionEntry
extends Resource

var item_id := ""
var is_discovered := false
var first_obtained_at := 0.0
var first_source_type := ""
var first_source_id := ""

func to_dict() -> Dictionary:
	return {
		"item_id": item_id,
		"is_discovered": is_discovered,
		"first_obtained_at": first_obtained_at,
		"first_source_type": first_source_type,
		"first_source_id": first_source_id
	}

static func from_dict(data: Dictionary) -> ItemCollectionEntry:
	var entry := ItemCollectionEntry.new()
	entry.item_id = str(data.get("item_id", ""))
	entry.is_discovered = bool(data.get("is_discovered", false))
	entry.first_obtained_at = maxf(0.0, float(data.get("first_obtained_at", 0.0)))
	entry.first_source_type = str(data.get("first_source_type", ""))
	entry.first_source_id = str(data.get("first_source_id", ""))
	return entry
