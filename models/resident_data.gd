class_name ResidentData
extends Resource

@export var resident_id := ""
@export var display_name := ""
@export var state: ResidentStateData = ResidentStateData.new()
@export var relationship: ResidentRelationshipData = ResidentRelationshipData.new()
@export var relationship_history: Array[Dictionary] = []
@export var social_experience_history: Array[Dictionary] = []
@export var completed_event_ids: Array[String] = []
@export var daily_interactions: Dictionary = {}
@export var last_home_visit_day := ""
@export var pending_invitation: Dictionary = {}
@export var building_request: Dictionary = {}
var arrived_at: float:
	get: return state.arrived_at
	set(value): state.arrived_at = value
var current_location: String:
	get: return state.current_location
	set(value): state.current_location = value
var resident_state: String:
	get: return state.state
	set(value): state.state = value
var relationship_state: String:
	get: return relationship.state

func to_dict() -> Dictionary: return {"resident_id": resident_id, "display_name": display_name, "state": state.to_dict(), "relationship": relationship.to_dict(), "relationship_history": relationship_history.duplicate(true), "social_experience_history": social_experience_history.duplicate(true), "completed_event_ids": completed_event_ids.duplicate(), "daily_interactions": daily_interactions.duplicate(true), "last_home_visit_day": last_home_visit_day, "pending_invitation": pending_invitation.duplicate(true), "building_request": building_request.duplicate(true)}
static func from_dict(raw: Dictionary) -> ResidentData:
	var value := ResidentData.new(); value.resident_id = str(raw.get("resident_id", "")); value.display_name = str(raw.get("display_name", ""))
	value.state = ResidentStateData.from_dict(raw.get("state", {}) if raw.get("state", {}) is Dictionary else {})
	value.relationship = ResidentRelationshipData.from_dict(raw.get("relationship", {}) if raw.get("relationship", {}) is Dictionary else {}, value.resident_id)
	if raw.get("relationship_history", []) is Array: value.relationship_history.assign(raw.get("relationship_history", []))
	if raw.get("social_experience_history", []) is Array: value.social_experience_history.assign(raw.get("social_experience_history", []))
	if raw.get("completed_event_ids", []) is Array: value.completed_event_ids.assign(raw.get("completed_event_ids", []))
	value.daily_interactions = raw.get("daily_interactions", {}).duplicate(true) if raw.get("daily_interactions", {}) is Dictionary else {}
	value.last_home_visit_day = str(raw.get("last_home_visit_day", "")); value.pending_invitation = raw.get("pending_invitation", {}).duplicate(true) if raw.get("pending_invitation", {}) is Dictionary else {}; value.building_request = raw.get("building_request", {}).duplicate(true) if raw.get("building_request", {}) is Dictionary else {}; return value
