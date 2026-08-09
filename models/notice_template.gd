class_name NoticeTemplate
extends Resource

@export var notice_id := ""
@export var category := "general"
@export_multiline var content := ""
@export var required_building_id := ""
@export var required_building_state := ""
@export var required_farm_state := ""
@export var required_growth_mark_id := ""
@export var required_activity_location := ""
@export var priority := 0
@export var can_repeat := true

func to_dict() -> Dictionary:
    return {
        "notice_id": notice_id,
        "category": category,
        "content": content,
        "required_building_id": required_building_id,
        "required_building_state": required_building_state,
        "required_farm_state": required_farm_state,
        "required_growth_mark_id": required_growth_mark_id,
        "required_activity_location": required_activity_location,
        "priority": priority,
        "can_repeat": can_repeat
    }

static func from_dict(data: Dictionary) -> NoticeTemplate:
    var t := NoticeTemplate.new()
    t.notice_id = str(data.get("notice_id", data.get("NoticeId", "")))
    t.category = str(data.get("category", data.get("Category", "general")))
    t.content = str(data.get("content", data.get("Content", "")))
    t.required_building_id = str(data.get("required_building_id", data.get("RequiredBuildingId", "")))
    t.required_building_state = str(data.get("required_building_state", data.get("RequiredBuildingState", "")))
    t.required_farm_state = str(data.get("required_farm_state", data.get("RequiredFarmState", "")))
    t.required_growth_mark_id = str(data.get("required_growth_mark_id", data.get("RequiredGrowthMarkId", "")))
    t.required_activity_location = str(data.get("required_activity_location", data.get("RequiredActivityLocation", "")))
    t.priority = int(data.get("priority", data.get("Priority", 0)))
    t.can_repeat = bool(data.get("can_repeat", data.get("CanRepeat", true)))
    return t

func is_valid() -> bool:
    return not notice_id.is_empty() and not content.is_empty()
