class_name VillageHistoryManager
extends Node

signal history_changed
signal carrot_inventory_changed(inventory: CarrotInventoryEntry)
var data: VillageData

func setup(village_data: VillageData) -> void:
    data = village_data
    _repair_inventory()

func add_building_history(entry: BuildingHistoryEntry) -> bool:
    if data == null or entry == null or entry.building_id.is_empty(): return false
    for i in data.building_history.size():
        var existing := BuildingHistoryEntry.from_dict(data.building_history[i])
        if existing.building_id == entry.building_id:
            _merge_building_history(existing, entry)
            data.building_history[i] = existing.to_dict()
            history_changed.emit()
            return true
    data.building_history.append(entry.to_dict())
    history_changed.emit()
    return true

func add_construction_history(entry: ConstructionHistoryEntry) -> bool:
    if data == null or entry == null or entry.construction_record_id.is_empty() or _has_record(data.construction_records, "construction_record_id", entry.construction_record_id): return false
    data.construction_records.append(entry.to_dict()); history_changed.emit(); return true
func update_construction_completed(record_id: String, completed_at: float) -> bool:
    for i in data.construction_records.size():
        if str(data.construction_records[i].get("construction_record_id", "")) == record_id:
            data.construction_records[i]["completed_at"] = maxf(0.0, completed_at); history_changed.emit(); return true
    return false
func add_building_use_history(entry: BuildingUseHistoryEntry) -> bool:
    if data == null or entry == null or entry.building_use_record_id.is_empty() or _has_record(data.building_interaction_records, "building_use_record_id", entry.building_use_record_id): return false
    data.building_interaction_records.append(entry.to_dict()); history_changed.emit(); return true
func add_farm_cycle_history(entry: FarmCycleHistoryEntry) -> bool:
    if data == null or entry == null or entry.farm_cycle_id.is_empty() or _has_record(data.farm_cycle_records, "farm_cycle_id", entry.farm_cycle_id): return false
    data.farm_cycle_records.append(entry.to_dict()); history_changed.emit(); return true
func mark_farm_cycle_harvested(id: String, at_time: float, amount: int) -> bool:
    for i in data.farm_cycle_records.size():
        if str(data.farm_cycle_records[i].get("farm_cycle_id", "")) == id:
            data.farm_cycle_records[i]["harvested_at"] = maxf(0.0, at_time)
            data.farm_cycle_records[i]["harvest_amount"] = maxi(0, amount)
            data.farm_cycle_records[i]["is_harvested"] = true
            history_changed.emit(); return true
    return false
func add_harvest_history(entry: HarvestHistoryEntry) -> bool:
    if data == null or entry == null or entry.harvest_record_id.is_empty() or _has_record(data.harvest_records, "harvest_record_id", entry.harvest_record_id): return false
    data.harvest_records.append(entry.to_dict()); history_changed.emit(); return true
func add_carrots(amount: int, at_time: float = -1.0) -> CarrotInventoryEntry:
    var inv := get_carrot_inventory()
    inv.add(maxi(0, amount), at_time)
    data.carrot_inventory = inv.to_dict(); data.carrot_amount = inv.amount
    carrot_inventory_changed.emit(inv); history_changed.emit(); return inv
func get_carrot_inventory() -> CarrotInventoryEntry:
    return CarrotInventoryEntry.from_dict(data.carrot_inventory) if data != null else CarrotInventoryEntry.new()
func mark_building_unlocked(id: String, at_time: float) -> void:
    var e := BuildingHistoryEntry.new(); e.building_id = id; e.unlocked_at = at_time; add_building_history(e)
func mark_building_placed(id: String, slot: String, at_time: float) -> void:
    var e := BuildingHistoryEntry.new(); e.building_id = id; e.slot_id = slot; e.placed_at = at_time; add_building_history(e)
func mark_building_construction_started(id: String, slot: String, at_time: float) -> void:
    var e := BuildingHistoryEntry.new(); e.building_id = id; e.slot_id = slot; e.construction_started_at = at_time; add_building_history(e)
func mark_building_completed(id: String, slot: String, at_time: float) -> void:
    var e := BuildingHistoryEntry.new(); e.building_id = id; e.slot_id = slot; e.completed_at = at_time; add_building_history(e)
func mark_building_used(id: String, at_time: float, count: int) -> void:
    var e := BuildingHistoryEntry.new(); e.building_id = id; e.last_used_at = at_time; e.use_count = count
    if count <= 1: e.first_used_at = at_time
    add_building_history(e)
func _has_record(records: Array[Dictionary], key: String, id: String) -> bool:
    for raw in records:
        if str(raw.get(key, "")) == id: return true
    return false
func _merge_building_history(target: BuildingHistoryEntry, source: BuildingHistoryEntry) -> void:
    if target.slot_id.is_empty() and not source.slot_id.is_empty(): target.slot_id = source.slot_id
    for key in ["unlocked_at", "placed_at", "construction_started_at", "completed_at", "first_used_at"]:
        var current := float(target.get(key)); var incoming := float(source.get(key))
        if current <= 0.0 and incoming > 0.0: target.set(key, incoming)
    if source.last_used_at > target.last_used_at: target.last_used_at = source.last_used_at
    target.use_count = maxi(target.use_count, source.use_count)
func _repair_inventory() -> void:
    if data == null: return
    var inv := CarrotInventoryEntry.from_dict(data.carrot_inventory)
    if inv.amount == 0 and data.carrot_amount > 0:
        inv.amount = maxi(0, data.carrot_amount); inv.total_obtained = maxi(inv.total_obtained, inv.amount)
    data.carrot_inventory = inv.to_dict(); data.carrot_amount = inv.amount
func AddBuildingHistory(entry: BuildingHistoryEntry) -> bool: return add_building_history(entry)
func AddConstructionHistory(entry: ConstructionHistoryEntry) -> bool: return add_construction_history(entry)
func AddBuildingUseHistory(entry: BuildingUseHistoryEntry) -> bool: return add_building_use_history(entry)
func AddFarmCycleHistory(entry: FarmCycleHistoryEntry) -> bool: return add_farm_cycle_history(entry)
func AddHarvestHistory(entry: HarvestHistoryEntry) -> bool: return add_harvest_history(entry)
func GetCarrotInventory() -> CarrotInventoryEntry: return get_carrot_inventory()
