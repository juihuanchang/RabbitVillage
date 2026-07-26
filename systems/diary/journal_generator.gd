class_name JournalGenerator
extends RefCounted


const TEMPLATE_PATHS: Dictionary = {
	"forest_walk": "res://data/journals/forest.json",
	"fishing": "res://data/journals/fishing.json"
}


## 根據完成的活動產生一篇正式日記。
static func generate(
		active_activity: ActiveActivityData,
		journal_id: String
) -> JournalEntry:
	if active_activity == null:
		push_error("JournalGenerator：活動資料不存在。")
		return null

	if active_activity.rabbit == null:
		push_error("JournalGenerator：找不到兔子資料。")
		return null

	if active_activity.activity == null:
		push_error("JournalGenerator：找不到活動資料。")
		return null

	if active_activity.activity_record_id.is_empty():
		push_error("JournalGenerator：活動紀錄編號不可為空。")
		return null

	if journal_id.strip_edges().is_empty():
		push_error("JournalGenerator：日記編號不可為空。")
		return null

	var activity_id := (
		active_activity.activity.activity_id
		.strip_edges()
		.to_lower()
	)

	if activity_id.is_empty():
		push_error("JournalGenerator：activity_id 不可為空。")
		return null

	var template_path := str(
		TEMPLATE_PATHS.get(activity_id, "")
	)

	if template_path.is_empty():
		push_error(
			"JournalGenerator：找不到對應的日記模板，activity_id：" +
			activity_id
		)
		return null

	var templates := _load_templates(template_path)
	var selected_template: Dictionary

	if templates.is_empty():
		push_warning(
			"JournalGenerator：模板讀取失敗，改用預設備用內容。"
		)

		selected_template = _get_fallback_template(
			activity_id
		)
	else:
		var selected_index := randi_range(
			0,
			templates.size() - 1
		)

		selected_template = templates[
			selected_index
		]

	var rabbit_name := (
		active_activity.rabbit.rabbit_name
		.strip_edges()
	)

	var title := str(
		selected_template.get(
			"title",
			"活動日記"
		)
	)

	var content := str(
		selected_template.get(
			"content",
			""
		)
	)

	title = title.replace(
		"{rabbit_name}",
		rabbit_name
	)

	content = content.replace(
		"{rabbit_name}",
		rabbit_name
	)

	var created_at := TimeManager.get_now()
	var date_text := _get_current_date()

	return JournalEntry.new(
		journal_id,
		active_activity.activity_record_id,
		date_text,
		activity_id,
		rabbit_name,
		title,
		content,
		created_at
	)


## 從指定 JSON 檔案讀取日記模板。
static func _load_templates(
		path: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if not FileAccess.file_exists(path):
		push_error(
			"JournalGenerator：找不到日記模板：" +
			path
		)
		return result

	var json_text := FileAccess.get_file_as_string(
		path
	)

	if json_text.strip_edges().is_empty():
		push_error(
			"JournalGenerator：日記模板內容為空：" +
			path
		)
		return result

	var json := JSON.new()
	var parse_error := json.parse(json_text)

	if parse_error != OK:
		push_error(
			"JournalGenerator：JSON 解析失敗：%s，第 %d 行"
			% [
				json.get_error_message(),
				json.get_error_line()
			]
		)
		return result

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error(
			"JournalGenerator：JSON 最外層必須是 Dictionary。"
		)
		return result

	var root := json.data as Dictionary
	var raw_templates: Variant = root.get(
		"templates",
		[]
	)

	if not (raw_templates is Array):
		push_error(
			"JournalGenerator：templates 必須是 Array。"
		)
		return result

	for item: Variant in raw_templates:
		if not (item is Dictionary):
			push_warning(
				"JournalGenerator：忽略格式錯誤的模板。"
			)
			continue

		var template := item as Dictionary
		var title := str(
			template.get("title", "")
		).strip_edges()

		var content := str(
			template.get("content", "")
		).strip_edges()

		if title.is_empty() or content.is_empty():
			push_warning(
				"JournalGenerator：忽略缺少標題或內容的模板。"
			)
			continue

		result.append({
			"title": title,
			"content": content
		})

	return result


## 取得目前系統日期，例如 2026/07/22。
static func _get_current_date() -> String:
	var current_date := Time.get_datetime_dict_from_system(
		false
	)

	return "%04d/%02d/%02d" % [
		int(current_date.get("year", 0)),
		int(current_date.get("month", 0)),
		int(current_date.get("day", 0))
	]


## JSON 無法讀取時仍建立基本日記，避免活動完全沒有紀錄。
static func _get_fallback_template(
		activity_id: String
) -> Dictionary:
	match activity_id:
		"forest_walk":
			return {
				"title": "森林散步",
				"content": (
					"{rabbit_name} 今天到森林裡散步，"
					+ "平安地回到了家。"
				)
			}

		"fishing":
			return {
				"title": "池邊時光",
				"content": (
					"{rabbit_name} 今天到池塘邊釣魚，"
					+ "度過了一段悠閒的時間。"
				)
			}

		_:
			return {
				"title": "活動日記",
				"content": (
					"{rabbit_name} 今天完成了一項活動。"
				)
			}