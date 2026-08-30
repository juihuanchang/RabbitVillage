class_name ConstructionResult
extends Resource
@export var construction_record_id := ""
@export var building_id := ""
@export var slot_id := ""
@export var started_at := 0.0
@export var completed_at := 0.0
@export var village_experience_reward := 0
@export var is_first_completion := false
@export var reward_applied := false
var construction_id: String: get = get_construction_id
func get_construction_id() -> String: return construction_record_id
func to_dict() -> Dictionary:
	return {"construction_record_id": construction_record_id, "building_id": building_id, "slot_id": slot_id,
		"started_at": started_at, "completed_at": completed_at,
		"village_experience_reward": village_experience_reward, "is_first_completion": is_first_completion, "reward_applied": reward_applied}
