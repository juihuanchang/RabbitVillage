class_name NoticeConditionData
extends Resource
@export var recent_activity_location := ""
@export var completed_building_ids: Array[String] = []
@export var constructing_building_id := ""
@export var is_farm_growing := false
@export var are_carrots_ready := false
@export var has_leaf_mark := false
func to_dict() -> Dictionary: return {"recent_activity_location": recent_activity_location, "completed_building_ids": completed_building_ids.duplicate(), "constructing_building_id": constructing_building_id, "is_farm_growing": is_farm_growing, "are_carrots_ready": are_carrots_ready, "has_leaf_mark": has_leaf_mark}
