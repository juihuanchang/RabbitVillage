class_name BuildingManager
extends Node

const VALID_SLOTS := ["Slot01", "Slot02", "Slot03", "Slot04", "Slot05", "Slot06", "Slot07", "Slot08", "Slot09"]
var data: VillageData
var buildings: Dictionary = {}
var construction_manager: ConstructionManager

func _init() -> void:
	for b in [BuildingData.create("coffee_shop", "咖啡廳", 0.0, 0, true), BuildingData.create("rest_pavilion", "休息亭", 30.0, 25, false), BuildingData.create("notice_board", "公告欄", 30.0, 30), BuildingData.create("carrot_farm", "小農田", 30.0, 40)]: buildings[b.building_id] = b
func setup(village_data: VillageData) -> void:
	data = village_data
	for id in data.unlocked_building_ids:
		if buildings.has(id): (buildings[id] as BuildingData).is_unlocked = true
func get_all_buildings() -> Array[BuildingData]: var a: Array[BuildingData] = []; a.assign(buildings.values()); return a
func get_building(id: String) -> BuildingData: return buildings.get(id) as BuildingData
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
	if b == null: return {"ok": false, "reason": "找不到建築"}
	if not b.is_unlocked: return {"ok": false, "reason": "建築尚未解鎖"}
	if has_building(id): return {"ok": false, "reason": "建築已經完工" if is_building_completed(id) else "建築已經放置"}
	if not VALID_SLOTS.has(slot_id): return {"ok": false, "reason": "空地不存在"}
	if get_used_slot_ids().has(slot_id): return {"ok": false, "reason": "空地已被使用"}
	if get_constructing_building() != null: return {"ok": false, "reason": "目前已有建築施工中"}
	return {"ok": true, "reason": ""}
func place_building(id: String, slot_id: String) -> Dictionary:
	var check := can_place_building(id, slot_id); if not check.ok: return check
	var record := BuildingRecord.new(); record.building_id = id; record.slot_id = slot_id; record.placed_at = TimeManager.get_now()
	if bool(data.building_interactions.get("completed_once:" + id, false)) or id == "coffee_shop": record.state = BuildingState.COMPLETED; record.completed_at = record.placed_at
	data.building_records[id] = record.to_dict(); return {"ok": true, "reason": "", "record": record}
func reclaim_building(id: String) -> Dictionary:
	if not has_building(id): return {"ok": false, "reason": "建築不在地圖上"}
	if get_building_state(id) == BuildingState.CONSTRUCTING: return {"ok": false, "reason": "施工中請使用取消施工"}
	if is_building_completed(id): data.building_interactions["completed_once:" + id] = true
	data.building_records.erase(id); return {"ok": true, "reason": ""}
func adopt_completed_building(id: String, slot_id: String) -> bool:
	if not buildings.has(id) or not VALID_SLOTS.has(slot_id): return false
	unlock_building(id)
	var raw: Dictionary = data.building_records.get(id, {})
	raw["building_id"] = id; raw["slot_id"] = slot_id; raw["state"] = BuildingState.COMPLETED
	raw["placed_at"] = float(raw.get("placed_at", TimeManager.get_now()))
	raw["completed_at"] = maxf(float(raw.get("completed_at", 0.0)), TimeManager.get_now())
	data.building_records[id] = raw; data.building_interactions["completed_once:" + id] = true
	return true
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
