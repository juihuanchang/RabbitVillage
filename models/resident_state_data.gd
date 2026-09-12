class_name ResidentStateData
extends Resource

const LOCKED := "locked"
const VISITOR := "visitor"
const RESIDENT := "resident"
const VALID_STATES := [LOCKED, VISITOR, RESIDENT]

@export var state := LOCKED
@export var arrived_at := 0.0
@export var current_location := "cafe"

func to_dict() -> Dictionary: return {"state": state, "arrived_at": arrived_at, "current_location": current_location}
static func from_dict(raw: Dictionary) -> ResidentStateData:
	var value := ResidentStateData.new(); value.state = str(raw.get("state", LOCKED)); value.state = value.state if VALID_STATES.has(value.state) else LOCKED; value.arrived_at = maxf(0.0, float(raw.get("arrived_at", 0.0))); value.current_location = str(raw.get("current_location", "cafe")); return value
