class_name GrowthDirectionChoiceData
extends Resource

const NOT_AVAILABLE := "not_available"
const AVAILABLE := "available"
const PENDING_CHOICE := "pending_choice"
const CHOICE_CONFIRMED := "choice_confirmed"
const FINAL_PENDING := "final_pending"
const FINAL_COMPLETED := "final_completed"
const VALID_CHOICES := ["encourage_forest", "maintain_current", "encourage_lakeside", "let_rabbit_decide"]

@export var event_id := "growth_direction_001"
@export var state := NOT_AVAILABLE
@export var choice_id := ""
@export var resolved_branch := "balanced"
@export var confirmed_at := 0.0

func to_dict() -> Dictionary: return {"event_id": event_id, "state": state, "choice_id": choice_id, "resolved_branch": resolved_branch, "confirmed_at": confirmed_at}
static func from_dict(raw: Dictionary) -> GrowthDirectionChoiceData:
	var value := GrowthDirectionChoiceData.new(); value.state = str(raw.get("state", NOT_AVAILABLE)); value.choice_id = str(raw.get("choice_id", "")); value.resolved_branch = str(raw.get("resolved_branch", "balanced")); value.confirmed_at = float(raw.get("confirmed_at", 0.0)); return value
