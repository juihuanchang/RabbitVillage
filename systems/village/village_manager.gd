class_name VillageManager
extends Node

signal village_progress_changed(progress: VillageProgressData)
const LEVEL_THRESHOLDS := [0, 100, 250, 500, 900]
var data: VillageData
var building_manager: BuildingManager
var growth_manager: GrowthManager
var life_event_manager: LifeEventManager
var rabbit: RabbitData
var activity_manager: ActivityManager
var diary_manager: DiaryManager
var history_summary: Dictionary = {}

func setup(village_data: VillageData) -> void:
	data = village_data
	if data.progress.village_level > 0 or data.progress.village_experience > 0:
		check_village_level()
func setup_snapshot_sources(buildings: BuildingManager, growth: GrowthManager, life_events: LifeEventManager) -> void: building_manager = buildings; growth_manager = growth; life_event_manager = life_events
func setup_late_game(value: RabbitData, activities: ActivityManager, diary: DiaryManager, summary: Dictionary = {}) -> void: rabbit = value; activity_manager = activities; diary_manager = diary; history_summary = summary.duplicate(true)
func set_life_history_summary(summary: Dictionary) -> void: history_summary = summary.duplicate(true)
func get_village_progress_snapshot() -> VillageProgressSnapshot:
	var snapshot := VillageProgressSnapshot.new()
	if building_manager != null:
		for record: BuildingRecord in building_manager.get_completed_buildings(): snapshot.completed_buildings.append(record.building_id)
		snapshot.unlocked_buildings = data.unlocked_building_ids.duplicate()
	if growth_manager != null:
		snapshot.growth_progress = {"forest_stage": growth_manager.get_forest_growth_stage(), "lakeside_stage": growth_manager.get_lakeside_growth_stage(), "appearance": growth_manager.get_appearance_state(), "dominant_tendency": growth_manager.get_dominant_tendency()}
		if growth_manager.get_forest_growth_stage() > 0: snapshot.areas.append("forest")
		if growth_manager.get_lakeside_growth_stage() > 0: snapshot.areas.append("lakeside")
	if life_event_manager != null: snapshot.life_events = life_event_manager.get_completed_event_ids()
	snapshot.progress_score = snapshot.completed_buildings.size() * 20 + snapshot.unlocked_buildings.size() * 5 + snapshot.life_events.size() * 5 + int(snapshot.growth_progress.get("forest_stage", 0)) * 10 + int(snapshot.growth_progress.get("lakeside_stage", 0)) * 10
	return snapshot
func add_village_experience(value: int) -> int:
	if data == null or value <= 0: return get_village_experience()
	data.progress.village_experience += value; check_village_level(); village_progress_changed.emit(data.progress); return data.progress.village_experience
func get_village_experience() -> int: return data.progress.village_experience if data else 0
func get_village_level() -> int: return data.progress.village_level if data else 0
func check_village_level() -> int:
	if data == null: return 1
	var level := 1
	for i in LEVEL_THRESHOLDS.size():
		if data.progress.village_experience >= LEVEL_THRESHOLDS[i]: level = i + 1
	data.progress.village_level = level; return level
func get_village_progress() -> VillageProgressData: return data.progress if data else null
func register_building_completed(building_id: String) -> bool:
	if not data.conditions.claim_once("building_completed:" + building_id): return false
	data.progress.completed_building_count += 1; village_progress_changed.emit(data.progress); return true
func register_rest_pavilion_use() -> void: data.progress.rest_pavilion_use_count += 1; village_progress_changed.emit(data.progress)
func register_notice_read() -> void: data.progress.notice_board_read_count += 1; village_progress_changed.emit(data.progress)
func register_farm_cycle_started() -> void: data.progress.farm_growth_cycle_count += 1; village_progress_changed.emit(data.progress)
func register_carrot_harvest(amount: int) -> void: data.progress.total_harvest_count += 1; data.progress.total_carrots_obtained += maxi(0, amount); village_progress_changed.emit(data.progress)
func claim_reward_once(key: String, experience: int) -> bool:
	if not data.conditions.claim_once(key): return false
	add_village_experience(experience); return true

func check_stage1_completion() -> StageCompletionResult:
	var result := StageCompletionResult.new(); var condition := StageCompletionConditionData.new()
	if building_manager == null or not building_manager.is_building_completed("coffee_shop"): result.reason = "cafe_not_completed"; return result
	if rabbit == null or rabbit.total_activity_count < condition.required_activity_count: result.reason = "activity_count"; return result
	if growth_manager == null or (growth_manager.get_forest_growth_stage() < 3 and growth_manager.get_lakeside_growth_stage() < 2): result.reason = "growth_stage"; return result
	if life_event_manager == null or life_event_manager.get_completed_event_ids().size() < condition.required_life_event_count: result.reason = "life_events"; return result
	if diary_manager == null or diary_manager.get_journal_count() < condition.required_journal_count: result.reason = "journals"; return result
	if get_village_progress_snapshot().progress_score < condition.required_village_progress: result.reason = "village_progress"; return result
	result.success = true; result.completed_at = TimeManager.get_now(); return result
