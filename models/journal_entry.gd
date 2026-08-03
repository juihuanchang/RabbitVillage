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

func _init(
		initial_journal_id := "",
		initial_record_id := "",
		initial_date := "",
		initial_activity_id := "",
		initial_rabbit_name := "",
		initial_title := "",
		initial_content := "",
		initial_created_at := 0.0,
		initial_journal_type := "activity",
		initial_location_id := "",
		initial_location_name := "",
		initial_stat_changes := {},
		initial_items: Array[String] = [],
		initial_growth_mark_id := "",
		initial_is_read := false,
		initial_is_favorite := false,
		initial_is_special_memory := false,
		initial_illustration_id := ""
) -> void:
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
		"journal_id": journal_id,
		"journal_type": journal_type,
		"rabbit_name": rabbit_name,
		"activity_record_id": activity_record_id,
		"date": date,
		"activity_id": activity_id,
		"location_id": location_id,
		"location_name": location_name,
		"created_at": created_at,
		"title": title,
		"content": content,
		"stat_changes": stat_changes,
		"items": items,
		"growth_mark_id": growth_mark_id,
		"is_read": is_read,
		"is_favorite": is_favorite,
		"is_special_memory": is_special_memory,
		"illustration_id": illustration_id
	}

static func from_dict(data: Dictionary) -> JournalEntry:
	var loaded_items: Array[String] = []
	for item: Variant in data.get("items", data.get("Items", [])):
		loaded_items.append(str(item))
	var loaded_stats: Dictionary = {}
	var raw_stats: Variant = data.get("stat_changes", data.get("StatChanges", {}))
	if raw_stats is Dictionary:
		loaded_stats = raw_stats.duplicate(true)
	var loaded_activity_id := str(data.get("activity_id", data.get("ActivityId", "")))
	var loaded_location_id := str(data.get("location_id", data.get("LocationId", "")))
	var loaded_location_name := str(data.get("location_name", data.get("LocationName", "")))
	if loaded_location_id.is_empty():
		match loaded_activity_id:
			"forest_walk", "forest_explore":
				loaded_location_id = "forest"
				loaded_location_name = "森林"
			"fishing":
				loaded_location_id = "lake"
				loaded_location_name = "湖邊"
			"home_rest":
				loaded_location_id = "home"
				loaded_location_name = "家裡"
	var loaded_journal_type := str(data.get("journal_type", data.get("JournalType", "activity")))
	if loaded_activity_id == "home_rest" and loaded_journal_type == "activity":
		loaded_journal_type = "home"
	return JournalEntry.new(
		str(data.get("journal_id", data.get("JournalId", ""))),
		str(data.get("activity_record_id", data.get("ActivityRecordId", ""))),
		str(data.get("date", data.get("CreatedDate", ""))),
		loaded_activity_id,
		str(data.get("rabbit_name", data.get("RabbitName", ""))),
		str(data.get("title", data.get("Title", ""))),
		str(data.get("content", data.get("Content", ""))),
		float(data.get("created_at", data.get("CreatedAt", 0.0))),
		loaded_journal_type,
		loaded_location_id,
		loaded_location_name,
		loaded_stats,
		loaded_items,
		str(data.get("growth_mark_id", data.get("GrowthMarkId", ""))),
		bool(data.get("is_read", data.get("IsRead", false))),
		bool(data.get("is_favorite", data.get("IsFavorite", false))),
		bool(data.get("is_special_memory", data.get("IsSpecialMemory", false))),
		str(data.get("illustration_id", data.get("IllustrationId", "")))
	)

func is_valid() -> bool:
	if journal_id.is_empty() or title.is_empty() or content.is_empty():
		return false
	if journal_type == "growth":
		return not growth_mark_id.is_empty()
	return not activity_record_id.is_empty() and not activity_id.is_empty()
