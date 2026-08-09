class_name BuildingData
extends Resource

@export var building_id := ""
@export var display_name := ""
@export var description := ""
@export var construction_seconds := 30.0
@export var village_experience_reward := 20
@export var is_unlocked := false

static func create(id: String, name: String, seconds: float, reward: int, unlocked := false) -> BuildingData:
	var b := BuildingData.new(); b.building_id = id; b.display_name = name
	b.construction_seconds = seconds; b.village_experience_reward = reward; b.is_unlocked = unlocked
	return b

func to_dict() -> Dictionary:
	return {"building_id": building_id, "display_name": display_name, "description": description,
		"construction_seconds": construction_seconds, "village_experience_reward": village_experience_reward,
		"is_unlocked": is_unlocked}
