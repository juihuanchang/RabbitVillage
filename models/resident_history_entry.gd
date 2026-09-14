class_name ResidentHistoryEntry
extends Resource

const ARRIVAL := "arrival"
const FIRST_MEETING := "first_meeting"

@export var history_id := ""
@export var resident_id := ""
@export var history_type := ""
@export var source_event_id := ""
@export var created_at := 0.0
@export var location_id := ""
@export var metadata: Dictionary = {}

func to_dict() -> Dictionary:
	var result := {
		"history_id": history_id,
		"resident_id": resident_id,
		"history_type": history_type,
		"source_event_id": source_event_id,
		"created_at": created_at,
		"location_id": location_id,
		"metadata": metadata.duplicate(true)
	}
	# Keep the explicit Week 9 field names in serialized data so Arrival / First
	# Meeting history stays readable without inferring the meaning of created_at.
	if history_type == ARRIVAL:
		result["arrived_at"] = created_at
	elif history_type == FIRST_MEETING:
		result["met_at"] = created_at
	return result

static func from_dict(raw: Dictionary) -> ResidentHistoryEntry:
	var value := ResidentHistoryEntry.new()
	value.history_id = str(raw.get("history_id", ""))
	value.resident_id = str(raw.get("resident_id", ""))
	value.history_type = str(raw.get("history_type", ""))
	value.source_event_id = str(raw.get("source_event_id", ""))
	value.created_at = maxf(0.0, float(raw.get("created_at", raw.get("arrived_at", raw.get("met_at", 0.0)))))
	value.location_id = str(raw.get("location_id", ""))
	value.metadata = raw.get("metadata", {}).duplicate(true) if raw.get("metadata", {}) is Dictionary else {}
	return value

func is_valid() -> bool:
	return not resident_id.is_empty() and history_type in [ARRIVAL, FIRST_MEETING] and created_at >= 0.0
