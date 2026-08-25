class_name LifeLocationResult
extends Resource

var location_record_id := ""
var location_id := ""
var activity_id := ""
var food_use_record_id := ""
var completed_at := 0.0
var energy_change := 0
var mood_change := 0
var intimacy_change := 0
var success := false
var reason := ""

func to_dict() -> Dictionary:
	return {"location_record_id": location_record_id, "location_id": location_id, "activity_id": activity_id,
		"food_use_record_id": food_use_record_id, "completed_at": completed_at, "energy_change": energy_change,
		"mood_change": mood_change, "intimacy_change": intimacy_change, "success": success, "reason": reason}
