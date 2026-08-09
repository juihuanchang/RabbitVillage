class_name FarmManager
extends Node

signal farm_cycle_started(cycle: FarmCycleData)
signal farm_ready(cycle: FarmCycleData)
signal carrots_harvested(result: HarvestResult)
var data: VillageData
var farm := FarmData.new()
var buildings: BuildingManager
var village: VillageManager

func setup(village_data: VillageData, building_manager: BuildingManager, village_manager: VillageManager) -> void:
	data = village_data; buildings = building_manager; village = village_manager
	if not data.farm.is_empty(): farm = FarmData.from_dict(data.farm)
	_sync()
func start_first_growth_cycle() -> Dictionary:
	if not buildings.is_building_completed("carrot_farm"): return {"ok": false, "reason": "小農田尚未完工"}
	if has_active_growth_cycle() or is_farm_ready(): return {"ok": false, "reason": "目前已有生長週期"}
	if not data.conditions.claim_once("farm:first_cycle_created"): return {"ok": false, "reason": "第一輪已建立"}
	var cycle := _create_cycle(); village.claim_reward_once("farm:first_growth", 15); return {"ok": true, "reason": "", "cycle": cycle}
func start_next_growth_cycle() -> Dictionary:
	if has_active_growth_cycle() or is_farm_ready(): return {"ok": false, "reason": "目前已有生長週期"}
	return {"ok": true, "reason": "", "cycle": _create_cycle()}
func _create_cycle() -> FarmCycleData:
	var c := FarmCycleData.new(); c.farm_cycle_id = "farm_%d_%d" % [int(TimeManager.get_now() * 1000000.0), randi_range(1000, 9999)]; c.started_at = TimeManager.get_now(); c.ready_at = c.started_at + farm.growth_seconds; farm.current_cycle = c.to_dict(); farm.state = FarmState.GROWING; village.register_farm_cycle_started(); _sync(); farm_cycle_started.emit(c); return c
func get_farm_state() -> String: return farm.state
func has_active_growth_cycle() -> bool: return farm.state == FarmState.GROWING and not farm.current_cycle.is_empty()
func is_farm_ready() -> bool: return farm.state == FarmState.READY
func get_farm_remaining_seconds() -> float: return maxf(get_farm_ready_time() - TimeManager.get_now(), 0.0) if has_active_growth_cycle() else 0.0
func get_farm_ready_time() -> float: return float(farm.current_cycle.get("ready_at", 0.0))
func get_current_farm_cycle() -> FarmCycleData: return FarmCycleData.from_dict(farm.current_cycle) if not farm.current_cycle.is_empty() else null
func check_farm_ready_state() -> bool:
	if not has_active_growth_cycle() or TimeManager.get_now() < get_farm_ready_time(): return false
	farm.state = FarmState.READY; _sync(); farm_ready.emit(get_current_farm_cycle()); return true
func harvest_carrots() -> HarvestResult:
	check_farm_ready_state()
	if not is_farm_ready(): return null
	var cycle := get_current_farm_cycle()
	if cycle == null or cycle.is_harvested or farm.completed_cycle_ids.has(cycle.farm_cycle_id): return null
	farm.completed_cycle_ids.append(cycle.farm_cycle_id); cycle.is_harvested = true; cycle.harvested_at = TimeManager.get_now(); farm.state = FarmState.IDLE; farm.current_cycle = {}; data.carrot_amount += 10; village.register_carrot_harvest(10); village.add_village_experience(10)
	var result := HarvestResult.new(); result.farm_cycle_id = cycle.farm_cycle_id; result.amount = 10; result.harvested_at = cycle.harvested_at; result.village_experience_reward = 10; _sync(); start_next_growth_cycle(); carrots_harvested.emit(result); return result
func get_carrot_amount() -> int: return data.carrot_amount
func get_total_harvest_count() -> int: return data.progress.total_harvest_count
func _sync() -> void: data.farm = farm.to_dict()
func GetFarmState() -> String: return get_farm_state()
func StartFirstGrowthCycle() -> Dictionary: return start_first_growth_cycle()
func StartNextGrowthCycle() -> Dictionary: return start_next_growth_cycle()
func HasActiveGrowthCycle() -> bool: return has_active_growth_cycle()
func IsFarmReady() -> bool: return is_farm_ready()
func GetFarmRemainingSeconds() -> float: return get_farm_remaining_seconds()
func GetFarmReadyTime() -> float: return get_farm_ready_time()
func GetCurrentFarmCycle() -> FarmCycleData: return get_current_farm_cycle()
func CheckFarmReadyState() -> bool: return check_farm_ready_state()
func HarvestCarrots() -> HarvestResult: return harvest_carrots()
func GetCarrotAmount() -> int: return get_carrot_amount()
func GetTotalHarvestCount() -> int: return get_total_harvest_count()
