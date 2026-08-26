class_name FoodUseHistoryEntry
extends Resource

var food_use_record_id := ""
var food_id := ""
var used_at := 0.0
var amount_used := 0
var hunger_before := 0
var hunger_after := 0
var energy_change := 0
var mood_change := 0
var is_first_use := false

func to_dict() -> Dictionary:
	return {
		"food_use_record_id": food_use_record_id,
		"food_id": food_id,
		"used_at": used_at,
		"amount_used": amount_used,
		"hunger_before": hunger_before,
		"hunger_after": hunger_after,
		"energy_change": energy_change,
		"mood_change": mood_change,
		"is_first_use": is_first_use
	}

static func from_dict(data: Dictionary) -> FoodUseHistoryEntry:
	var entry := FoodUseHistoryEntry.new()
	entry.food_use_record_id = str(data.get("food_use_record_id", ""))
	entry.food_id = str(data.get("food_id", ""))
	entry.used_at = maxf(0.0, float(data.get("used_at", 0.0)))
	entry.amount_used = maxi(0, int(data.get("amount_used", 0)))
	entry.hunger_before = clampi(int(data.get("hunger_before", 0)), 0, 100)
	entry.hunger_after = clampi(int(data.get("hunger_after", 0)), 0, 100)
	entry.energy_change = int(data.get("energy_change", 0))
	entry.mood_change = int(data.get("mood_change", 0))
	entry.is_first_use = bool(data.get("is_first_use", false))
	return entry
