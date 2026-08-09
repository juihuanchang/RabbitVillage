class_name JournalEntry
extends Resource

@export var journal_id := ""
@export var journal_type := "activity"
@export var rabbit_name := ""
@export var activity_record_id := ""
@export var date := ""
@export var activity_id := ""
@export var location_id := ""
@export var location_name := ""
@export var created_at := 0.0
@export var title := ""
@export_multiline var content := ""
@export var stat_changes: Dictionary = {}
@export var items: Array[String] = []
@export var growth_mark_id := ""
@export var is_read := false
@export var is_favorite := false
@export var is_special_memory := false
@export var illustration_id := ""
@export var village_event_id := ""
@export var building_id := ""
@export var construction_record_id := ""
@export var building_use_record_id := ""
@export var notice_id := ""
@export var notice_date := ""
@export var farm_cycle_id := ""
@export var harvest_record_id := ""
@export var village_stage := 0
@export var is_village_memory := false

func _init(initial_journal_id := "", initial_record_id := "", initial_date := "", initial_activity_id := "", initial_rabbit_name := "", initial_title := "", initial_content := "", initial_created_at := 0.0, initial_journal_type := "activity", initial_location_id := "", initial_location_name := "", initial_stat_changes := {}, initial_items: Array[String] = [], initial_growth_mark_id := "", initial_is_read := false, initial_is_favorite := false, initial_is_special_memory := false, initial_illustration_id := "") -> void:
    journal_id = initial_journal_id
    activity_record_id = initial_record_id
    date = initial_date
    activity_id = initial_activity_id
    rabbit_name = initial_rabbit_name
    title = initial_title
    content = initial_content
    created_at = TimeManager.get_now() if initial_created_at <= 0.0 else initial_created_at
    journal_type = initial_journal_type
    location_id = initial_location_id
    location_name = initial_location_name
    stat_changes = initial_stat_changes.duplicate(true)
    items.assign(initial_items)
    growth_mark_id = initial_growth_mark_id
    is_read = initial_is_read
    is_favorite = initial_is_favorite
    is_special_memory = initial_is_special_memory
    illustration_id = initial_illustration_id

func to_dict() -> Dictionary:
    return {
        "journal_id": journal_id, "journal_type": journal_type, "rabbit_name": rabbit_name,
        "activity_record_id": activity_record_id, "date": date, "activity_id": activity_id,
        "location_id": location_id, "location_name": location_name, "created_at": created_at,
        "title": title, "content": content, "stat_changes": stat_changes, "items": items,
        "growth_mark_id": growth_mark_id, "is_read": is_read, "is_favorite": is_favorite,
        "is_special_memory": is_special_memory, "illustration_id": illustration_id,
        "village_event_id": village_event_id, "building_id": building_id,
        "construction_record_id": construction_record_id, "building_use_record_id": building_use_record_id,
        "notice_id": notice_id, "notice_date": notice_date, "farm_cycle_id": farm_cycle_id,
        "harvest_record_id": harvest_record_id, "village_stage": village_stage,
        "is_village_memory": is_village_memory
    }

static func from_dict(data: Dictionary) -> JournalEntry:
    var loaded_items: Array[String] = []
    for item: Variant in data.get("items", data.get("Items", [])):
        loaded_items.append(str(item))
    var loaded_stats: Dictionary = {}
    var raw_stats: Variant = data.get("stat_changes", data.get("StatChanges", {}))
    if raw_stats is Dictionary:
        loaded_stats = raw_stats.duplicate(true)
    var activity_id_loaded := str(data.get("activity_id", data.get("ActivityId", "")))
    var location_id_loaded := str(data.get("location_id", data.get("LocationId", "")))
    var location_name_loaded := str(data.get("location_name", data.get("LocationName", "")))
    if location_id_loaded.is_empty():
        match activity_id_loaded:
            "forest_walk", "forest_explore":
                location_id_loaded = "forest"
                location_name_loaded = "森林"
            "fishing":
                location_id_loaded = "lake"
                location_name_loaded = "湖邊"
            "home_rest":
                location_id_loaded = "home"
                location_name_loaded = "家裡"
    var type_loaded := str(data.get("journal_type", data.get("JournalType", "activity")))
    if activity_id_loaded == "home_rest" and type_loaded == "activity":
        type_loaded = "home"
    var e := JournalEntry.new(
        str(data.get("journal_id", data.get("JournalId", ""))),
        str(data.get("activity_record_id", data.get("ActivityRecordId", ""))),
        str(data.get("date", data.get("CreatedDate", ""))), activity_id_loaded,
        str(data.get("rabbit_name", data.get("RabbitName", ""))), str(data.get("title", data.get("Title", ""))),
        str(data.get("content", data.get("Content", ""))), float(data.get("created_at", data.get("CreatedAt", 0.0))),
        type_loaded, location_id_loaded, location_name_loaded, loaded_stats, loaded_items,
        str(data.get("growth_mark_id", data.get("GrowthMarkId", ""))),
        bool(data.get("is_read", data.get("IsRead", false))), bool(data.get("is_favorite", data.get("IsFavorite", false))),
        bool(data.get("is_special_memory", data.get("IsSpecialMemory", false))), str(data.get("illustration_id", data.get("IllustrationId", ""))))
    e.village_event_id = str(data.get("village_event_id", data.get("VillageEventId", "")))
    e.building_id = str(data.get("building_id", data.get("BuildingId", "")))
    e.construction_record_id = str(data.get("construction_record_id", data.get("ConstructionRecordId", "")))
    e.building_use_record_id = str(data.get("building_use_record_id", data.get("BuildingUseRecordId", "")))
    e.notice_id = str(data.get("notice_id", data.get("NoticeId", "")))
    e.notice_date = str(data.get("notice_date", data.get("NoticeDate", "")))
    e.farm_cycle_id = str(data.get("farm_cycle_id", data.get("FarmCycleId", "")))
    e.harvest_record_id = str(data.get("harvest_record_id", data.get("HarvestRecordId", "")))
    e.village_stage = maxi(0, int(data.get("village_stage", data.get("VillageStage", 0))))
    e.is_village_memory = bool(data.get("is_village_memory", data.get("IsVillageMemory", false)))
    return e

func is_valid() -> bool:
    if journal_id.is_empty() or title.is_empty() or content.is_empty():
        return false
    match journal_type:
        "growth": return not growth_mark_id.is_empty()
        "activity", "home": return not activity_record_id.is_empty() and not activity_id.is_empty()
        "village_event": return not village_event_id.is_empty()
        "construction", "building_complete": return not construction_record_id.is_empty() and not building_id.is_empty()
        "building_use": return not building_use_record_id.is_empty() and not building_id.is_empty()
        "notice": return not notice_id.is_empty() and not notice_date.is_empty()
        "farm_growth": return not farm_cycle_id.is_empty()
        "harvest": return not harvest_record_id.is_empty() and not farm_cycle_id.is_empty()
        "village_growth": return village_stage > 0
    return true