func can_trigger_stage1_ending() -> bool:
	if rabbit == null: return false
	var state := _raw_stage1_ending_state(); if state.state in [EndingStateData.PENDING, EndingStateData.COMPLETED]: return false
	return _ending_requirements_met()
func _ending_requirements_met() -> bool:
	if not check_stage1_completion().success: return false
	var choice := growth_manager.get_growth_direction_choice() if growth_manager != null else null
	return (growth_manager != null and growth_manager.get_current_final_form() != "none") or (choice != null and choice.choice_id == "maintain_current")
func get_stage1_ending_state() -> EndingStateData:
	var state := _raw_stage1_ending_state()
	if state.state == EndingStateData.LOCKED and _ending_requirements_met(): state.state = EndingStateData.AVAILABLE
	return state
func _raw_stage1_ending_state() -> EndingStateData:
	if rabbit == null or rabbit.stage1_ending_state.is_empty(): return EndingStateData.new()
	return EndingStateData.from_dict(rabbit.stage1_ending_state)
func create_stage1_ending() -> EndingStateData:
	var state := get_stage1_ending_state()
	if state.state == EndingStateData.PENDING or state.state == EndingStateData.COMPLETED: return state
	if not can_trigger_stage1_ending(): return state
	state.state = EndingStateData.PENDING; state.created_at = TimeManager.get_now(); rabbit.stage1_ending_state = state.to_dict(); return state
func complete_stage1_ending() -> EndingResult:
	var existing := get_stage1_ending_result()
	if has_completed_stage1_ending(): return existing
	var state := get_stage1_ending_state(); if state.state != EndingStateData.PENDING: return null
	var snapshot := get_village_progress_snapshot(); var result := EndingResult.new(); result.ending_type = "maintain" if growth_manager.get_current_final_form() == "none" else growth_manager.get_current_final_form().trim_suffix("_rabbit"); result.current_form = growth_manager.get_current_final_form(); result.growth_summary = {"forest_stage": growth_manager.get_forest_growth_stage(), "lakeside_stage": growth_manager.get_lakeside_growth_stage(), "dominant_tendency": growth_manager.get_dominant_tendency()}; result.village_summary = {"completed_buildings": snapshot.completed_buildings, "unlocked_buildings": snapshot.unlocked_buildings, "areas": snapshot.areas, "progress_score": snapshot.progress_score}; result.important_memories = life_event_manager.get_completed_event_ids().duplicate(); result.completed_at = TimeManager.get_now(); result.first_completion = true
	state.state = EndingStateData.COMPLETED; state.completed_at = result.completed_at; rabbit.stage1_ending_state = state.to_dict(); rabbit.stage1_ending_result = result.to_dict(); return result
func has_completed_stage1_ending() -> bool: return rabbit != null and get_stage1_ending_state().state == EndingStateData.COMPLETED
func get_stage1_ending_result() -> EndingResult:
	if rabbit == null or rabbit.stage1_ending_result.is_empty(): return null
	var raw := rabbit.stage1_ending_result; var result := EndingResult.new(); result.ending_id = str(raw.get("ending_id", "stage1_ending")); result.ending_type = str(raw.get("ending_type", "")); result.current_form = str(raw.get("current_form", "none")); result.growth_summary = raw.get("growth_summary", {}).duplicate(true); result.village_summary = raw.get("village_summary", {}).duplicate(true); result.important_memories.assign(raw.get("important_memories", [])); result.completed_at = float(raw.get("completed_at", 0.0)); result.first_completion = false; return result
func get_rabbit_life_summary() -> RabbitLifeSummaryData:
	var summary := RabbitLifeSummaryData.new(); var profile := RabbitLifeProfileData.new(); summary.profile = profile
	if rabbit == null: return summary
	profile.name = rabbit.rabbit_name; profile.move_in_date = rabbit.move_in_date; profile.current_form = growth_manager.get_current_final_form() if growth_manager != null else "none"; profile.dominant_tendency = growth_manager.get_dominant_tendency() if growth_manager != null else "balanced"
	profile.favorite_location = str(history_summary.get("favorite_location", "")); profile.favorite_food = str(history_summary.get("favorite_food", "")); profile.most_used_activity = str(history_summary.get("most_used_activity", "")); profile.first_growth_mark = str(history_summary.get("first_growth_mark", "")); profile.first_building = str(history_summary.get("first_building", "")); profile.important_event_count = life_event_manager.get_completed_event_ids().size() if life_event_manager != null else 0; profile.journal_count = diary_manager.get_journal_count() if diary_manager != null else 0
	summary.growth_summary = {"forest_stage": growth_manager.get_forest_growth_stage(), "lakeside_stage": growth_manager.get_lakeside_growth_stage(), "current_form": profile.current_form, "dominant_tendency": profile.dominant_tendency} if growth_manager != null else {}
	var snapshot := get_village_progress_snapshot(); summary.village_summary = {"completed_buildings": snapshot.completed_buildings, "unlocked_buildings": snapshot.unlocked_buildings, "progress_score": snapshot.progress_score}; summary.important_memories = life_event_manager.get_completed_event_ids() if life_event_manager != null else []; return summary
