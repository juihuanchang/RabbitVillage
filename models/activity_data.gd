class_name ActivityData
extends Resource

@export var activity_id: String = ""
@export var activity_name: String = ""
@export_range(0.1, 86400.0, 0.1, "suffix:s") var duration_seconds: float = 30.0
@export_range(0, 100) var energy_cost: int = 0
@export var hunger_change: int = 0
@export var mood_reward: int = 0

# Compatibility properties used by the existing journal/UI integration.
var energy_change: int:
	get: return -energy_cost
var mood_change: int:
	get: return mood_reward

func _init(
		initial_id: String = "",
		initial_name: String = "",
		initial_duration_seconds: float = 30.0,
		initial_energy_cost: int = 0,
		initial_hunger_change: int = 0,
		initial_mood_reward: int = 0
) -> void:
	activity_id = initial_id.strip_edges().to_lower()
	activity_name = initial_name.strip_edges()
	duration_seconds = maxf(initial_duration_seconds, 0.1)
	energy_cost = maxi(initial_energy_cost, 0)
	hunger_change = initial_hunger_change
	mood_reward = initial_mood_reward

static func create_forest_walk() -> ActivityData:
	return ActivityData.new("forest_walk", "森林散步", 30.0, 5, -3, 3)

static func create_fishing() -> ActivityData:
	return ActivityData.new("fishing", "池邊釣魚", 45.0, 4, -2, 4)

func to_dict() -> Dictionary:
	return {
		"activity_id": activity_id,
		"activity_name": activity_name,
		"duration_seconds": duration_seconds,
		"energy_cost": energy_cost,
		"hunger_change": hunger_change,
		"mood_reward": mood_reward
	}

static func from_dict(data: Dictionary) -> ActivityData:
	var cost := int(data.get("energy_cost", maxi(0, -int(data.get("energy_change", 0)))))
	var reward := int(data.get("mood_reward", data.get("mood_change", 0)))
	return ActivityData.new(
		str(data.get("activity_id", "")),
		str(data.get("activity_name", "")),
		float(data.get("duration_seconds", 30.0)),
		cost,
		int(data.get("hunger_change", 0)),
		reward
	)
