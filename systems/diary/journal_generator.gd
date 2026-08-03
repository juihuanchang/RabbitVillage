class_name JournalGenerator
extends RefCounted

const TEMPLATE_PATHS := {
	"forest_walk": "res://data/journals/forest_walk.json",
	"forest_explore": "res://data/journals/forest_explore.json",
	"fishing": "res://data/journals/fishing.json",
	"home_rest": "res://data/journals/home_rest.json"
}
const LEAF_MARK_PATH := "res://data/journals/leaf_mark.json"

static func generate(active: ActiveActivityData, journal_id: String) -> JournalEntry:
	if active == null or active.rabbit == null or active.activity == null:
		return null
	var template := _pick_activity_template(active.activity.activity_id)
	var title := str(template.get("title", "%s完成" % active.activity.activity_name))
	var content := str(template.get(
		"content",
		"{rabbit_name} 完成了%s，平安回到家。" % active.activity.activity_name
	)).replace("{rabbit_name}", active.rabbit.rabbit_name)
	var happened_at := active.completed_at if active.completed_at > 0.0 else TimeManager.get_now()
	return JournalEntry.new(
		journal_id,
		active.activity_record_id,
		_format_date(happened_at),
		active.activity.activity_id,
		active.rabbit.rabbit_name,
		title,
		content,
		happened_at,
		"home" if active.activity.activity_id == "home_rest" else "activity",
		active.activity.location_id,
		active.activity.location_name,
		active.get_stat_changes(),
		active.activity.reward_items
	)

static func generate_growth_journal(
		rabbit_name: String,
		journal_id: String,
		growth_mark_id: String,
		created_at: float = -1.0
) -> JournalEntry:
	if growth_mark_id != "leaf_mark":
		return null
	var data := _load_json(LEAF_MARK_PATH)
	if data.is_empty():
		return null
	var happened_at := TimeManager.get_now() if created_at <= 0.0 else created_at
	return JournalEntry.new(
		journal_id,
		"",
		_format_date(happened_at),
		"",
		rabbit_name,
		str(data.get("title", "耳朵旁的小葉子")),
		str(data.get("content", "")).replace("{rabbit_name}", rabbit_name),
		happened_at,
		"growth",
		str(data.get("location_id", "forest")),
		str(data.get("location_name", "森林")),
		{},
		[],
		growth_mark_id,
		false,
		false,
		true,
		str(data.get("illustration_id", "leaf_mark_memory"))
	)

static func _pick_activity_template(activity_id: String) -> Dictionary:
	var path := str(TEMPLATE_PATHS.get(activity_id, ""))
	if path.is_empty():
		return {}
	var data := _load_json(path)
	var templates: Variant = data.get("templates", [])
	if not (templates is Array) or templates.is_empty():
		return {}
	var chosen: Variant = templates.pick_random()
	return chosen.duplicate(true) if chosen is Dictionary else {}

static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Journal template not found: %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not (json.data is Dictionary):
		push_warning("Invalid journal template JSON: %s" % path)
		return {}
	return json.data

static func _format_date(unix_time: float) -> String:
	var data := Time.get_datetime_dict_from_unix_time(int(unix_time))
	return "%04d/%02d/%02d" % [data.year, data.month, data.day]
