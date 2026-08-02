class_name ActiveActivityData
extends Resource

@export var activity_record_id: String = ""
@export var rabbit: RabbitData
@export var activity: ActivityData
@export var started_at: float = 0.0
@export var ends_at: float = 0.0
@export var is_completed: bool = false
@export var completed_at: float = 0.0

func _init(
		initial_rabbit: RabbitData = null,
		initial_activity: ActivityData = null,
		initial_started_at: float = 0.0,
		initial_record_id: String = "",
		initial_ends_at: float = -1.0,
		initial_is_completed: bool = false,
		initial_completed_at: float = 0.0
) -> void:
	rabbit = initial_rabbit
	activity = initial_activity
	started_at = initial_started_at
	activity_record_id = initial_record_id if not initial_record_id.is_empty() else _generate_record_id()
	ends_at = initial_ends_at if initial_ends_at >= 0.0 else started_at + (activity.duration_seconds if activity else 0.0)
	is_completed = initial_is_completed
	completed_at = initial_completed_at

func get_remaining_seconds(now: float = -1.0) -> float:
	if is_completed:
		return 0.0
	var check_time := TimeManager.get_now() if now < 0.0 else now
	return maxf(ends_at - check_time, 0.0)

func mark_completed(at_time: float = -1.0) -> void:
	is_completed = true
	completed_at = TimeManager.get_now() if at_time < 0.0 else at_time

func get_completion_data() -> Dictionary:
	return {
		"activity_record_id": activity_record_id,
		"activity_id": activity.activity_id if activity else "",
		"location_id": activity.location_id if activity else "",
		"activity_name": activity.activity_name if activity else "",
		"started_at": started_at,
		"completed_at": completed_at,
		"energy_change": activity.energy_change if activity else 0,
		"hunger_change": activity.hunger_change if activity else 0,
		"mood_change": activity.mood_change if activity else 0,
		"forest_experience_change": activity.forest_experience_change if activity else 0,
		"fishing_experience_change": activity.fishing_experience_change if activity else 0,
		"intimacy_change": activity.intimacy_change if activity else 0,
		"activity_completion_count": 1,
		"reward_items": []
	}

func to_dict() -> Dictionary:
	return {
		"activity_record_id": activity_record_id,
		"rabbit_name": rabbit.rabbit_name if rabbit else "",
		"activity": activity.to_dict() if activity else {},
		"started_at": started_at,
		"ends_at": ends_at,
		"is_completed": is_completed,
		"completed_at": completed_at
	}

static func from_dict(data: Dictionary, restored_rabbit: RabbitData) -> ActiveActivityData:
	if restored_rabbit == null or not (data.get("activity", {}) is Dictionary):
		return null
	var restored_activity := ActivityData.from_dict(data.get("activity", {}))
	if restored_activity.activity_id.is_empty():
		return null
	return ActiveActivityData.new(
		restored_rabbit,
		restored_activity,
		float(data.get("started_at", 0.0)),
		str(data.get("activity_record_id", "")),
		float(data.get("ends_at", 0.0)),
		bool(data.get("is_completed", false)),
		float(data.get("completed_at", 0.0))
	)

static func _generate_record_id() -> String:
	var timestamp_microseconds := int(Time.get_unix_time_from_system() * 1000000.0)
	return "activity_%d_%d" % [timestamp_microseconds, randi_range(1000, 9999)]
