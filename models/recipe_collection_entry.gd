class_name RecipeCollectionEntry
extends Resource

var recipe_id := ""
var is_discovered := false
var first_cooked_at := 0.0
var first_source_type := ""
var first_source_id := ""
var total_cook_count := 0

func to_dict() -> Dictionary:
	return {
		"recipe_id": recipe_id,
		"is_discovered": is_discovered,
		"first_cooked_at": first_cooked_at,
		"first_source_type": first_source_type,
		"first_source_id": first_source_id,
		"total_cook_count": total_cook_count
	}

static func from_dict(data: Dictionary) -> RecipeCollectionEntry:
	var entry := RecipeCollectionEntry.new()
	entry.recipe_id = str(data.get("recipe_id", ""))
	entry.is_discovered = bool(data.get("is_discovered", false))
	entry.first_cooked_at = maxf(0.0, float(data.get("first_cooked_at", 0.0)))
	entry.first_source_type = str(data.get("first_source_type", ""))
	entry.first_source_id = str(data.get("first_source_id", ""))
	entry.total_cook_count = maxi(0, int(data.get("total_cook_count", 0)))
	return entry
