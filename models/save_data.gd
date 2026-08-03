class_name SaveData
extends Resource

const CURRENT_VERSION := 4

var save_version := CURRENT_VERSION
var rabbits: Array[Dictionary] = []
var current_activity: Dictionary = {}
var journals: Array[Dictionary] = []
var completed_activity_ids: Array[String] = []
var last_saved_at := 0.0

# Week 3 persistence.
var forest_experience := 0
var fishing_experience := 0
var intimacy := 0
var forest_activity_count := 0
var fishing_activity_count := 0
var home_activity_count := 0
var total_activity_count := 0
var all_activity_records: Array[Dictionary] = []
var unlocked_growth_marks: Array[Dictionary] = []
var pending_growth_event: Dictionary = {}
var growth_album_entries: Array[Dictionary] = []
var growth_tendencies: Dictionary = {"forest": 0, "lake": 0, "home": 0}

func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"rabbits": rabbits,
		"current_activity": current_activity,
		"journals": journals,
		"completed_activity_ids": completed_activity_ids,
		"last_saved_at": last_saved_at,
		"forest_experience": forest_experience,
		"fishing_experience": fishing_experience,
		"intimacy": intimacy,
		"forest_activity_count": forest_activity_count,
		"fishing_activity_count": fishing_activity_count,
		"home_activity_count": home_activity_count,
		"total_activity_count": total_activity_count,
		"all_activity_records": all_activity_records,
		"unlocked_growth_marks": unlocked_growth_marks,
		"pending_growth_event": pending_growth_event,
		"growth_album_entries": growth_album_entries,
		"growth_tendencies": growth_tendencies
	}

static func from_dict(data: Dictionary) -> SaveData:
	var result := SaveData.new()
	result.save_version = int(data.get("save_version", data.get("version", 1)))
	for item: Variant in data.get("rabbits", []):
		if item is Dictionary:
			result.rabbits.append(item)
	if data.get("current_activity", {}) is Dictionary:
		result.current_activity = data.get("current_activity", {})
	for item: Variant in data.get("journals", []):
		if item is Dictionary:
			result.journals.append(item)
	for item: Variant in data.get("completed_activity_ids", []):
		result.completed_activity_ids.append(str(item))
	result.last_saved_at = float(data.get("last_saved_at", 0.0))

	result.forest_experience = int(data.get("forest_experience", 0))
	result.fishing_experience = int(data.get("fishing_experience", 0))
	result.intimacy = int(data.get("intimacy", 0))
	result.forest_activity_count = int(data.get("forest_activity_count", 0))
	result.fishing_activity_count = int(data.get("fishing_activity_count", 0))
	result.home_activity_count = int(data.get("home_activity_count", 0))
	result.total_activity_count = int(data.get("total_activity_count", 0))
	for item: Variant in data.get("all_activity_records", []):
		if item is Dictionary:
			result.all_activity_records.append(item)
	for item: Variant in data.get("unlocked_growth_marks", []):
		if item is Dictionary:
			result.unlocked_growth_marks.append(item.duplicate(true))
		else:
			result.unlocked_growth_marks.append({"id": str(item), "is_unlocked": true, "unlocked_at": 0.0})
	if data.get("pending_growth_event", {}) is Dictionary:
		result.pending_growth_event = data.get("pending_growth_event", {}).duplicate(true)
	for item: Variant in data.get("growth_album_entries", []):
		if item is Dictionary:
			result.growth_album_entries.append(item)
	var tendencies: Variant = data.get("growth_tendencies", {})
	if tendencies is Dictionary:
		result.growth_tendencies = {
			"forest": int(tendencies.get("forest", 0)),
			"lake": int(tendencies.get("lake", 0)),
			"home": int(tendencies.get("home", 0))
		}
	return result

func is_supported_version() -> bool:
	return save_version >= 1 and save_version <= CURRENT_VERSION
