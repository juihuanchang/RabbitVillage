class_name EndingStateData
extends Resource
const LOCKED := "locked"
const AVAILABLE := "available"
const PENDING := "pending"
const COMPLETED := "completed"
@export var state := LOCKED
@export var ending_id := "stage1_ending"
@export var created_at := 0.0
@export var completed_at := 0.0
func to_dict() -> Dictionary: return {"state": state, "ending_id": ending_id, "created_at": created_at, "completed_at": completed_at}
static func from_dict(raw: Dictionary) -> EndingStateData:
	var value := EndingStateData.new(); value.state = str(raw.get("state", LOCKED)); value.ending_id = str(raw.get("ending_id", "stage1_ending")); value.created_at = float(raw.get("created_at", 0.0)); value.completed_at = float(raw.get("completed_at", 0.0)); return value
