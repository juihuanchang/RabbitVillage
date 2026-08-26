class_name FoodVarietyRecord
extends Resource

var food_id := ""
var first_used_at := 0.0
var last_used_at := 0.0
var use_count := 0

func to_dict() -> Dictionary:
	return {"food_id": food_id, "first_used_at": first_used_at, "last_used_at": last_used_at, "use_count": use_count}

static func from_dict(data: Dictionary) -> FoodVarietyRecord:
	var entry := FoodVarietyRecord.new()
	entry.food_id = str(data.get("food_id", ""))
	entry.first_used_at = maxf(0.0, float(data.get("first_used_at", 0.0)))
	entry.last_used_at = maxf(entry.first_used_at, float(data.get("last_used_at", entry.first_used_at)))
	entry.use_count = maxi(0, int(data.get("use_count", 0)))
	return entry
