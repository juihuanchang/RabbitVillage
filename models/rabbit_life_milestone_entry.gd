class_name RabbitLifeMilestoneEntry
extends Resource

@export var milestone_id := ""
@export var occurred_at := 0.0
@export var occurred_date := ""
@export var source_type := ""
@export var source_id := ""

func to_dict() -> Dictionary:
	return {
		"milestone_id": milestone_id,
		"occurred_at": occurred_at,
		"occurred_date": occurred_date,
		"source_type": source_type,
		"source_id": source_id
	}

static func from_dict(raw: Dictionary) -> RabbitLifeMilestoneEntry:
	var entry := RabbitLifeMilestoneEntry.new()
	entry.milestone_id = str(raw.get("milestone_id", ""))
	entry.occurred_at = maxf(0.0, float(raw.get("occurred_at", 0.0)))
	entry.occurred_date = str(raw.get("occurred_date", ""))
	entry.source_type = str(raw.get("source_type", ""))
	entry.source_id = str(raw.get("source_id", ""))
	return entry
