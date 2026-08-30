class_name ActivityManager
extends Node

signal activity_started(active_activity: ActiveActivityData)
signal countdown_changed(active_activity: ActiveActivityData, remaining_seconds: float)
signal activity_completed(active_activity: ActiveActivityData)
signal activity_completed_data(completion_data: Dictionary)
signal rabbit_returned(rabbit: RabbitData)

const MIN_HUNGER_TO_START := 15
const VALID_LOCATIONS := ["home", "forest", "lake", "cafe"]
var active_activity: ActiveActivityData
var last_error := ""
var _rabbit: RabbitData
var _reward_manager: RewardManager
var _life_event_manager: LifeEventManager
var _growth_manager: GrowthManager
var _activities: Dictionary = {}
var _completed_record_ids: Dictionary = {}
var _building_manager: BuildingManager
var _currency_manager: CurrencyManager

func _init() -> void:
	register_activity(ActivityData.create_forest_walk()); register_activity(ActivityData.create_forest_explore())
	register_activity(ActivityData.create_fishing()); register_activity(ActivityData.create_home_rest())
	register_activity(CafeActivityData.create("cafe_hot_drink", "Hot Drink", 30.0, 0, 8, 8))
	register_activity(CafeActivityData.create("cafe_help_serve", "Help Serve", 45.0, -8, 5, 12, 3, 10))
	register_activity(CafeActivityData.create("cafe_relax", "Relax", 30.0, 12, 10, 5, 1))

func setup(rabbit: RabbitData, rewards: RewardManager = null, life_events: LifeEventManager = null, growth: GrowthManager = null) -> void:
	_rabbit = rabbit; _reward_manager = rewards; _life_event_manager = life_events; _growth_manager = growth
func setup_cafe(buildings: BuildingManager, currency: CurrencyManager) -> void: _building_manager = buildings; _currency_manager = currency
func register_activity(activity: ActivityData) -> bool:
	if activity == null or activity.activity_id.is_empty(): return false
	_activities[activity.activity_id] = activity; return true
func get_activity(activity_id: String) -> ActivityData: return _activities.get(activity_id.strip_edges().to_lower()) as ActivityData
func get_activity_data(activity_id: String) -> ActivityData: return get_activity(activity_id)
func get_all_activities() -> Array[ActivityData]:
	var result: Array[ActivityData] = []; result.assign(_activities.values()); return result
func get_activities_by_location(location_id: String) -> Array[ActivityData]:
	var result: Array[ActivityData] = []
	for activity: ActivityData in _activities.values():
		if activity.location_id == location_id.strip_edges().to_lower(): result.append(activity)
	return result

func can_start_activity(activity_id: String) -> Dictionary:
	if active_activity != null or (_rabbit != null and not _rabbit.current_activity.is_empty()): return _check(false, "already_active")
	var activity := get_activity(activity_id)
	if activity == null or not activity.is_unlocked or not VALID_LOCATIONS.has(activity.location_id): return _check(false, "invalid_activity")
	if _rabbit == null: return _check(false, "invalid_activity")
	if activity.location_id == "cafe" and (_building_manager == null or not _building_manager.is_building_completed("coffee_shop")): return _check(false, "cafe_not_completed")
	if (_life_event_manager != null and _life_event_manager.has_pending_life_event()) or (_growth_manager != null and _growth_manager.has_pending_growth_event()): return _check(false, "invalid_activity")
	if activity.activity_type != ActivityData.TYPE_HOME and _rabbit.hunger < MIN_HUNGER_TO_START: return _check(false, "too_hungry")
	if _rabbit.energy < activity.required_energy: return _check(false, "too_tired")
	return _check(true, "")
func _check(success: bool, reason: String) -> Dictionary: return {"ok": success, "success": success, "reason": reason}

