class_name ActivityData
extends Resource

const TYPE_OUTDOOR := "outdoor"
const TYPE_HOME := "home"

@export var activity_id: String = ""
@export var location_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(0.1, 86400.0, 0.1, "suffix:s") var duration_seconds: float = 30.0
@export var energy_change: int = 0
@export var hunger_change: int = 0
@export var mood_change: int = 0
@export var forest_experience_change: int = 0
@export var fishing_experience_change: int = 0
@export var intimacy_change: int = 0
@export_range(0, 100) var required_energy: int = 0
@export var is_unlocked: bool = true
@export_enum("outdoor", "home") var activity_type: String = TYPE_OUTDOOR

# Week-two compatibility properties.
var activity_name: String:
	get: return display_name
	set(value): display_name = value
var energy_cost: int:
	get: return maxi(0, -energy_change)
var mood_reward: int:
	get: return mood_change

func _init(
	initial_id: String = "", initial_location_id: String = "",
	initial_name: String = "", initial_description: String = "",
	initial_duration_seconds: float = 30.0, initial_energy_change: int = 0,
	initial_hunger_change: int = 0, initial_mood_change: int = 0,
	initial_forest_experience_change: int = 0,
	initial_fishing_experience_change: int = 0,
	initial_intimacy_change: int = 0, initial_required_energy: int = 0,
	initial_is_unlocked: bool = true, initial_activity_type: String = TYPE_OUTDOOR
) -> void:
	activity_id = initial_id.strip_edges().to_lower()
	location_id = initial_location_id.strip_edges().to_lower()
	display_name = initial_name.strip_edges()
	description = initial_description
	duration_seconds = maxf(initial_duration_seconds, 0.1)
	energy_change = initial_energy_change
	hunger_change = initial_hunger_change
	mood_change = initial_mood_change
	forest_experience_change = initial_forest_experience_change
	fishing_experience_change = initial_fishing_experience_change
	intimacy_change = initial_intimacy_change
	required_energy = clampi(initial_required_energy, 0, 100)
	is_unlocked = initial_is_unlocked
	activity_type = initial_activity_type

static func create_forest_walk() -> ActivityData:
	return ActivityData.new("forest_walk", "forest", "森林散步", "和 Amy 在森林裡散步。", 30.0, -5, -3, 3, 10, 0, 1, 5)

static func create_forest_explore() -> ActivityData:
	return ActivityData.new("forest_explore", "forest", "森林探索", "和 Amy 深入森林探索。", 60.0, -12, -6, 5, 18, 0, 1, 12)

static func create_fishing() -> ActivityData:
	return ActivityData.new("fishing", "lake", "湖邊釣魚", "和 Amy 一起在湖邊釣魚。", 45.0, -4, -2, 4, 0, 10, 1, 4)

static func create_home_rest() -> ActivityData:
	return ActivityData.new("home_rest", "home", "在家休息", "讓 Amy 在家好好休息。", 30.0, 15, -2, 2, 0, 0, 1, 0, true, TYPE_HOME)

func to_dict() -> Dictionary:
	return {
		"activity_id": activity_id, "location_id": location_id,
		"display_name": display_name, "activity_name": display_name,
		"description": description, "duration_seconds": duration_seconds,
		"energy_change": energy_change, "hunger_change": hunger_change,
		"mood_change": mood_change,
		"forest_experience_change": forest_experience_change,
		"fishing_experience_change": fishing_experience_change,
		"intimacy_change": intimacy_change, "required_energy": required_energy,
		"is_unlocked": is_unlocked, "activity_type": activity_type
	}

static func from_dict(data: Dictionary) -> ActivityData:
	var legacy_energy := -int(data.get("energy_cost", 0))
	return ActivityData.new(
		str(data.get("activity_id", "")), str(data.get("location_id", "")),
		str(data.get("display_name", data.get("activity_name", ""))),
		str(data.get("description", "")), float(data.get("duration_seconds", 30.0)),
		int(data.get("energy_change", legacy_energy)), int(data.get("hunger_change", 0)),
		int(data.get("mood_change", data.get("mood_reward", 0))),
		int(data.get("forest_experience_change", 0)), int(data.get("fishing_experience_change", 0)),
		int(data.get("intimacy_change", 0)),
		int(data.get("required_energy", data.get("energy_cost", 0))),
		bool(data.get("is_unlocked", true)), str(data.get("activity_type", TYPE_OUTDOOR))
	)
