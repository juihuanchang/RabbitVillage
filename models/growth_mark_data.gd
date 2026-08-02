class_name GrowthMarkData
extends Resource

@export var id := ""
@export var display_name := ""
@export var growth_path := ""
@export var stage := 0
@export_multiline var description := ""
@export var required_experience := 0
@export var required_visit_count := 0
@export var required_activity_id := ""
@export var is_unlocked := false
@export var unlocked_at := 0.0

func to_dict() -> Dictionary:
	return {"id": id, "display_name": display_name, "growth_path": growth_path, "stage": stage,
		"description": description, "required_experience": required_experience,
		"required_visit_count": required_visit_count, "required_activity_id": required_activity_id,
		"is_unlocked": is_unlocked, "unlocked_at": unlocked_at}

static func create_leaf_mark() -> GrowthMarkData:
	var mark := GrowthMarkData.new()
	mark.id = "leaf_mark"; mark.display_name = "第一片葉子"; mark.growth_path = "forest"; mark.stage = 1
	mark.description = "Amy 耳朵旁出現了一片小葉子。"; mark.required_experience = 20; mark.required_visit_count = 3
	return mark
