class_name GrowthPathProgressData
extends Resource

var forest_stage := 0
var lakeside_stage := 0
var forest_tendency_level := 0
var lakeside_tendency_level := 0
var last_updated_at := 0.0

func to_dict() -> Dictionary:
	return {"forest_stage": forest_stage, "lakeside_stage": lakeside_stage,
		"forest_tendency_level": forest_tendency_level, "lakeside_tendency_level": lakeside_tendency_level,
		"last_updated_at": last_updated_at}
