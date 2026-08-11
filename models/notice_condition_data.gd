class_name NoticeConditionData
extends Resource
@export var recent_activity_location := ""
@export var completed_building_ids: Array[String] = []
@export var constructing_building_id := ""
@export var is_farm_growing := false
@export var are_carrots_ready := false
@export var has_leaf_mark := false
func to_dict() -> Dictionary: return {"recent_activity_location": recent_activity_location, "completed_building_ids": completed_building_ids.duplicate(), "constructing_building_id": constructing_building_id, "is_farm_growing": is_farm_growing, "are_carrots_ready": are_carrots_ready, "has_leaf_mark": has_leaf_mark}

static func from_dict(data: Dictionary) -> NoticeConditionData:
	var condition := NoticeConditionData.new()
	condition.recent_activity_location = str(data.get("recent_activity_location", ""))
	for id: Variant in data.get("completed_building_ids", []):
		condition.completed_building_ids.append(str(id))
	condition.constructing_building_id = str(data.get("constructing_building_id", ""))
	condition.is_farm_growing = bool(data.get("is_farm_growing", false))
	condition.are_carrots_ready = bool(data.get("are_carrots_ready", false))
	condition.has_leaf_mark = bool(data.get("has_leaf_mark", false))
	return condition
