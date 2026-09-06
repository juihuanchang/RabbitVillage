class_name FinalGrowthStateData
extends Resource
@export var state := "not_available"
@export var branch := "balanced"
@export var pending_at := 0.0
@export var complete_at := 0.0
@export var completed_at := 0.0
@export var result_applied := false
func to_dict() -> Dictionary: return {"state": state, "branch": branch, "pending_at": pending_at, "complete_at": complete_at, "completed_at": completed_at, "result_applied": result_applied}
static func from_dict(raw: Dictionary) -> FinalGrowthStateData:
	var value := FinalGrowthStateData.new(); value.state = str(raw.get("state", "not_available")); value.branch = str(raw.get("branch", "balanced")); value.pending_at = float(raw.get("pending_at", 0.0)); value.complete_at = float(raw.get("complete_at", 0.0)); value.completed_at = float(raw.get("completed_at", 0.0)); value.result_applied = bool(raw.get("result_applied", false)); return value
