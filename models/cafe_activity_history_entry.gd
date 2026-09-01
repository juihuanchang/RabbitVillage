class_name CafeActivityHistoryEntry
extends Resource

@export var activity_record_id := ""
@export var cafe_activity_id := ""
@export var started_at := 0.0
@export var completed_at := 0.0
@export var cafe_experience_change := 0
@export var social_experience_change := 0
@export var coin_reward := 0

func to_dict() -> Dictionary:
	return {
		"activity_record_id": activity_record_id,
		"cafe_activity_id": cafe_activity_id,
		"started_at": started_at,
		"completed_at": completed_at,
		"cafe_experience_change": cafe_experience_change,
		"social_experience_change": social_experience_change,
		"coin_reward": coin_reward
	}

static func from_dict(data: Dictionary) -> CafeActivityHistoryEntry:
	var entry := CafeActivityHistoryEntry.new()
	entry.activity_record_id = str(data.get("activity_record_id", ""))
	entry.cafe_activity_id = str(data.get("cafe_activity_id", data.get("activity_id", "")))
	entry.started_at = maxf(0.0, float(data.get("started_at", 0.0)))
	entry.completed_at = maxf(0.0, float(data.get("completed_at", 0.0)))
	entry.cafe_experience_change = maxi(0, int(data.get("cafe_experience_change", data.get("cafe_experience_reward", 0))))
	entry.social_experience_change = maxi(0, int(data.get("social_experience_change", data.get("social_experience_reward", 0))))
	entry.coin_reward = maxi(0, int(data.get("coin_reward", 0)))
	return entry
