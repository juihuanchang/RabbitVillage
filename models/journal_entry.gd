class_name JournalEntry
extends Resource

@export var journal_id := ""
@export var activity_record_id := ""
@export var date := ""
@export var activity_id := ""
@export var rabbit_name := ""
@export var title := ""
@export_multiline var content := ""
@export var created_at := 0.0

func _init(
		initial_journal_id := "",
		initial_record_id := "",
		initial_date := "",
		initial_activity_id := "",
		initial_rabbit_name := "",
		initial_title := "",
		initial_content := "",
		initial_created_at := 0.0
) -> void:
	journal_id = initial_journal_id
	activity_record_id = initial_record_id
	date = initial_date
	activity_id = initial_activity_id
	rabbit_name = initial_rabbit_name
	title = initial_title
	content = initial_content
	created_at = TimeManager.get_now() if initial_created_at <= 0.0 else initial_created_at

func to_dict() -> Dictionary:
	return {
		"journal_id": journal_id, "activity_record_id": activity_record_id,
		"date": date, "activity_id": activity_id, "rabbit_name": rabbit_name,
		"title": title, "content": content, "created_at": created_at
	}

static func from_dict(data: Dictionary) -> JournalEntry:
	return JournalEntry.new(
		str(data.get("journal_id", "")), str(data.get("activity_record_id", "")),
		str(data.get("date", "")), str(data.get("activity_id", "")),
		str(data.get("rabbit_name", "")), str(data.get("title", "")),
		str(data.get("content", "")), float(data.get("created_at", 0.0))
	)

func is_valid() -> bool:
	return not journal_id.is_empty() and not activity_record_id.is_empty() and not activity_id.is_empty()
