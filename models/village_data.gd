class_name VillageData
extends Resource

const FORMAL_BUILDINGS := ["coffee_shop", "rest_pavilion", "notice_board", "carrot_farm"]
const VALID_SLOTS := ["Slot01", "Slot02", "Slot03", "Slot04", "Slot05", "Slot06", "Slot07", "Slot08", "Slot09"]

@export var progress: VillageProgressData = VillageProgressData.new()
@export var conditions: VillageConditionData = VillageConditionData.new()
@export var unlocked_building_ids: Array[String] = []
@export var completed_village_event_ids: Array[String] = []
@export var pending_village_events: Array[Dictionary] = []
@export var building_records: Dictionary = {}
@export var active_construction: Dictionary = {}
@export var completed_construction_ids: Array[String] = []
@export var building_interactions: Dictionary = {}
@export var active_building_interaction: Dictionary = {}
@export var daily_notice: Dictionary = {}
@export var notice_history: Array[Dictionary] = []
@export var farm: Dictionary = {}
@export var building_history: Array[Dictionary] = []
@export var construction_records: Array[Dictionary] = []
@export var building_interaction_records: Array[Dictionary] = []
@export var farm_cycle_records: Array[Dictionary] = []
@export var harvest_records: Array[Dictionary] = []
@export var carrot_inventory: Dictionary = {"food_id": "carrot", "amount": 0, "first_obtained_at": 0.0, "last_obtained_at": 0.0, "total_obtained": 0}
@export var legacy_a_snapshot: Dictionary = {}

func to_dict() -> Dictionary:
    return {
        "progress": progress.to_dict(), "conditions": conditions.to_dict(),
        "unlocked_building_ids": unlocked_building_ids.duplicate(), "completed_village_event_ids": completed_village_event_ids.duplicate(),
        "pending_village_events": pending_village_events.duplicate(true), "building_records": building_records.duplicate(true),
        "active_construction": active_construction.duplicate(true), "completed_construction_ids": completed_construction_ids.duplicate(),
        "building_interactions": building_interactions.duplicate(true), "active_building_interaction": active_building_interaction.duplicate(true),
        "daily_notice": daily_notice.duplicate(true), "notice_history": notice_history.duplicate(true),
        "farm": farm.duplicate(true), "building_history": building_history.duplicate(true),
        "construction_records": construction_records.duplicate(true), "building_interaction_records": building_interaction_records.duplicate(true),
        "farm_cycle_records": farm_cycle_records.duplicate(true), "harvest_records": harvest_records.duplicate(true),
        "carrot_inventory": carrot_inventory.duplicate(true), "legacy_a_snapshot": legacy_a_snapshot.duplicate(true)
    }

