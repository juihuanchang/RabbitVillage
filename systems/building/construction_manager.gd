class_name ConstructionManager
extends Node

signal construction_started(record: ConstructionRecord)
signal construction_completed(result: ConstructionResult)
var data: VillageData
var building_manager: BuildingManager
var village_manager: VillageManager

func setup(village_data: VillageData, buildings: BuildingManager, village: VillageManager) -> void:
	data = village_data; building_manager = buildings; village_manager = village
func start_construction(building_id: String) -> Dictionary:
	if has_active_construction(): return {"ok": false, "reason": "目前已有建築施工中"}
	if not building_manager.has_building(building_id): return {"ok": false, "reason": "建築狀態錯誤"}
	if building_manager.get_building_state(building_id) != BuildingState.PLACED: return {"ok": false, "reason": "建築狀態錯誤"}
	var definition := building_manager.get_building(building_id); var raw: Dictionary = data.building_records[building_id]
	var record := ConstructionRecord.new(); record.construction_record_id = _unique_id("construction")
	record.building_id = building_id; record.slot_id = str(raw.get("slot_id", "")); record.started_at = TimeManager.get_now(); record.ends_at = record.started_at + definition.construction_seconds
	raw["state"] = BuildingState.CONSTRUCTING; data.building_records[building_id] = raw; data.active_construction = record.to_dict()
	construction_started.emit(record); return {"ok": true, "reason": "", "record": record}
func has_active_construction() -> bool: return data != null and not data.active_construction.is_empty() and not bool(data.active_construction.get("is_completed", false))
func get_active_construction() -> ConstructionRecord: return ConstructionRecord.from_dict(data.active_construction) if has_active_construction() else null
func get_construction_remaining_seconds() -> float: var r := get_active_construction(); return maxf(r.ends_at - TimeManager.get_now(), 0.0) if r else 0.0
func get_construction_end_time() -> float: var r := get_active_construction(); return r.ends_at if r else 0.0
func check_construction_completion() -> ConstructionResult:
	var record := get_active_construction()
	if record == null or TimeManager.get_now() < record.ends_at: return null
	if data.completed_construction_ids.has(record.construction_record_id): data.active_construction = {}; return null
	data.completed_construction_ids.append(record.construction_record_id); record.is_completed = true; record.completed_at = TimeManager.get_now()
	var raw: Dictionary = data.building_records.get(record.building_id, {})
	if raw.is_empty() or raw.get("state") != BuildingState.CONSTRUCTING: data.active_construction = {}; return null
	var first := village_manager.register_building_completed(record.building_id); raw["state"] = BuildingState.COMPLETED; raw["completed_at"] = record.completed_at; data.building_records[record.building_id] = raw
	var result := ConstructionResult.new(); result.construction_record_id = record.construction_record_id; result.building_id = record.building_id; result.slot_id = record.slot_id; result.started_at = record.started_at; result.completed_at = record.completed_at; result.is_first_completion = first
	if first: result.village_experience_reward = building_manager.get_building(record.building_id).village_experience_reward; village_manager.add_village_experience(result.village_experience_reward)
	data.active_construction = {}; construction_completed.emit(result); return result
func _unique_id(prefix: String) -> String: return "%s_%d_%d" % [prefix, int(TimeManager.get_now() * 1000000.0), randi_range(1000, 9999)]
func StartConstruction(id: String) -> Dictionary: return start_construction(id)
func HasActiveConstruction() -> bool: return has_active_construction()
func GetActiveConstruction() -> ConstructionRecord: return get_active_construction()
func GetConstructionRemainingSeconds() -> float: return get_construction_remaining_seconds()
func GetConstructionEndTime() -> float: return get_construction_end_time()
func CheckConstructionCompletion() -> ConstructionResult: return check_construction_completion()
