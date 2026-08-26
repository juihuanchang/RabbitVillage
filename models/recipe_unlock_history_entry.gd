class_name RecipeUnlockHistoryEntry
extends Resource

var recipe_id := ""
var unlocked_at := 0.0
var source_type := ""
var source_id := ""

func to_dict() -> Dictionary:
	return {"recipe_id": recipe_id, "unlocked_at": unlocked_at, "source_type": source_type, "source_id": source_id}

static func from_dict(data: Dictionary) -> RecipeUnlockHistoryEntry:
	var entry := RecipeUnlockHistoryEntry.new()
	entry.recipe_id = str(data.get("recipe_id", ""))
	entry.unlocked_at = maxf(0.0, float(data.get("unlocked_at", 0.0)))
	entry.source_type = str(data.get("source_type", ""))
	entry.source_id = str(data.get("source_id", ""))
	return entry
