class_name FarmCycleHistoryEntry
extends Resource

@export var farm_cycle_id := ""
@export var started_at := 0.0
@export var ready_at := 0.0
@export var harvested_at := 0.0
@export var harvest_amount := 0
@export var is_harvested := false

func to_dict() -> Dictionary:
    return {"farm_cycle_id": farm_cycle_id, "started_at": started_at, "ready_at": ready_at, "harvested_at": harvested_at, "harvest_amount": harvest_amount, "is_harvested": is_harvested}

static func from_dict(data: Dictionary) -> FarmCycleHistoryEntry:
    var e := FarmCycleHistoryEntry.new()
    e.farm_cycle_id = str(data.get("farm_cycle_id", ""))
    e.started_at = maxf(0.0, float(data.get("started_at", 0.0)))
    e.ready_at = maxf(0.0, float(data.get("ready_at", 0.0)))
    e.harvested_at = maxf(0.0, float(data.get("harvested_at", 0.0)))
    e.harvest_amount = maxi(0, int(data.get("harvest_amount", 0)))
    e.is_harvested = bool(data.get("is_harvested", false))
    return e
