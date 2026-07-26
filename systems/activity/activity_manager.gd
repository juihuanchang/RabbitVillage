class_name ActivityManager
extends Node

signal activity_started(active_activity: ActiveActivityData)
signal countdown_changed(active_activity: ActiveActivityData, remaining_seconds: float)
signal activity_completed(active_activity: ActiveActivityData)
signal activity_completed_data(completion_data: Dictionary)
signal rabbit_returned(rabbit: RabbitData)

const ERROR_ACTIVITY_IN_PROGRESS := "活動進行中"
const ERROR_ENERGY_NOT_ENOUGH := "體力不足"
const ERROR_ACTIVITY_NOT_FOUND := "找不到活動"
const ERROR_RABBIT_NOT_READY := "Amy 資料尚未準備完成"

var active_activity: ActiveActivityData = null
var last_error: String = ""
var _rabbit: RabbitData
var _activities: Dictionary = {}

func _init() -> void:
	register_activity(ActivityData.create_forest_walk())
	register_activity(ActivityData.create_fishing())

func setup(rabbit: RabbitData) -> void:
	_rabbit = rabbit

func register_activity(activity: ActivityData) -> bool:
	if activity == null or activity.activity_id.is_empty():
		return false
	_activities[activity.activity_id] = activity
	return true

func get_activity(activity_id: String) -> ActivityData:
	return _activities.get(activity_id.strip_edges().to_lower()) as ActivityData

func get_all_activities() -> Array[ActivityData]:
	var result: Array[ActivityData] = []
	result.assign(_activities.values())
	return result

func can_start_activity(activity_id: String) -> Dictionary:
	var activity := get_activity(activity_id)
	if activity == null:
		return {"ok": false, "reason": ERROR_ACTIVITY_NOT_FOUND}
	if _rabbit == null:
		return {"ok": false, "reason": ERROR_RABBIT_NOT_READY}
	if active_activity != null or _rabbit.is_away or not _rabbit.current_activity.is_empty():
		return {"ok": false, "reason": ERROR_ACTIVITY_IN_PROGRESS}
	if _rabbit.energy < activity.energy_cost:
		return {"ok": false, "reason": ERROR_ENERGY_NOT_ENOUGH}
	return {"ok": true, "reason": ""}

# Generic entry point. Returns a result A can display directly.
func start_activity(activity_id: String) -> Dictionary:
	var check := can_start_activity(activity_id)
	last_error = str(check.reason)
	if not check.ok:
		return check
	var activity := get_activity(activity_id)
	var now := TimeManager.get_now()
	active_activity = ActiveActivityData.new(_rabbit, activity, now)
	_rabbit.is_away = true
	_rabbit.current_activity = activity.activity_id
	activity_started.emit(active_activity)
	countdown_changed.emit(active_activity, active_activity.get_remaining_seconds(now))
	return {"ok": true, "reason": "", "active_activity": active_activity}

func has_active_activity() -> bool:
	return active_activity != null and not active_activity.is_completed

func get_current_activity() -> ActiveActivityData:
	return active_activity

func get_remaining_seconds() -> float:
	return active_activity.get_remaining_seconds() if active_activity else 0.0

func get_end_time() -> float:
	return active_activity.ends_at if active_activity else 0.0

func is_rabbit_away() -> bool:
	return _rabbit != null and _rabbit.is_away

func get_rabbit_data() -> RabbitData:
	return _rabbit

func restore_activity(restored: ActiveActivityData) -> void:
	active_activity = restored
	if restored != null:
		_rabbit = restored.rabbit
		_rabbit.is_away = not restored.is_completed
		_rabbit.current_activity = restored.activity.activity_id if not restored.is_completed else ""

func _process(_delta: float) -> void:
	if not has_active_activity():
		return
	var now := TimeManager.get_now()
	countdown_changed.emit(active_activity, active_activity.get_remaining_seconds(now))
	if now >= active_activity.ends_at:
		_complete_activity(now)

func check_for_completion() -> bool:
	if not has_active_activity() or TimeManager.get_now() < active_activity.ends_at:
		return false
	_complete_activity(TimeManager.get_now())
	return true

func _complete_activity(completed_time: float) -> void:
	if active_activity == null or active_activity.is_completed:
		return
	var completed := active_activity
	completed.mark_completed(completed_time)
	completed.rabbit.energy -= completed.activity.energy_cost
	completed.rabbit.hunger += completed.activity.hunger_change
	completed.rabbit.mood += completed.activity.mood_reward
	completed.rabbit.is_away = false
	completed.rabbit.current_activity = ""
	activity_completed.emit(completed)
	activity_completed_data.emit(completed.get_completion_data())
	active_activity = null
	rabbit_returned.emit(completed.rabbit)

# PascalCase aliases matching the agreed A/B API.
func StartActivity(activity_id: String) -> Dictionary: return start_activity(activity_id)
func HasActiveActivity() -> bool: return has_active_activity()
func GetCurrentActivity() -> ActiveActivityData: return get_current_activity()
func GetRemainingSeconds() -> float: return get_remaining_seconds()
func GetEndTime() -> float: return get_end_time()
func IsRabbitAway() -> bool: return is_rabbit_away()
func GetRabbitData() -> RabbitData: return get_rabbit_data()
