class_name GrowthMarkData
extends Resource

var id := ""
var display_name := ""
var growth_path := ""
var stage := 0
var description := ""
var required_experience := 0
var required_visit_count := 0
var required_activity_id := ""
var is_unlocked := false
var unlocked_at := 0.0

func to_dict() -> Dictionary:
	return {"id": id, "display_name": display_name, "growth_path": growth_path, "stage": stage,
		"description": description, "required_experience": required_experience,
		"required_visit_count": required_visit_count, "required_activity_id": required_activity_id,
		"is_unlocked": is_unlocked, "unlocked_at": unlocked_at}

static func create(id_value: String, path: String, stage_value: int) -> GrowthMarkData:
	var mark := GrowthMarkData.new(); mark.id = id_value; mark.display_name = id_value
	mark.growth_path = path; mark.stage = stage_value; return mark

static func create_leaf_mark() -> GrowthMarkData:
	var mark := create("leaf_mark", "forest", 1); mark.required_experience = 20; mark.required_visit_count = 3; return mark
