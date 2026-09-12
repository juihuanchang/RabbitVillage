class_name ResidentRelationshipData
extends Resource

const STRANGER := "stranger"
const ACQUAINTANCE := "acquaintance"
const FRIEND := "friend"

@export var resident_id := ""
@export var state := STRANGER
@export var progress := 0
@export var interaction_count := 0
@export var shared_activity_count := 0
@export var event_count := 0
@export var gift_count := 0
@export var applied_source_ids: Array[String] = []

func to_dict() -> Dictionary: return {"resident_id": resident_id, "state": state, "progress": progress, "interaction_count": interaction_count, "shared_activity_count": shared_activity_count, "event_count": event_count, "gift_count": gift_count, "applied_source_ids": applied_source_ids.duplicate()}
static func from_dict(raw: Dictionary, id: String = "") -> ResidentRelationshipData:
	var value := ResidentRelationshipData.new(); value.resident_id = str(raw.get("resident_id", id)); value.state = str(raw.get("state", STRANGER)); value.state = value.state if value.state in [STRANGER, ACQUAINTANCE, FRIEND] else STRANGER; value.progress = maxi(0, int(raw.get("progress", 0))); value.interaction_count = maxi(0, int(raw.get("interaction_count", 0))); value.shared_activity_count = maxi(0, int(raw.get("shared_activity_count", 0))); value.event_count = maxi(0, int(raw.get("event_count", 0))); value.gift_count = maxi(0, int(raw.get("gift_count", 0))); 
	if raw.get("applied_source_ids", []) is Array: value.applied_source_ids.assign(raw.get("applied_source_ids", []))
	return value
