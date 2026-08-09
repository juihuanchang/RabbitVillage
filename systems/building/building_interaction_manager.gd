class_name BuildingInteractionManager
extends Node

signal building_interaction_started(active: ActiveBuildingInteractionData)
signal building_interaction_completed(result: BuildingUseResult)
var data: VillageData
var rabbit: RabbitData
var activities: ActivityManager
var buildings: BuildingManager
var village: VillageManager
var growth: GrowthManager
var village_events: VillageEventManager
var definition := BuildingInteractionData.new()

func setup(village_data: VillageData, rabbit_data: RabbitData, activity_manager: ActivityManager, building_manager: BuildingManager, village_manager: VillageManager, growth_manager: GrowthManager, event_manager: VillageEventManager) -> void:
	data = village_data; rabbit = rabbit_data; activities = activity_manager; buildings = building_manager; village = village_manager; growth = growth_manager; village_events = event_manager
	if is_rest_pavilion_in_use():
		rabbit.current_activity = "building:rest_pavilion"
		rabbit.current_state = "休息亭休息中"
func can_use_rest_pavilion() -> Dictionary:
	if not buildings.is_building_completed("rest_pavilion"): return {"ok": false, "reason": "休息亭尚未完工"}
	if activities.has_active_activity(): return {"ok": false, "reason": "Amy 正在進行活動"}
	if is_rest_pavilion_in_use(): return {"ok": false, "reason": "Amy 正在使用其他建築"}
	if is_rest_pavilion_on_cooldown(): return {"ok": false, "reason": "休息亭冷卻中"}
	if (growth != null and growth.has_pending_growth_event()) or (village_events != null and village_events.has_pending_event()): return {"ok": false, "reason": "尚有待確認事件"}
	if definition.duration_seconds <= 0.0: return {"ok": false, "reason": "使用時間資料錯誤"}
	return {"ok": true, "reason": ""}
func start_rest_pavilion_use() -> Dictionary:
	var check := can_use_rest_pavilion(); if not check.ok: return check
	var active := ActiveBuildingInteractionData.new(); active.interaction_record_id = _unique_id(); active.building_id = "rest_pavilion"; active.started_at = TimeManager.get_now(); active.ends_at = active.started_at + definition.duration_seconds
	data.active_building_interaction = active.to_dict(); rabbit.current_activity = "building:rest_pavilion"; rabbit.current_state = "休息亭休息中"; building_interaction_started.emit(active); return {"ok": true, "reason": "", "active": active}
func check_rest_pavilion_completion() -> BuildingUseResult:
	if not is_rest_pavilion_in_use(): return null
	var raw := data.active_building_interaction
	if TimeManager.get_now() < float(raw.get("ends_at", 0.0)): return null
	var id := str(raw.get("interaction_record_id", ""))
	if data.conditions.rewarded_keys.has("building_use:" + id): data.active_building_interaction = {}; return null
	data.conditions.claim_once("building_use:" + id); rabbit.energy += definition.energy_change; rabbit.mood += definition.mood_change; rabbit.intimacy += definition.intimacy_change
	var record: Dictionary = data.building_records["rest_pavilion"]; record["use_count"] = int(record.get("use_count", 0)) + 1; record["last_used_at"] = TimeManager.get_now(); data.building_records["rest_pavilion"] = record
	data.building_interactions["rest_pavilion_cooldown_ends_at"] = TimeManager.get_now() + definition.cooldown_seconds; data.active_building_interaction = {}; rabbit.current_activity = ""; rabbit.current_state = ""; village.register_rest_pavilion_use(); village.claim_reward_once("first_use:rest_pavilion", 15)
	var result := BuildingUseResult.new(); result.interaction_record_id = id; result.building_id = "rest_pavilion"; result.completed_at = TimeManager.get_now(); result.energy_change = definition.energy_change; result.mood_change = definition.mood_change; result.intimacy_change = definition.intimacy_change; result.use_count = int(record.use_count); building_interaction_completed.emit(result); return result
func is_rest_pavilion_in_use() -> bool: return data != null and not data.active_building_interaction.is_empty()
func get_rest_pavilion_use_remaining() -> float: return maxf(float(data.active_building_interaction.get("ends_at", 0.0)) - TimeManager.get_now(), 0.0) if is_rest_pavilion_in_use() else 0.0
func is_rest_pavilion_on_cooldown() -> bool: return get_rest_pavilion_cooldown_remaining() > 0.0
func get_rest_pavilion_cooldown_remaining() -> float: return maxf(get_rest_pavilion_cooldown_end_time() - TimeManager.get_now(), 0.0)
func get_rest_pavilion_cooldown_end_time() -> float: return float(data.building_interactions.get("rest_pavilion_cooldown_ends_at", 0.0)) if data else 0.0
func _unique_id() -> String: return "building_use_%d_%d" % [int(TimeManager.get_now() * 1000000.0), randi_range(1000, 9999)]
func CanUseRestPavilion() -> Dictionary: return can_use_rest_pavilion()
func StartRestPavilionUse() -> Dictionary: return start_rest_pavilion_use()
func CheckRestPavilionCompletion() -> BuildingUseResult: return check_rest_pavilion_completion()
func IsRestPavilionInUse() -> bool: return is_rest_pavilion_in_use()
func GetRestPavilionUseRemaining() -> float: return get_rest_pavilion_use_remaining()
func IsRestPavilionOnCooldown() -> bool: return is_rest_pavilion_on_cooldown()
func GetRestPavilionCooldownRemaining() -> float: return get_rest_pavilion_cooldown_remaining()
func GetRestPavilionCooldownEndTime() -> float: return get_rest_pavilion_cooldown_end_time()
