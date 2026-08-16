class_name LifeEventResult
extends Resource

var event_id := ""
var confirmed_at := 0.0
var is_applied := false

func to_dict() -> Dictionary:
	return {"event_id": event_id, "confirmed_at": confirmed_at, "is_applied": is_applied}
