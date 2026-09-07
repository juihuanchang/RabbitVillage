class_name GrowthDirectionChoiceHistoryEntry
extends Resource

@export var choice_id := ""
@export var selected_at := 0.0
@export var source_event_id := "growth_direction_001"
@export var resolved_branch := "balanced"

func to_dict() -> Dictionary:
	return {
		"choice_id": choice_id,
		"selected_at": selected_at,
		"source_event_id": source_event_id,
		"resolved_branch": resolved_branch
	}

static func from_dict(raw: Dictionary) -> GrowthDirectionChoiceHistoryEntry:
	var entry := GrowthDirectionChoiceHistoryEntry.new()
	entry.choice_id = str(raw.get("choice_id", ""))
	entry.selected_at = maxf(0.0, float(raw.get("selected_at", raw.get("confirmed_at", 0.0))))
	entry.source_event_id = str(raw.get("source_event_id", raw.get("event_id", "growth_direction_001")))
	entry.resolved_branch = str(raw.get("resolved_branch", "balanced"))
	return entry
