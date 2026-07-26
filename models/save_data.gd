class_name SaveData
extends Resource

const CURRENT_VERSION := 2
var save_version := CURRENT_VERSION
var rabbits: Array[Dictionary] = []
var current_activity: Dictionary = {}
var journals: Array[Dictionary] = []
var completed_activity_ids: Array[String] = []
var last_saved_at := 0.0

func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"rabbits": rabbits,
		"current_activity": current_activity,
		"journals": journals,
		"completed_activity_ids": completed_activity_ids,
		"last_saved_at": last_saved_at
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
	return result

func is_supported_version() -> bool:
	return save_version >= 1 and save_version <= CURRENT_VERSION
