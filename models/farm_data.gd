class_name FarmData
extends Resource

@export var crop_id := "carrot"
@export var state := FarmState.LOCKED
@export var growth_seconds := 90.0
@export var current_cycle: Dictionary = {}
@export var completed_cycle_ids: Array[String] = []

func to_dict() -> Dictionary:
    return {"crop_id": "carrot", "state": state, "growth_seconds": growth_seconds, "current_cycle": current_cycle.duplicate(true), "completed_cycle_ids": completed_cycle_ids.duplicate()}

static func from_dict(d: Dictionary) -> FarmData:
    var f := FarmData.new()
    f.crop_id = "carrot"
    f.state = str(d.get("state", FarmState.LOCKED))
    f.growth_seconds = maxf(0.1, float(d.get("growth_seconds", 90.0)))
    if d.get("current_cycle", {}) is Dictionary:
        f.current_cycle = d.get("current_cycle", {}).duplicate(true)
    for id: Variant in d.get("completed_cycle_ids", []):
        f.completed_cycle_ids.append(str(id))
    return f
