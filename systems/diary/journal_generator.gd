class_name JournalGenerator
extends RefCounted


const FOREST_TEMPLATE_PATH := "res://data/journals/forest.json"


## 根據完成的活動產生日記。
static func generate(active_activity: ActiveActivityData) -> JournalEntry:
	if active_activity == null:
		push_error("JournalGenerator：active_activity 不可為 null")
		return null

	if active_activity.rabbit == null:
		push_error("JournalGenerator：找不到 RabbitData")
		return null

	if active_activity.activity == null:
		push_error("JournalGenerator：找不到 ActivityData")
		return null

	var rabbit_name := active_activity.rabbit.rabbit_name
	var activity_name := active_activity.activity.activity_name

	match activity_name:
		"森林散步":
			return _generate_forest_journal(rabbit_name, activity_name)
		_:
			return _generate_default_journal(rabbit_name, activity_name)


## 產生森林日記。
static func _generate_forest_journal(
		rabbit_name: String,
		activity_name: String
) -> JournalEntry:
	var templates := _load_templates(FOREST_TEMPLATE_PATH)

	if templates.is_empty():
		var fallback_content := (
			"今天%s去了森林。\n\n回家時撿了一片葉子。"
			% rabbit_name
		)

		return JournalEntry.new(
			rabbit_name,
			activity_name,
			fallback_content
		)

	var selected_template: String = templates.pick_random()
	var content := selected_template.replace(
		"{rabbit_name}",
		rabbit_name
	)

	return JournalEntry.new(
		rabbit_name,
		activity_name,
		content
	)


## 其他活動還沒有模板時，使用預設內容。
static func _generate_default_journal(
		rabbit_name: String,
		activity_name: String
) -> JournalEntry:
	var content := "今天%s完成了「%s」。" % [
		rabbit_name,
		activity_name
	]

	return JournalEntry.new(
		rabbit_name,
		activity_name,
		content
	)


## 從 JSON 讀取日記模板。
static func _load_templates(path: String) -> Array[String]:
	var result: Array[String] = []

	if not FileAccess.file_exists(path):
		push_error("找不到日記模板：" + path)
		return result

	var json_text := FileAccess.get_file_as_string(path)
	var parsed_data: Variant = JSON.parse_string(json_text)

	if typeof(parsed_data) != TYPE_DICTIONARY:
		push_error("日記模板格式錯誤：" + path)
		return result

	var data := parsed_data as Dictionary
	var template_data: Variant = data.get("templates", [])

	if not (template_data is Array):
		push_error("templates 必須是 Array")
		return result

	for item: Variant in template_data:
		if item is String and not item.is_empty():
			result.append(item)

	return result