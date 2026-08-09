class_name VillageConditionData
extends Resource

@export var rewarded_keys: Array[String] = []

func claim_once(key: String) -> bool:
	if key.is_empty() or rewarded_keys.has(key): return false
	rewarded_keys.append(key); return true

func to_dict() -> Dictionary: return {"rewarded_keys": rewarded_keys.duplicate()}

static func from_dict(data: Dictionary) -> VillageConditionData:
	var result := VillageConditionData.new()
	for key: Variant in data.get("rewarded_keys", []): result.rewarded_keys.append(str(key))
	return result
