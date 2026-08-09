class_name BuildingManager
extends Node

const VALID_SLOTS := ["Slot01", "Slot02", "Slot03", "Slot04", "Slot05", "Slot06", "Slot07", "Slot08", "Slot09"]
var data: VillageData
var buildings: Dictionary = {}
var construction_manager: ConstructionManager

func _init() -> void:
	for b in [BuildingData.create("rest_pavilion", "休息亭", 30.0, 25, false), BuildingData.create("notice_board", "公告欄", 45.0, 30), BuildingData.create("carrot_farm", "小農田", 60.0, 40)]: buildings[b.building_id] = b
func setup(village_data: VillageData) -> void:
	data = village_data
	for id in data.unlocked_building_ids:
		if buildings.has(id): (buildings[id] as BuildingData).is_unlocked = true
func get_all_buildings() -> Array[BuildingData]: var a: Array[BuildingData] = []; a.assign(buildings.values()); return a
func get_building(id: String) -> BuildingData: return buildings.get(id) as BuildingData
func get_unlocked_buildings() -> Array[BuildingData]: return get_all_buildings().filter(func(b): return b.is_unlocked)
func get_available_buildings() -> Array[BuildingData]: return get_unlocked_buildings().filter(func(b): return not has_building(b.building_id))
func get_constructing_building() -> BuildingRecord:
	for raw: Dictionary in data.building_records.values():
		if raw.get("state") == BuildingState.CONSTRUCTING: return BuildingRecord.from_dict(raw)
	return null
func get_completed_buildings() -> Array[BuildingRecord]:
	var out: Array[BuildingRecord] = []
	for raw: Dictionary in data.building_records.values():
		if raw.get("state") == BuildingState.COMPLETED: out.append(BuildingRecord.from_dict(raw))
	return out
func can_place_building(id: String, slot_id: String) -> Dictionary:
	var b := get_building(id)
	if b == null or id == "coffee_shop": return {"ok": false, "reason": "找不到建築"}
	if not b.is_unlocked: return {"ok": false, "reason": "建築尚未解鎖"}
	if has_building(id): return {"ok": false, "reason": "建築已經完工" if is_building_completed(id) else "建築已經放置"}
	if not VALID_SLOTS.has(slot_id): return {"ok": false, "reason": "空地不存在"}
	if get_used_slot_ids().has(slot_id): return {"ok": false, "reason": "空地已被使用"}
	if get_constructing_building() != null: return {"ok": false, "reason": "目前已有建築施工中"}
	return {"ok": true, "reason": ""}
func place_building(id: String, slot_id: String) -> Dictionary:
	var check := can_place_building(id, slot_id); if not check.ok: return check
	var record := BuildingRecord.new(); record.building_id = id; record.slot_id = slot_id; record.placed_at = TimeManager.get_now()
	data.building_records[id] = record.to_dict(); return {"ok": true, "reason": "", "record": record}
func has_building(id: String) -> bool: return data != null and data.building_records.has(id)
func is_building_completed(id: String) -> bool: return get_building_state(id) == BuildingState.COMPLETED
func get_building_state(id: String) -> String:
	if not buildings.has(id): return "invalid"
	if data.building_records.has(id): return str(data.building_records[id].get("state", "invalid"))
	return BuildingState.AVAILABLE if (buildings[id] as BuildingData).is_unlocked else BuildingState.LOCKED
func get_used_slot_ids() -> Array[String]:
	var ids: Array[String] = []
	for raw: Dictionary in data.building_records.values(): ids.append(str(raw.get("slot_id", "")))
	return ids
func unlock_building(id: String) -> bool:
	if not buildings.has(id) or data.unlocked_building_ids.has(id): return false
	data.unlocked_building_ids.append(id); (buildings[id] as BuildingData).is_unlocked = true; return true
func GetAllBuildings() -> Array[BuildingData]: return get_all_buildings()
func GetBuilding(id: String) -> BuildingData: return get_building(id)
func GetUnlockedBuildings() -> Array[BuildingData]: return get_unlocked_buildings()
func GetAvailableBuildings() -> Array[BuildingData]: return get_available_buildings()
func GetConstructingBuilding() -> BuildingRecord: return get_constructing_building()
func GetCompletedBuildings() -> Array[BuildingRecord]: return get_completed_buildings()
func CanPlaceBuilding(id: String, slot: String) -> Dictionary: return can_place_building(id, slot)
func PlaceBuilding(id: String, slot: String) -> Dictionary: return place_building(id, slot)
func HasBuilding(id: String) -> bool: return has_building(id)
func IsBuildingCompleted(id: String) -> bool: return is_building_completed(id)
func GetBuildingState(id: String) -> String: return get_building_state(id)
func GetUsedSlotIds() -> Array[String]: return get_used_slot_ids()
