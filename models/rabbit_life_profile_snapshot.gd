class_name RabbitLifeProfileSnapshot
extends Resource

@export var snapshot_id := ""
@export var created_at := 0.0
@export var rabbit_name := "Amy"
@export var move_in_date := ""
@export var first_activity := ""
@export var first_journal := ""
@export var first_forest := ""
@export var first_fishing := ""
@export var first_food := ""
@export var first_purchase := ""
@export var first_cooking := ""
@export var first_growth := ""
@export var first_building := ""
@export var cafe_unlock := ""
@export var cafe_complete := ""
@export var final_growth := ""
@export var favorite_location := ""
@export var favorite_food := ""
@export var most_used_activity := ""
@export var current_form := "none"
@export var dominant_tendency := "balanced"
@export var important_memories: Array[Dictionary] = []

func to_dict() -> Dictionary:
	return {
		"snapshot_id": snapshot_id,
		"created_at": created_at,
		"rabbit_name": rabbit_name,
		"name": rabbit_name,
		"move_in_date": move_in_date,
		"first_activity": first_activity,
		"first_journal": first_journal,
		"first_forest": first_forest,
		"first_fishing": first_fishing,
		"first_food": first_food,
		"first_purchase": first_purchase,
		"first_cooking": first_cooking,
		"first_growth": first_growth,
		"first_growth_mark": first_growth,
		"first_building": first_building,
		"cafe_unlock": cafe_unlock,
		"cafe_complete": cafe_complete,
		"final_growth": final_growth,
		"favorite_location": favorite_location,
		"favorite_food": favorite_food,
		"most_used_activity": most_used_activity,
		"current_form": current_form,
		"dominant_tendency": dominant_tendency,
		"important_memories": important_memories.duplicate(true)
	}

static func from_dict(raw: Dictionary) -> RabbitLifeProfileSnapshot:
	var value := RabbitLifeProfileSnapshot.new()
	value.snapshot_id = str(raw.get("snapshot_id", ""))
	value.created_at = maxf(0.0, float(raw.get("created_at", 0.0)))
	value.rabbit_name = str(raw.get("rabbit_name", raw.get("name", "Amy")))
	value.move_in_date = str(raw.get("move_in_date", ""))
	value.first_activity = str(raw.get("first_activity", ""))
	value.first_journal = str(raw.get("first_journal", ""))
	value.first_forest = str(raw.get("first_forest", ""))
	value.first_fishing = str(raw.get("first_fishing", ""))
	value.first_food = str(raw.get("first_food", ""))
	value.first_purchase = str(raw.get("first_purchase", ""))
	value.first_cooking = str(raw.get("first_cooking", ""))
	value.first_growth = str(raw.get("first_growth", raw.get("first_growth_mark", "")))
	value.first_building = str(raw.get("first_building", ""))
	value.cafe_unlock = str(raw.get("cafe_unlock", ""))
	value.cafe_complete = str(raw.get("cafe_complete", ""))
	value.final_growth = str(raw.get("final_growth", ""))
	value.favorite_location = str(raw.get("favorite_location", ""))
	value.favorite_food = str(raw.get("favorite_food", ""))
	value.most_used_activity = str(raw.get("most_used_activity", ""))
	value.current_form = str(raw.get("current_form", "none"))
	value.dominant_tendency = str(raw.get("dominant_tendency", "balanced"))
	for item: Variant in raw.get("important_memories", []):
		if item is Dictionary:
			value.important_memories.append(item.duplicate(true))
	return value
