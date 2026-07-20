class_name ActiveActivityData
extends Resource

@export var rabbit: RabbitData
@export var activity: ActivityData
@export var started_at: float = 0.0
@export var ends_at: float = 0.0


func _init(
		initial_rabbit: RabbitData = null,
		initial_activity: ActivityData = null,
		initial_started_at: float = 0.0
) -> void:
	rabbit = initial_rabbit
	activity = initial_activity
	started_at = initial_started_at
	if activity != null:
		ends_at = started_at + activity.duration_seconds


func get_remaining_seconds(now: float) -> float:
	return maxf(ends_at - now, 0.0)
