class_name SharedActivityHistoryEntry
extends Resource

@export var activity_record_id := ""
@export var activity_id := ""
@export var resident_id := ""
@export var location_id := ""
@export var relationship_change := 0
@export var social_experience_change := 0
@export var relationship_state := ResidentRelationshipData.STRANGER
@export var reaction_tag := ""
@export var completed_at := 0.0

func to_dict() -> Dictionary:
	return {
		"activity_record_id": activity_record_id,
		"activity_id": activity_id,
		"resident_id": resident_id,
		"location_id": location_id,
		"relationship_change": relationship_change,
		"social_experience_change": social_experience_change,
		"relationship_state": relationship_state,
		"reaction_tag": reaction_tag,
		"completed_at": completed_at
	}

static func from_dict(raw: Dictionary) -> SharedActivityHistoryEntry:
	var value := SharedActivityHistoryEntry.new()
	value.activity_record_id = str(raw.get("activity_record_id", ""))
	value.activity_id = str(raw.get("activity_id", ""))
	value.resident_id = str(raw.get("resident_id", raw.get("participant_resident_id", "")))
	value.location_id = str(raw.get("location_id", ""))
	value.relationship_change = maxi(0, int(raw.get("relationship_change", 0)))
	value.social_experience_change = maxi(0, int(raw.get("social_experience_change", 0)))
	value.relationship_state = str(raw.get("relationship_state", ResidentRelationshipData.STRANGER))
	value.reaction_tag = str(raw.get("reaction_tag", ""))
	value.completed_at = maxf(0.0, float(raw.get("completed_at", raw.get("created_at", 0.0))))
	return value

func is_valid() -> bool:
	return not activity_record_id.is_empty() and not resident_id.is_empty()