static func from_dict(data: Dictionary) -> VillageData:
    var v := VillageData.new()
    if data.get("progress", {}) is Dictionary:
        v.progress = VillageProgressData.from_dict(data.get("progress", {}))
    if data.get("conditions", {}) is Dictionary:
        v.conditions = VillageConditionData.from_dict(data.get("conditions", {}))
    for id: Variant in data.get("unlocked_building_ids", []):
        var building_id := str(id)
        if FORMAL_BUILDINGS.has(building_id) and not v.unlocked_building_ids.has(building_id):
            v.unlocked_building_ids.append(building_id)
    for id: Variant in data.get("completed_village_event_ids", []):
        var event_id := _migrate_event_id(str(id))
        if not event_id.is_empty() and not v.completed_village_event_ids.has(event_id):
            v.completed_village_event_ids.append(event_id)
    for raw_event: Variant in data.get("pending_village_events", []):
        if raw_event is Dictionary:
            var event = raw_event.duplicate(true)
            event["event_id"] = _migrate_event_id(str(event.get("event_id", "")))
            if not str(event.get("event_id", "")).is_empty():
                v.pending_village_events.append(event)
    for id: Variant in data.get("completed_construction_ids", []):
        v.completed_construction_ids.append(str(id))
    if data.get("building_interactions", {}) is Dictionary:
        v.building_interactions = data.get("building_interactions", {}).duplicate(true)
    if data.get("active_building_interaction", {}) is Dictionary:
        v.active_building_interaction = data.get("active_building_interaction", {}).duplicate(true)
    if data.get("active_construction", {}) is Dictionary:
        v.active_construction = _sanitize_construction(data.get("active_construction", {}))
    var raw_buildings: Variant = data.get("building_records", {})
    if raw_buildings is Dictionary:
        for key: Variant in raw_buildings.keys():
            var raw: Variant = raw_buildings[key]
            if not (raw is Dictionary):
                continue
            var building_id := str(raw.get("building_id", key))
            if building_id == "cafe":
                building_id = "coffee_shop"
            if not FORMAL_BUILDINGS.has(building_id):
                continue
            var clean = raw.duplicate(true)
            clean["building_id"] = building_id
            var slot_id := str(clean.get("slot_id", ""))
            if not slot_id.is_empty() and not VALID_SLOTS.has(slot_id):
                clean["slot_id"] = ""
            v.building_records[building_id] = clean
    var notice_source: Variant = data.get("notice_history", data.get("notices", []))
    if notice_source is Array:
        for raw_notice: Variant in notice_source:
            if raw_notice is Dictionary and not str(raw_notice.get("date_key", "")).is_empty():
                v.notice_history.append(raw_notice.duplicate(true))
    if data.get("daily_notice", {}) is Dictionary:
        v.daily_notice = data.get("daily_notice", {}).duplicate(true)
    if data.get("farm", {}) is Dictionary:
        v.farm = _sanitize_farm(data.get("farm", {}))
    var legacy_carrot_amount := maxi(0, int(data.get("carrot_amount", 0)))
    for raw_history: Variant in data.get("building_history", []):
        if raw_history is Dictionary:
            var history := BuildingHistoryEntry.from_dict(raw_history)
            if not history.building_id.is_empty():
                v.building_history.append(history.to_dict())
    _copy_dict_array(data.get("construction_records", []), v.construction_records)
    _copy_dict_array(data.get("building_interaction_records", []), v.building_interaction_records)
    _copy_dict_array(data.get("farm_cycle_records", []), v.farm_cycle_records)
    _copy_dict_array(data.get("harvest_records", []), v.harvest_records)
    if data.get("legacy_a_snapshot", {}) is Dictionary:
        v.legacy_a_snapshot = data.get("legacy_a_snapshot", {}).duplicate(true)
    var raw_inventory: Dictionary = data.get("carrot_inventory", {}) if data.get("carrot_inventory", {}) is Dictionary else {}
    var inventory := CarrotInventoryEntry.from_dict(raw_inventory)
    inventory.amount = maxi(inventory.amount, legacy_carrot_amount)
    inventory.total_obtained = maxi(inventory.total_obtained, maxi(inventory.amount, v.progress.total_carrots_obtained))
    v.carrot_inventory = inventory.to_dict()
    return v

static func create_migrated_week3_default() -> VillageData:
    var v := VillageData.new()
    v.progress.village_level = 0
    v.progress.village_experience = 0
    v.farm = FarmData.new().to_dict()
    v.farm["state"] = FarmState.LOCKED
    return v

static func _migrate_event_id(id: String) -> String:
    if id == "village_carrot_farm_001":
        return "village_small_farm_001"
    return id

static func _sanitize_construction(raw: Dictionary) -> Dictionary:
    var result := raw.duplicate(true)
    var building_id := str(result.get("building_id", ""))
    if not FORMAL_BUILDINGS.has(building_id):
        return {}
    var slot_id := str(result.get("slot_id", ""))
    if not slot_id.is_empty() and not VALID_SLOTS.has(slot_id):
        result["slot_id"] = ""
    for key in ["started_at", "ends_at", "completed_at"]:
        result[key] = maxf(0.0, float(result.get(key, 0.0)))
    if float(result.get("ends_at", 0.0)) < float(result.get("started_at", 0.0)):
        result["ends_at"] = float(result.get("started_at", 0.0))
    return result

static func _sanitize_farm(raw: Dictionary) -> Dictionary:
    var farm_data := FarmData.from_dict(raw)
    var valid_states := [FarmState.LOCKED, FarmState.IDLE, FarmState.GROWING, FarmState.READY]
    if not valid_states.has(farm_data.state):
        farm_data.state = FarmState.LOCKED
    if not farm_data.current_cycle.is_empty():
        var cycle := FarmCycleData.from_dict(farm_data.current_cycle)
        if cycle.farm_cycle_id.is_empty() or cycle.ready_at < cycle.started_at:
            farm_data.current_cycle = {}
            farm_data.state = FarmState.IDLE
        else:
            farm_data.current_cycle = cycle.to_dict()
    return farm_data.to_dict()

static func _copy_dict_array(source: Variant, target: Array[Dictionary]) -> void:
    if not (source is Array):
        return
    for raw: Variant in source:
        if raw is Dictionary:
            target.append(raw.duplicate(true))
