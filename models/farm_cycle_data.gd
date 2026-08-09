class_name FarmCycleData
extends Resource
@export var farm_cycle_id := ""
@export var crop_id := "carrot"
@export var started_at := 0.0
@export var ready_at := 0.0
@export var harvested_at := 0.0
@export var is_harvested := false
func to_dict() -> Dictionary: return {"farm_cycle_id": farm_cycle_id, "crop_id": crop_id, "started_at": started_at, "ready_at": ready_at, "harvested_at": harvested_at, "is_harvested": is_harvested}
static func from_dict(d: Dictionary) -> FarmCycleData:
	var c := FarmCycleData.new(); c.farm_cycle_id = str(d.get("farm_cycle_id", "")); c.started_at = float(d.get("started_at", 0.0)); c.ready_at = float(d.get("ready_at", 0.0)); c.harvested_at = float(d.get("harvested_at", 0.0)); c.is_harvested = bool(d.get("is_harvested", false)); return c
