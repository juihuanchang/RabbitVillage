class_name ResidentInteractionHistoryEntry
extends Resource

@export var interaction_id := ""
@export var resident_id := ""
@export var interaction_type := "resident_talk"
@export var relationship_change := 0
@export var social_experience_change := 0
@export var relationship_state := ResidentRelationshipData.STRANGER
@export var reaction_tag := ""
@export var interacted_at := 0.0

func to_dict() -> Dictionary:
	return {
		"interaction_id": interaction_id,
		"resident_id": resident_id,
		"interaction_type": interaction_type,
		"relationship_change": relationship_change,
		"social_experience_change": social_experience_change,
		"relationship_state": relationship_state,
		"reaction_tag": reaction_tag,
		"interacted_at": interacted_at
	}

static func from_dict(raw: Dictionary) -> ResidentInteractionHistoryEntry:
	var value := ResidentInteractionHistoryEntry.new()
	value.interaction_id = str(raw.get("interaction_id", ""))
	value.resident_id = str(raw.get("resident_id", ""))
	value.interaction_type = str(raw.get("interaction_type", "resident_talk"))
	value.relationship_change = maxi(0, int(raw.get("relationship_change", 0)))
	value.social_experience_change = maxi(0, int(raw.get("social_experience_change", 0)))
	value.relationship_state = str(raw.get("relationship_state", ResidentRelationshipData.STRANGER))
	value.reaction_tag = str(raw.get("reaction_tag", ""))
	value.interacted_at = maxf(0.0, float(raw.get("interacted_at", raw.get("created_at", 0.0))))
	return value

func is_valid() -> bool:
	return not interaction_id.is_empty() and not resident_id.is_empty()
