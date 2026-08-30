class_name VillageManager
extends Node

signal village_progress_changed(progress: VillageProgressData)
const LEVEL_THRESHOLDS := [0, 100, 250, 500, 900]
var data: VillageData
var building_manager: BuildingManager
var growth_manager: GrowthManager
var life_event_manager: LifeEventManager

func setup(village_data: VillageData) -> void:
	data = village_data
	if data.progress.village_level > 0 or data.progress.village_experience > 0:
		check_village_level()
func setup_snapshot_sources(buildings: BuildingManager, growth: GrowthManager, life_events: LifeEventManager) -> void: building_manager = buildings; growth_manager = growth; life_event_manager = life_events
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
