class_name EndingResult
extends Resource
@export var ending_id := "stage1_ending"
@export var ending_type := ""
@export var current_form := "none"
@export var growth_summary: Dictionary = {}
@export var village_summary: Dictionary = {}
@export var important_memories: Array[String] = []
@export var completed_at := 0.0
@export var first_completion := false
func to_dict() -> Dictionary: return {"ending_id": ending_id, "ending_type": ending_type, "current_form": current_form, "growth_summary": growth_summary.duplicate(true), "village_summary": village_summary.duplicate(true), "important_memories": important_memories.duplicate(), "completed_at": completed_at, "first_completion": first_completion}
