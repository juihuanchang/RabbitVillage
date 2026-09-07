class_name FinalGrowthHistoryEntry
extends Resource

@export var final_growth_record_id := ""
@export var growth_path := ""
@export var old_stage := 0
@export var new_stage := 0
@export var final_form := "none"
@export var completed_at := 0.0

func to_dict() -> Dictionary:
	return {
		"final_growth_record_id": final_growth_record_id,
		"growth_path": growth_path,
		"old_stage": old_stage,
		"new_stage": new_stage,
		"final_form": final_form,
		"completed_at": completed_at
	}

static func from_dict(raw: Dictionary) -> FinalGrowthHistoryEntry:
	var entry := FinalGrowthHistoryEntry.new()
	entry.final_growth_record_id = str(raw.get("final_growth_record_id", ""))
	entry.growth_path = str(raw.get("growth_path", raw.get("branch", "")))
	entry.old_stage = maxi(0, int(raw.get("old_stage", 0)))
	entry.new_stage = maxi(0, int(raw.get("new_stage", 0)))
	entry.final_form = str(raw.get("final_form", raw.get("current_form", "none")))
	entry.completed_at = maxf(0.0, float(raw.get("completed_at", 0.0)))
	return entry
