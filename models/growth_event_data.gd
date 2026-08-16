class_name GrowthEventData
extends Resource

var event_id := ""
var growth_mark_id := ""
var title := ""
var content := ""
var triggered_at := 0.0
var is_confirmed := false
var is_applied := false

func to_dict() -> Dictionary:
	return {"event_id": event_id, "growth_mark_id": growth_mark_id, "title": title, "content": content,
		"triggered_at": triggered_at, "is_confirmed": is_confirmed, "is_applied": is_applied}

static func from_dict(data: Dictionary) -> GrowthEventData:
	var event := GrowthEventData.new(); event.event_id = str(data.get("event_id", ""))
	event.growth_mark_id = str(data.get("growth_mark_id", "")); event.title = str(data.get("title", ""))
	event.content = str(data.get("content", "")); event.triggered_at = float(data.get("triggered_at", 0.0))
	event.is_confirmed = bool(data.get("is_confirmed", false)); event.is_applied = bool(data.get("is_applied", false)); return event

static func create(event_id: String, mark_id: String) -> GrowthEventData:
	var event := GrowthEventData.new(); event.event_id = event_id; event.growth_mark_id = mark_id
	event.triggered_at = TimeManager.get_now(); return event

static func create_leaf_event() -> GrowthEventData: return create("growth_leaf_mark_001", "leaf_mark")
