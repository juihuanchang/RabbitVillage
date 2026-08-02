class_name ActivityManager
extends Node

signal activity_started(active_activity: ActiveActivityData)
signal countdown_changed(active_activity: ActiveActivityData, remaining_seconds: float)
signal activity_completed(active_activity: ActiveActivityData)
signal activity_completed_data(completion_data: Dictionary)
signal rabbit_returned(rabbit: RabbitData)

const ERROR_ACTIVITY_IN_PROGRESS := "活動進行中"
const ERROR_ACTIVITY_NOT_FOUND := "找不到活動"
const ERROR_ACTIVITY_LOCKED := "活動尚未解鎖"
const ERROR_ENERGY_NOT_ENOUGH := "體力不足"
const ERROR_TOO_HUNGRY := "Amy 太餓了"
const ERROR_INVALID_LOCATION := "地點資料錯誤"
const ERROR_RABBIT_NOT_READY := "Amy 資料尚未準備完成"
const MIN_HUNGER_TO_START := 10
const VALID_LOCATIONS := ["home", "forest", "lake"]

var active_activity: ActiveActivityData = null
var last_error := ""
var _rabbit: RabbitData
var _activities: Dictionary = {}
var _completed_record_ids: Dictionary = {}

func _init() -> void:
	register_activity(ActivityData.create_forest_walk())
	register_activity(ActivityData.create_forest_explore())
	register_activity(ActivityData.create_fishing())
	register_activity(ActivityData.create_home_rest())

func setup(rabbit: RabbitData) -> void: _rabbit = rabbit

func register_activity(activity: ActivityData) -> bool:
	if activity == null or activity.activity_id.is_empty(): return false
	_activities[activity.activity_id] = activity
	return true

func get_activity(activity_id: String) -> ActivityData:
	return _activities.get(activity_id.strip_edges().to_lower()) as ActivityData

func get_activity_data(activity_id: String) -> ActivityData: return get_activity(activity_id)

func get_all_activities() -> Array[ActivityData]:
	var result: Array[ActivityData] = []; result.assign(_activities.values()); return result

func get_activities_by_location(location_id: String) -> Array[ActivityData]:
	var result: Array[ActivityData] = []
	for activity: ActivityData in _activities.values():
		if activity.location_id == location_id.strip_edges().to_lower(): result.append(activity)
	return result

func can_start_activity(activity_id: String) -> Dictionary:
	if active_activity != null or (_rabbit != null and not _rabbit.current_activity.is_empty()):
		return {"ok": false, "reason": ERROR_ACTIVITY_IN_PROGRESS}
	var activity := get_activity(activity_id)
	if activity == null: return {"ok": false, "reason": ERROR_ACTIVITY_NOT_FOUND}
	if not activity.is_unlocked: return {"ok": false, "reason": ERROR_ACTIVITY_LOCKED}
	if not VALID_LOCATIONS.has(activity.location_id): return {"ok": false, "reason": ERROR_INVALID_LOCATION}
	if _rabbit == null: return {"ok": false, "reason": ERROR_RABBIT_NOT_READY}
	if _rabbit.energy < activity.required_energy: return {"ok": false, "reason": ERROR_ENERGY_NOT_ENOUGH}
	if _rabbit.hunger < MIN_HUNGER_TO_START: return {"ok": false, "reason": ERROR_TOO_HUNGRY}
	return {"ok": true, "reason": ""}

func start_activity(activity_id: String) -> Dictionary:
	var check := can_start_activity(activity_id); last_error = str(check.reason)
	if not check.ok: return check
	var activity := get_activity(activity_id); var now := TimeManager.get_now()
	active_activity = ActiveActivityData.new(_rabbit, activity, now)
	_rabbit.is_away = activity.activity_type == ActivityData.TYPE_OUTDOOR
	_rabbit.current_activity = activity.activity_id
	_rabbit.current_state = "休息中" if activity.activity_type == ActivityData.TYPE_HOME else "活動中"
	activity_started.emit(active_activity)
	countdown_changed.emit(active_activity, active_activity.get_remaining_seconds(now))
	return {"ok": true, "reason": "", "active_activity": active_activity}

func has_active_activity() -> bool: return active_activity != null and not active_activity.is_completed
func get_current_activity() -> ActiveActivityData: return active_activity
func get_remaining_seconds() -> float: return active_activity.get_remaining_seconds() if active_activity else 0.0
func get_end_time() -> float: return active_activity.ends_at if active_activity else 0.0
func is_rabbit_away() -> bool: return _rabbit != null and _rabbit.is_away
func get_rabbit_data() -> RabbitData: return _rabbit

func restore_activity(restored: ActiveActivityData) -> void:
	active_activity = restored
	if restored != null:
		_rabbit = restored.rabbit
		var running := not restored.is_completed
		_rabbit.is_away = running and restored.activity.activity_type == ActivityData.TYPE_OUTDOOR
		_rabbit.current_activity = restored.activity.activity_id if running else ""
		_rabbit.current_state = ("休息中" if restored.activity.activity_type == ActivityData.TYPE_HOME else "活動中") if running else ""

func set_completed_record_ids(record_ids: Array[String]) -> void:
	_completed_record_ids.clear()
	for record_id in record_ids: _completed_record_ids[record_id] = true

func get_completed_record_ids() -> Array[String]:
	var result: Array[String] = []; result.assign(_completed_record_ids.keys()); return result

func _process(_delta: float) -> void:
	if not has_active_activity(): return
	var now := TimeManager.get_now()
	countdown_changed.emit(active_activity, active_activity.get_remaining_seconds(now))
	if now >= active_activity.ends_at: _complete_activity(now)

func check_for_completion() -> bool:
	if not has_active_activity() or TimeManager.get_now() < active_activity.ends_at: return false
	_complete_activity(TimeManager.get_now()); return true

func _complete_activity(completed_time: float) -> void:
	if active_activity == null or active_activity.is_completed: return
	var completed := active_activity
	if _completed_record_ids.has(completed.activity_record_id):
		active_activity = null
		return
	_completed_record_ids[completed.activity_record_id] = true
	completed.mark_completed(completed_time)
	var rabbit := completed.rabbit; var activity := completed.activity
	rabbit.energy += activity.energy_change; rabbit.hunger += activity.hunger_change; rabbit.mood += activity.mood_change
	rabbit.forest_experience += activity.forest_experience_change
	rabbit.fishing_experience += activity.fishing_experience_change
	rabbit.intimacy += activity.intimacy_change
	match activity.location_id:
		"forest": rabbit.forest_activity_count += 1
		"lake": rabbit.fishing_activity_count += 1
		"home": rabbit.home_activity_count += 1
	rabbit.total_activity_count += 1
	rabbit.is_away = false; rabbit.current_activity = ""; rabbit.current_state = ""
	activity_completed.emit(completed); activity_completed_data.emit(completed.get_completion_data())
	active_activity = null; rabbit_returned.emit(rabbit)

func StartActivity(activity_id: String) -> Dictionary: return start_activity(activity_id)
func HasActiveActivity() -> bool: return has_active_activity()
func GetCurrentActivity() -> ActiveActivityData: return get_current_activity()
func GetRemainingSeconds() -> float: return get_remaining_seconds()
func GetEndTime() -> float: return get_end_time()
func IsRabbitAway() -> bool: return is_rabbit_away()
func GetRabbitData() -> RabbitData: return get_rabbit_data()
func GetActivitiesByLocation(location_id: String) -> Array[ActivityData]: return get_activities_by_location(location_id)
func GetActivityData(activity_id: String) -> ActivityData: return get_activity_data(activity_id)
