class_name ConstructionHistoryEntry
extends Resource

# Fourth-week fields are preserved. Week 7 extends the same record instead of creating
# a second construction-history system.
@export var construction_record_id := ""
@export var building_id := ""
@export var slot_id := ""
@export var started_at := 0.0
@export var complete_at := 0.0
@export var completed_at := 0.0
@export var coin_cost := 0
@export var material_costs: Dictionary = {}
@export var is_completed := false

var construction_id: String:
	get: return construction_record_id
	set(value): construction_record_id = value

func to_dict() -> Dictionary:
	return {
		"construction_record_id": construction_record_id,
		"construction_id": construction_record_id,
		"building_id": building_id,
		"slot_id": slot_id,
		"started_at": started_at,
		"complete_at": complete_at,
		"completed_at": completed_at,
		"coin_cost": coin_cost,
		"material_costs": material_costs.duplicate(true),
		"is_completed": is_completed or completed_at > 0.0
	}

static func from_dict(data: Dictionary) -> ConstructionHistoryEntry:
	var entry := ConstructionHistoryEntry.new()
	entry.construction_record_id = str(data.get("construction_record_id", data.get("construction_id", "")))
	entry.building_id = str(data.get("building_id", ""))
	entry.slot_id = str(data.get("slot_id", ""))
	entry.started_at = maxf(0.0, float(data.get("started_at", 0.0)))
	entry.complete_at = maxf(entry.started_at, float(data.get("complete_at", data.get("ends_at", entry.started_at))))
	entry.completed_at = maxf(0.0, float(data.get("completed_at", 0.0)))
	entry.coin_cost = maxi(0, int(data.get("coin_cost", data.get("cost", 0))))
	if data.get("material_costs", {}) is Dictionary:
		for raw_id: Variant in data.get("material_costs", {}).keys():
			var item_id := str(raw_id)
			var amount := maxi(0, int(data.get("material_costs", {})[raw_id]))
			if not item_id.is_empty() and amount > 0:
				entry.material_costs[item_id] = amount
	entry.is_completed = bool(data.get("is_completed", false)) or entry.completed_at > 0.0
	return entry
