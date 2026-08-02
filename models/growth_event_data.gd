class_name GrowthEventData
extends Resource

@export var event_id := ""
@export var growth_mark_id := ""
@export var title := ""
@export_multiline var content := ""
@export var triggered_at := 0.0
@export var is_confirmed := false
@export var is_applied := false

func to_dict() -> Dictionary:
	return {"event_id": event_id, "growth_mark_id": growth_mark_id, "title": title, "content": content,
		"triggered_at": triggered_at, "is_confirmed": is_confirmed, "is_applied": is_applied}

static func from_dict(data: Dictionary) -> GrowthEventData:
	var event := GrowthEventData.new()
	event.event_id = str(data.get("event_id", "")); event.growth_mark_id = str(data.get("growth_mark_id", ""))
	event.title = str(data.get("title", "")); event.content = str(data.get("content", ""))
	event.triggered_at = float(data.get("triggered_at", 0.0)); event.is_confirmed = bool(data.get("is_confirmed", false))
	event.is_applied = bool(data.get("is_applied", false))
	return event

static func create_leaf_event() -> GrowthEventData:
	var event := GrowthEventData.new()
	event.event_id = "growth_leaf_mark_001"; event.growth_mark_id = "leaf_mark"
	event.title = "耳朵旁的小葉子"; event.content = "Amy 耳朵旁出現了一片小葉子。"
	event.triggered_at = TimeManager.get_now()
	return event
