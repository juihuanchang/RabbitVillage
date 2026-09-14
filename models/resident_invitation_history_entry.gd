class_name ResidentInvitationHistoryEntry
extends Resource

@export var invitation_id := ""
@export var resident_id := ""
@export var activity_id := ""
@export var state := "pending"
@export var created_at := 0.0
@export var responded_at := 0.0

func to_dict() -> Dictionary:
	return {"invitation_id": invitation_id, "resident_id": resident_id, "activity_id": activity_id, "state": state, "created_at": created_at, "responded_at": responded_at}

static func from_dict(raw: Dictionary) -> ResidentInvitationHistoryEntry:
	var value := ResidentInvitationHistoryEntry.new()
	value.invitation_id = str(raw.get("invitation_id", ""))
	value.resident_id = str(raw.get("resident_id", ""))
	value.activity_id = str(raw.get("activity_id", ""))
	value.state = str(raw.get("state", "pending"))
	if value.state not in ["pending", "accepted", "declined"]: value.state = "pending"
	value.created_at = maxf(0.0, float(raw.get("created_at", 0.0)))
	value.responded_at = maxf(0.0, float(raw.get("responded_at", 0.0)))
	return value

func is_valid() -> bool:
	return not invitation_id.is_empty() and not resident_id.is_empty()
