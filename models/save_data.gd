class_name SaveData
extends Resource

const CURRENT_VERSION := 5
var save_version := CURRENT_VERSION
var rabbits: Array[Dictionary] = []
var current_activity: Dictionary = {}
var journals: Array[Dictionary] = []
var completed_activity_ids: Array[String] = []
var last_saved_at := 0.0
var forest_experience := 0
var fishing_experience := 0
var intimacy := 0
var forest_activity_count := 0
var fishing_activity_count := 0
var home_activity_count := 0
var total_activity_count := 0
var all_activity_records: Array[Dictionary] = []
var unlocked_growth_marks: Array[Dictionary] = []
var pending_growth_event: Dictionary = {}
var growth_album_entries: Array[Dictionary] = []
var growth_tendencies: Dictionary = {"forest": 0, "lake": 0, "home": 0}
var village_data: Dictionary = {}
var village_progress: Dictionary = {"village_level": 0, "village_experience": 0}
var pending_village_events: Array[Dictionary] = []
var completed_village_event_ids: Array[String] = []
var buildings: Dictionary = {}
var construction_records: Array[Dictionary] = []
var building_interaction_records: Array[Dictionary] = []
var daily_notice: Dictionary = {}
var notice_history: Array[Dictionary] = []
var farm_data: Dictionary = {}
var farm_cycle_records: Array[Dictionary] = []
var harvest_records: Array[Dictionary] = []
var carrot_inventory: Dictionary = {"food_id": "carrot", "amount": 0, "first_obtained_at": 0.0, "last_obtained_at": 0.0, "total_obtained": 0}
var village_journals: Array[Dictionary] = []
var building_history: Array[Dictionary] = []

func to_dict() -> Dictionary:
    return {
        "save_version": save_version, "rabbits": rabbits, "current_activity": current_activity, "journals": journals,
        "completed_activity_ids": completed_activity_ids, "last_saved_at": last_saved_at,
        "forest_experience": forest_experience, "fishing_experience": fishing_experience, "intimacy": intimacy,
        "forest_activity_count": forest_activity_count, "fishing_activity_count": fishing_activity_count,
        "home_activity_count": home_activity_count, "total_activity_count": total_activity_count,
        "all_activity_records": all_activity_records, "unlocked_growth_marks": unlocked_growth_marks,
        "pending_growth_event": pending_growth_event, "growth_album_entries": growth_album_entries,
        "growth_tendencies": growth_tendencies, "village_data": village_data, "village_progress": village_progress,
        "pending_village_events": pending_village_events, "completed_village_event_ids": completed_village_event_ids,
        "buildings": buildings, "construction_records": construction_records,
        "building_interaction_records": building_interaction_records, "daily_notice": daily_notice,
        "notice_history": notice_history, "farm_data": farm_data, "farm_cycle_records": farm_cycle_records,
        "harvest_records": harvest_records, "carrot_inventory": carrot_inventory,
        "village_journals": village_journals, "building_history": building_history
    }

static func from_dict(data: Dictionary) -> SaveData:
    var r := SaveData.new()
    r.save_version = int(data.get("save_version", data.get("version", 1)))
    _copy_dict_array(data.get("rabbits", []), r.rabbits)
    if data.get("current_activity", {}) is Dictionary: r.current_activity = data.get("current_activity", {}).duplicate(true)
    _copy_dict_array(data.get("journals", []), r.journals)
    for id: Variant in data.get("completed_activity_ids", []): r.completed_activity_ids.append(str(id))
    r.last_saved_at = maxf(0.0, float(data.get("last_saved_at", 0.0)))
    r.forest_experience = maxi(0, int(data.get("forest_experience", 0)))
    r.fishing_experience = maxi(0, int(data.get("fishing_experience", 0)))
    r.intimacy = maxi(0, int(data.get("intimacy", 0)))
    r.forest_activity_count = maxi(0, int(data.get("forest_activity_count", 0)))
    r.fishing_activity_count = maxi(0, int(data.get("fishing_activity_count", 0)))
    r.home_activity_count = maxi(0, int(data.get("home_activity_count", 0)))
    r.total_activity_count = maxi(0, int(data.get("total_activity_count", 0)))
    _copy_dict_array(data.get("all_activity_records", []), r.all_activity_records)
    for item: Variant in data.get("unlocked_growth_marks", []):
        if item is Dictionary: r.unlocked_growth_marks.append(item.duplicate(true))
        else: r.unlocked_growth_marks.append({"id": str(item), "is_unlocked": true, "unlocked_at": 0.0})
    if data.get("pending_growth_event", {}) is Dictionary: r.pending_growth_event = data.get("pending_growth_event", {}).duplicate(true)
    _copy_dict_array(data.get("growth_album_entries", []), r.growth_album_entries)
    if data.get("growth_tendencies", {}) is Dictionary: r.growth_tendencies = data.get("growth_tendencies", {}).duplicate(true)
    if data.get("village_data", {}) is Dictionary: r.village_data = data.get("village_data", {}).duplicate(true)
    if data.get("village_progress", {}) is Dictionary: r.village_progress = data.get("village_progress", {}).duplicate(true)
    _copy_dict_array(data.get("pending_village_events", []), r.pending_village_events)
    for id: Variant in data.get("completed_village_event_ids", []): r.completed_village_event_ids.append(str(id))
    if data.get("buildings", {}) is Dictionary: r.buildings = data.get("buildings", {}).duplicate(true)
    _copy_dict_array(data.get("construction_records", []), r.construction_records)
    _copy_dict_array(data.get("building_interaction_records", []), r.building_interaction_records)
    if data.get("daily_notice", {}) is Dictionary: r.daily_notice = data.get("daily_notice", {}).duplicate(true)
    _copy_dict_array(data.get("notice_history", []), r.notice_history)
    if data.get("farm_data", {}) is Dictionary: r.farm_data = data.get("farm_data", {}).duplicate(true)
    _copy_dict_array(data.get("farm_cycle_records", []), r.farm_cycle_records)
    _copy_dict_array(data.get("harvest_records", []), r.harvest_records)
    if data.get("carrot_inventory", {}) is Dictionary: r.carrot_inventory = CarrotInventoryEntry.from_dict(data.get("carrot_inventory", {})).to_dict()
    _copy_dict_array(data.get("village_journals", []), r.village_journals)
    _copy_dict_array(data.get("building_history", []), r.building_history)
    return r

func is_supported_version() -> bool:
    return save_version >= 1 and save_version <= CURRENT_VERSION

func is_week3_or_older() -> bool:
    return save_version <= 4

static func _copy_dict_array(source: Variant, target: Array[Dictionary]) -> void:
    if not (source is Array): return
    for item: Variant in source:
        if item is Dictionary: target.append(item.duplicate(true))
