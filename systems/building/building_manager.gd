class_name BuildingManager
extends Node

const VALID_SLOTS := ["Slot01", "Slot02", "Slot03", "Slot04", "Slot05", "Slot06", "Slot07", "Slot08", "Slot09"]
var data: VillageData
var buildings: Dictionary = {}
var construction_manager: ConstructionManager
var currency_manager: CurrencyManager
var inventory_manager: InventoryManager

func _init() -> void:
	_add("coffee_shop", "Café", 30.0, 40, 50, {"twig": 5, "small_stone": 3}, false)
	_add("rest_pavilion", "Rest Pavilion", 30.0, 25, 25, {"twig": 3, "leaf": 5}, false)
	_add("notice_board", "Notice Board", 30.0, 30, 30, {"twig": 4}, false)
	_add("carrot_farm", "Carrot Farm", 30.0, 40, 40, {"twig": 3, "small_stone": 2}, false)
func _add(id: String, title: String, seconds: float, exp: int, coins: int, materials: Dictionary, unlocked: bool) -> void:
	var b := BuildingData.create(id, title, seconds, exp, unlocked); b.coin_cost = coins; b.material_costs = materials; buildings[id] = b
func setup(village_data: VillageData) -> void:
	data = village_data
	for id in data.unlocked_building_ids:
		if buildings.has(id): (buildings[id] as BuildingData).is_unlocked = true
func setup_economy(currency: CurrencyManager, inventory: InventoryManager, construction: ConstructionManager = null) -> void: currency_manager = currency; inventory_manager = inventory; construction_manager = construction
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
	if b == null: return {"ok": false, "reason": "unknown_building"}
	if not b.is_unlocked: return {"ok": false, "reason": "building_locked"}
	if has_building(id): return {"ok": false, "reason": "duplicate_building"}
	if not VALID_SLOTS.has(slot_id): return {"ok": false, "reason": "invalid_slot"}
	if get_used_slot_ids().has(slot_id): return {"ok": false, "reason": "slot_occupied"}
	if get_constructing_building() != null: return {"ok": false, "reason": "construction_active"}
	if currency_manager != null and not currency_manager.can_spend_coins(b.coin_cost): return {"ok": false, "reason": "insufficient_coins"}
	if inventory_manager != null:
		for item_id: String in b.material_costs:
			if not inventory_manager.has_item(item_id, int(b.material_costs[item_id])): return {"ok": false, "reason": "insufficient_material:" + item_id}
	return {"ok": true, "reason": ""}
func place_building(id: String, slot_id: String) -> Dictionary:
	var check := can_place_building(id, slot_id); if not check.ok: return check
	var b := get_building(id); var transaction_id := "placement_%s_%d" % [id, int(TimeManager.get_now() * 1000000.0)]; var spent_coin := false; var removed: Dictionary = {}
	if currency_manager != null and b.coin_cost > 0:
		spent_coin = currency_manager.spend_coins(b.coin_cost, "building_placement", transaction_id)
		if not spent_coin: return {"ok": false, "reason": "insufficient_coins"}
	if inventory_manager != null:
		for item_id: String in b.material_costs:
			var amount := int(b.material_costs[item_id])
			if not inventory_manager.remove_item(item_id, amount, "building_placement", transaction_id): _rollback(b, spent_coin, removed, transaction_id); return {"ok": false, "reason": "material_transaction_failed:" + item_id}
			removed[item_id] = amount
	var record := BuildingRecord.new(); record.building_id = id; record.slot_id = slot_id; record.placed_at = TimeManager.get_now(); data.building_records[id] = record.to_dict()
	if construction_manager != null:
		var started := construction_manager.start_construction(id)
		if not started.ok: data.building_records.erase(id); _rollback(b, spent_coin, removed, transaction_id); return started
		return {"ok": true, "reason": "", "record": record, "construction": started.record}
	return {"ok": true, "reason": "", "record": record}
func _rollback(b: BuildingData, spent_coin: bool, removed: Dictionary, transaction_id: String) -> void:
	if inventory_manager != null:
		for item_id: String in removed: inventory_manager.rollback_removed_item(item_id, int(removed[item_id]), "building_rollback", transaction_id)
	if spent_coin: currency_manager.rollback_spend(b.coin_cost, "building_rollback", transaction_id)
func reclaim_building(id: String) -> Dictionary:
	if not has_building(id): return {"ok": false, "reason": "missing_building"}
	if get_building_state(id) == BuildingState.CONSTRUCTING: return {"ok": false, "reason": "construction_active"}
	if is_building_completed(id): data.building_interactions["completed_once:" + id] = true
	data.building_records.erase(id); return {"ok": true, "reason": ""}
func adopt_completed_building(id: String, slot_id: String) -> bool:
	if not buildings.has(id) or not VALID_SLOTS.has(slot_id): return false
	unlock_building(id); var raw: Dictionary = data.building_records.get(id, {}); raw["building_id"] = id; raw["slot_id"] = slot_id; raw["state"] = BuildingState.COMPLETED; raw["placed_at"] = float(raw.get("placed_at", TimeManager.get_now())); raw["completed_at"] = maxf(float(raw.get("completed_at", 0.0)), TimeManager.get_now()); data.building_records[id] = raw; data.building_interactions["completed_once:" + id] = true; return true
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
func can_unlock_building(id: String) -> Dictionary:
	if not buildings.has(id): return {"ok": false, "reason": "unknown_building"}
	if data.unlocked_building_ids.has(id): return {"ok": false, "reason": "already_unlocked"}
	return {"ok": true, "reason": ""}
func unlock_building(id: String) -> bool:
	if not can_unlock_building(id).ok: return false
	data.unlocked_building_ids.append(id); (buildings[id] as BuildingData).is_unlocked = true; return true
func get_buildable_building(id: String) -> BuildableBuildingData:
	var result := BuildableBuildingData.new(); result.building_id = id; var b := get_building(id); result.unlocked = b != null and b.is_unlocked; result.available_to_build = result.unlocked and not has_building(id) and get_constructing_building() == null; return result
func get_building_slots() -> Array[BuildingSlotData]:
	var result: Array[BuildingSlotData] = []
	for id: String in VALID_SLOTS:
		var slot := BuildingSlotData.new(); slot.slot_id = id
		for raw: Dictionary in data.building_records.values():
			if str(raw.get("slot_id", "")) == id: slot.building_id = str(raw.get("building_id", "")); slot.state = str(raw.get("state", "occupied")); break
		result.append(slot)
	return result
