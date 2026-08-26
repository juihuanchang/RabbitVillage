class_name CookingHistoryEntry
extends Resource

var cooking_record_id := ""
var recipe_id := ""
var ingredients: Dictionary = {}
var result_item := ""
var result_amount := 0
var cooked_at := 0.0

func to_dict() -> Dictionary:
	return {
		"cooking_record_id": cooking_record_id,
		"recipe_id": recipe_id,
		"ingredients": ingredients.duplicate(true),
		"result_item": result_item,
		"result_amount": result_amount,
		"cooked_at": cooked_at
	}

static func from_dict(data: Dictionary) -> CookingHistoryEntry:
	var entry := CookingHistoryEntry.new()
	entry.cooking_record_id = str(data.get("cooking_record_id", ""))
	entry.recipe_id = str(data.get("recipe_id", ""))
	if data.get("ingredients", {}) is Dictionary:
		entry.ingredients = data.get("ingredients", {}).duplicate(true)
	entry.result_item = str(data.get("result_item", data.get("result_item_id", "")))
	entry.result_amount = maxi(0, int(data.get("result_amount", 0)))
	entry.cooked_at = maxf(0.0, float(data.get("cooked_at", 0.0)))
	return entry
