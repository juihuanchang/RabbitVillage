class_name FoodUseResult
extends Resource

var food_use_record_id := ""
var food_id := ""
var used_at := 0.0
var amount_used := 0
var hunger_before := 0
var hunger_change := 0
var hunger_after := 0
var energy_before := 0
var energy_change := 0
var energy_after := 0
var mood_before := 0
var mood_change := 0
var mood_after := 0
var is_first_use := false

func to_dict() -> Dictionary:
	return {
		"food_use_record_id": food_use_record_id, "food_id": food_id, "used_at": used_at,
		"amount_used": amount_used, "hunger_before": hunger_before, "hunger_change": hunger_change,
		"hunger_after": hunger_after, "energy_before": energy_before, "energy_change": energy_change,
		"energy_after": energy_after, "mood_before": mood_before, "mood_change": mood_change,
		"mood_after": mood_after, "is_first_use": is_first_use
	}

static func from_dict(data: Dictionary) -> FoodUseResult:
	var result := FoodUseResult.new()
	result.food_use_record_id = str(data.get("food_use_record_id", ""))
	result.food_id = str(data.get("food_id", "")); result.used_at = float(data.get("used_at", 0.0))
	result.amount_used = int(data.get("amount_used", 0)); result.hunger_before = int(data.get("hunger_before", 0))
	result.hunger_change = int(data.get("hunger_change", 0)); result.hunger_after = int(data.get("hunger_after", 0))
	result.energy_before = int(data.get("energy_before", 0)); result.energy_change = int(data.get("energy_change", 0))
	result.energy_after = int(data.get("energy_after", result.energy_before + result.energy_change))
	result.mood_before = int(data.get("mood_before", 0)); result.mood_change = int(data.get("mood_change", 0))
	result.mood_after = int(data.get("mood_after", result.mood_before + result.mood_change))
	result.is_first_use = bool(data.get("is_first_use", false)); return result
