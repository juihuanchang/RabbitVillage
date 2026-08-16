class_name FoodUseResult
extends Resource

var food_use_record_id := ""
var food_id := ""
var used_at := 0.0
var amount_used := 0
var hunger_before := 0
var hunger_change := 0
var hunger_after := 0
var is_first_use := false

func to_dict() -> Dictionary:
	return {
		"food_use_record_id": food_use_record_id, "food_id": food_id, "used_at": used_at,
		"amount_used": amount_used, "hunger_before": hunger_before, "hunger_change": hunger_change,
		"hunger_after": hunger_after, "is_first_use": is_first_use
	}

static func from_dict(data: Dictionary) -> FoodUseResult:
	var result := FoodUseResult.new()
	result.food_use_record_id = str(data.get("food_use_record_id", ""))
	result.food_id = str(data.get("food_id", "")); result.used_at = float(data.get("used_at", 0.0))
	result.amount_used = int(data.get("amount_used", 0)); result.hunger_before = int(data.get("hunger_before", 0))
	result.hunger_change = int(data.get("hunger_change", 0)); result.hunger_after = int(data.get("hunger_after", 0))
	result.is_first_use = bool(data.get("is_first_use", false)); return result
