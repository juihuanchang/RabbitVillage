class_name LifeLocationManager
extends Node

signal life_location_activity_completed(result: LifeLocationResult)

var _rabbit: RabbitData
var _food: FoodManager
var _locations: Dictionary = {}
var _daily_counts: Dictionary = {}
var _cooldown_ends_at: Dictionary = {}
var _applied_record_ids: Array[String] = []
var _completed_activity_count := 0
var _completed_activity_ids: Dictionary = {}
var _day_key := ""

func _init() -> void:
	var picnic := LifeLocationData.new(); picnic.location_id = "picnic_area"; picnic.display_name = "野餐區"
	picnic.activities = [LifeLocationActivityData.create("picnic_rest", "野餐休息", 8, 4),
		LifeLocationActivityData.create("picnic_eat", "野餐用餐"), LifeLocationActivityData.create("picnic_relax", "野餐放鬆", 0, 8, 1)]
	_locations[picnic.location_id] = picnic

func setup(rabbit: RabbitData, food: FoodManager, saved_state: Dictionary = {}) -> void:
	_rabbit = rabbit; _food = food; _day_key = str(saved_state.get("day_key", _current_day_key()))
	if saved_state.get("daily_counts", {}) is Dictionary: _daily_counts = saved_state.get("daily_counts", {}).duplicate(true)
	if saved_state.get("cooldown_ends_at", {}) is Dictionary: _cooldown_ends_at = saved_state.get("cooldown_ends_at", {}).duplicate(true)
	for id: Variant in saved_state.get("applied_record_ids", []): _applied_record_ids.append(str(id))
	_completed_activity_count = maxi(0, int(saved_state.get("completed_activity_count", 0)))
	if saved_state.get("completed_activity_ids", {}) is Dictionary: _completed_activity_ids = saved_state.get("completed_activity_ids", {}).duplicate(true)
	_refresh_day()

func get_location(location_id: String) -> LifeLocationData: return _locations.get(location_id) as LifeLocationData
func get_activities(location_id: String) -> Array[LifeLocationActivityData]:
	var location := get_location(location_id); return location.activities if location != null else []

func can_start_activity(location_id: String, activity_id: String, food_item_id := "") -> Dictionary:
	_refresh_day(); var activity := _get_activity(location_id, activity_id)
	if activity == null: return {"success": false, "reason": "invalid_activity"}
	if int(_daily_counts.get(activity_id, 0)) >= activity.daily_limit: return {"success": false, "reason": "daily_limit"}
	if TimeManager.get_now() < float(_cooldown_ends_at.get(activity_id, 0.0)): return {"success": false, "reason": "cooldown"}
	if activity_id == "picnic_eat" and (_food == null or not _food.can_use_food(food_item_id)):
		return {"success": false, "reason": "food_unavailable"}
	return {"success": true, "reason": ""}

func perform_activity(location_id: String, activity_id: String, food_item_id := "", record_id := "") -> LifeLocationResult:
	var result := LifeLocationResult.new(); result.location_id = location_id; result.activity_id = activity_id
	result.location_record_id = record_id if not record_id.is_empty() else _make_id()
	if _applied_record_ids.has(result.location_record_id): result.reason = "duplicate_activity"; return result
	var check := can_start_activity(location_id, activity_id, food_item_id)
	if not bool(check.success): result.reason = str(check.reason); return result
	var activity := _get_activity(location_id, activity_id); var energy_before := _rabbit.energy
	var mood_before := _rabbit.mood; var intimacy_before := _rabbit.intimacy
	if activity_id == "picnic_eat":
		var food_result := _food.use_food(food_item_id)
		if food_result == null: result.reason = "food_failed"; return result
		result.food_use_record_id = food_result.food_use_record_id; _rabbit.mood += 3; _rabbit.intimacy += 2
	else:
		_rabbit.energy += activity.energy_change; _rabbit.mood += activity.mood_change; _rabbit.intimacy += activity.intimacy_change
	result.energy_change = _rabbit.energy - energy_before; result.mood_change = _rabbit.mood - mood_before
	result.intimacy_change = _rabbit.intimacy - intimacy_before; result.completed_at = TimeManager.get_now(); result.success = true
	_daily_counts[activity_id] = int(_daily_counts.get(activity_id, 0)) + 1
	_cooldown_ends_at[activity_id] = result.completed_at + activity.cooldown_seconds
	_applied_record_ids.append(result.location_record_id); _completed_activity_count += 1; _completed_activity_ids[activity_id] = true
	life_location_activity_completed.emit(result); return result

func _get_activity(location_id: String, activity_id: String) -> LifeLocationActivityData:
	for activity: LifeLocationActivityData in get_activities(location_id):
		if activity.activity_id == activity_id: return activity
	return null
func _refresh_day() -> void:
	var current := _current_day_key()
	if _day_key != current: _day_key = current; _daily_counts.clear(); _cooldown_ends_at.clear()
func _current_day_key() -> String: return Time.get_date_string_from_system()
func _make_id() -> String: return "life_location_%d_%d" % [int(TimeManager.get_now() * 1000000.0), randi_range(1000, 9999)]
func get_completed_activity_count() -> int: return _completed_activity_count
func has_completed_activity(activity_id: String) -> bool: return _completed_activity_ids.has(activity_id)
func get_completed_activity_type_count() -> int: return _completed_activity_ids.size()
func to_dict() -> Dictionary:
	return {"day_key": _day_key, "daily_counts": _daily_counts.duplicate(true), "cooldown_ends_at": _cooldown_ends_at.duplicate(true),
		"applied_record_ids": _applied_record_ids.duplicate(), "completed_activity_count": _completed_activity_count,
		"completed_activity_ids": _completed_activity_ids.duplicate(true)}
