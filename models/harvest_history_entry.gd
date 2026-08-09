class_name HarvestHistoryEntry
extends Resource

@export var harvest_record_id := ""
@export var farm_cycle_id := ""
@export var harvested_at := 0.0
@export var harvest_amount := 0
@export var is_first_harvest := false

func to_dict() -> Dictionary:
    return {"harvest_record_id": harvest_record_id, "farm_cycle_id": farm_cycle_id, "harvested_at": harvested_at, "harvest_amount": harvest_amount, "is_first_harvest": is_first_harvest}

static func from_dict(data: Dictionary) -> HarvestHistoryEntry:
    var e := HarvestHistoryEntry.new()
    e.harvest_record_id = str(data.get("harvest_record_id", ""))
    e.farm_cycle_id = str(data.get("farm_cycle_id", ""))
    e.harvested_at = maxf(0.0, float(data.get("harvested_at", 0.0)))
    e.harvest_amount = maxi(0, int(data.get("harvest_amount", data.get("amount", 0))))
    e.is_first_harvest = bool(data.get("is_first_harvest", false))
    return e
