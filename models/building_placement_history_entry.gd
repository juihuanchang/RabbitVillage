class_name BuildingPlacementHistoryEntry
extends Resource

@export var building_id := ""
@export var slot_id := ""
@export var placed_at := 0.0

func to_dict() -> Dictionary:
	return {
		"building_id": building_id,
		"slot_id": slot_id,
		"placed_at": placed_at
	}

static func from_dict(data: Dictionary) -> BuildingPlacementHistoryEntry:
	var entry := BuildingPlacementHistoryEntry.new()
	entry.building_id = str(data.get("building_id", ""))
	entry.slot_id = str(data.get("slot_id", ""))
	entry.placed_at = maxf(0.0, float(data.get("placed_at", 0.0)))
	return entry
