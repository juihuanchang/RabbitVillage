class_name ActivityData
extends Resource

@export var activity_name: String = ""
@export_range(0.1, 86400.0, 0.1, "suffix:s") var duration_seconds: float = 30.0
@export var energy_change: int = 0
@export var mood_change: int = 0


func _init(
		initial_name: String = "",
		initial_duration_seconds: float = 30.0,
		initial_energy_change: int = 0,
		initial_mood_change: int = 0
) -> void:
	activity_name = initial_name.strip_edges()
	duration_seconds = maxf(initial_duration_seconds, 0.1)
	energy_change = initial_energy_change
	mood_change = initial_mood_change


static func create_forest_walk() -> ActivityData:
	return ActivityData.new("森林散步", 30.0, -5, 3)
