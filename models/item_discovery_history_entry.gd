class_name ItemDiscoveryHistoryEntry
extends Resource

var discovery_id := ""
var item_id := ""
var discovered_at := 0.0
var source_type := ""
var source_id := ""

func to_dict() -> Dictionary:
	return {
		"discovery_id": discovery_id,
		"item_id": item_id,
		"discovered_at": discovered_at,
		"source_type": source_type,
		"source_id": source_id
	}

static func from_dict(data: Dictionary) -> ItemDiscoveryHistoryEntry:
	var entry := ItemDiscoveryHistoryEntry.new()
	entry.discovery_id = str(data.get("discovery_id", ""))
	entry.item_id = str(data.get("item_id", ""))
	entry.discovered_at = maxf(0.0, float(data.get("discovered_at", 0.0)))
	entry.source_type = str(data.get("source_type", ""))
	entry.source_id = str(data.get("source_id", ""))
	return entry
