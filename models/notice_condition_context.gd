class_name NoticeConditionContext
extends NoticeConditionData

static func from_dict(data: Dictionary) -> NoticeConditionContext:
    var c := NoticeConditionContext.new()
    c.recent_activity_location = str(data.get("recent_activity_location", ""))
    for id: Variant in data.get("completed_building_ids", []):
        c.completed_building_ids.append(str(id))
    c.constructing_building_id = str(data.get("constructing_building_id", ""))
    c.is_farm_growing = bool(data.get("is_farm_growing", false))
    c.are_carrots_ready = bool(data.get("are_carrots_ready", false))
    c.has_leaf_mark = bool(data.get("has_leaf_mark", false))
    return c
