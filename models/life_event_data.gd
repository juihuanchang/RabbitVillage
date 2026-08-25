class_name LifeEventData
extends Resource

var event_id := ""
var display_name := ""
var item_id := ""
var required_total_obtained := 0
var state := LifeEventState.LOCKED
var triggered_at := 0.0
var confirmed_at := 0.0

func to_dict() -> Dictionary:
	return {"event_id": event_id, "display_name": display_name, "item_id": item_id, "required_total_obtained": required_total_obtained,
		"state": state, "triggered_at": triggered_at, "confirmed_at": confirmed_at}