func start_activity(activity_id: String) -> Dictionary:
	var check := can_start_activity(activity_id); last_error = str(check.reason)
	if not check.ok: return check
	var activity := get_activity(activity_id); var now := TimeManager.get_now()
	active_activity = ActiveActivityData.new(_rabbit, activity, now); _rabbit.is_away = activity.activity_type == ActivityData.TYPE_OUTDOOR
	_rabbit.current_activity = activity.activity_id; _rabbit.current_state = "resting" if activity.activity_type == ActivityData.TYPE_HOME else "active"
	activity_started.emit(active_activity); countdown_changed.emit(active_activity, active_activity.get_remaining_seconds(now))
	return {"ok": true, "success": true, "reason": "", "active_activity": active_activity}

func has_active_activity() -> bool: return active_activity != null and not active_activity.is_completed
func get_current_activity() -> ActiveActivityData: return active_activity
func get_remaining_seconds() -> float: return active_activity.get_remaining_seconds() if active_activity else 0.0
func get_end_time() -> float: return active_activity.ends_at if active_activity else 0.0
func is_rabbit_away() -> bool: return _rabbit != null and _rabbit.is_away
func get_rabbit_data() -> RabbitData: return _rabbit
func restore_activity(restored: ActiveActivityData) -> void:
	active_activity = restored
	if restored == null: return
	_rabbit = restored.rabbit; var running := not restored.is_completed
	_rabbit.is_away = running and restored.activity.activity_type == ActivityData.TYPE_OUTDOOR
	_rabbit.current_activity = restored.activity.activity_id if running else ""
	_rabbit.current_state = ("resting" if restored.activity.activity_type == ActivityData.TYPE_HOME else "active") if running else ""
func set_completed_record_ids(record_ids: Array[String]) -> void:
	_completed_record_ids.clear()
	for record_id in record_ids: _completed_record_ids[record_id] = true
func get_completed_record_ids() -> Array[String]:
	var result: Array[String] = []; result.assign(_completed_record_ids.keys()); return result
func _process(_delta: float) -> void:
	if not has_active_activity(): return
	var now := TimeManager.get_now(); countdown_changed.emit(active_activity, active_activity.get_remaining_seconds(now))
	if now >= active_activity.ends_at: _complete_activity(now)
func check_for_completion() -> bool:
	if not has_active_activity() or TimeManager.get_now() < active_activity.ends_at: return false
	_complete_activity(TimeManager.get_now()); return true

func _complete_activity(completed_time: float) -> void:
	if active_activity == null or active_activity.is_completed: return
	var completed := active_activity
	if _completed_record_ids.has(completed.activity_record_id): active_activity = null; return
	_completed_record_ids[completed.activity_record_id] = true; completed.mark_completed(completed_time)
	var rabbit := completed.rabbit; var activity := completed.activity
	rabbit.energy += activity.energy_change; rabbit.hunger += activity.hunger_change; rabbit.mood += activity.mood_change
	rabbit.forest_experience += activity.forest_experience_change; rabbit.fishing_experience += activity.fishing_experience_change; rabbit.intimacy += activity.intimacy_change
	match activity.location_id:
		"forest": rabbit.forest_activity_count += 1
		"lake": rabbit.fishing_activity_count += 1
		"home": rabbit.home_activity_count += 1
		"cafe": rabbit.cafe_activity_count += 1
	if activity is CafeActivityData:
		var cafe := activity as CafeActivityData; rabbit.cafe_experience += cafe.cafe_experience_change; rabbit.social_experience += cafe.social_experience_change
		if cafe.coin_reward > 0 and _currency_manager != null: _currency_manager.add_coins(cafe.coin_reward, "cafe_activity", completed.activity_record_id)
	rabbit.total_activity_count += 1; rabbit.is_away = false; rabbit.current_activity = ""; rabbit.current_state = ""
	if _reward_manager != null:
		var reward := _reward_manager.generate_activity_reward(activity.activity_id, completed.activity_record_id)
		if reward != null and not _reward_manager.has_reward_been_applied(completed.activity_record_id): _reward_manager.apply_activity_reward(reward)
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
