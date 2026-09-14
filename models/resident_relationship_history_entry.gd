class_name ResidentRelationshipHistoryEntry
extends Resource

@export var relationship_history_id := ""
@export var resident_id := ""
@export var source_id := ""
@export var old_state := ResidentRelationshipData.STRANGER
@export var new_state := ResidentRelationshipData.STRANGER
@export var stage_changed_at := 0.0

func to_dict() -> Dictionary:
	return {
		"relationship_history_id": relationship_history_id,
		"resident_id": resident_id,
		"source_id": source_id,
		"old_state": old_state,
		"new_state": new_state,
		"stage_changed_at": stage_changed_at
	}

static func from_dict(raw: Dictionary) -> ResidentRelationshipHistoryEntry:
	var value := ResidentRelationshipHistoryEntry.new()
	value.relationship_history_id = str(raw.get("relationship_history_id", ""))
	value.resident_id = str(raw.get("resident_id", ""))
	value.source_id = str(raw.get("source_id", raw.get("source_event_id", "")))
	value.old_state = str(raw.get("old_state", ResidentRelationshipData.STRANGER))
	value.new_state = str(raw.get("new_state", raw.get("relationship_state", ResidentRelationshipData.STRANGER)))
	value.stage_changed_at = maxf(0.0, float(raw.get("stage_changed_at", raw.get("changed_at", 0.0))))
	return value

func is_valid() -> bool:
	return not resident_id.is_empty() and new_state in [ResidentRelationshipData.STRANGER, ResidentRelationshipData.ACQUAINTANCE, ResidentRelationshipData.FRIEND]
