class_name JournalEntry
extends Resource


## 日記編號，例如 journal_001。
@export var journal_id: String = ""

## 活動紀錄編號，例如 activity_1721234567890_1234。
## 同一個活動紀錄只能產生一篇日記。
@export var activity_record_id: String = ""

## 日期，例如 2026/07/22。
@export var date: String = ""

## 活動編號，例如 forest_walk、fishing。
@export var activity_id: String = ""

## 兔子名稱，例如 Amy。
@export var rabbit_name: String = ""

## 日記標題。
@export var title: String = ""

## 日記內容。
@export_multiline var content: String = ""

## 日記建立時的 Unix 時間，用於精確排序。
@export var created_at: float = 0.0


func _init(
		initial_journal_id: String = "",
		initial_activity_record_id: String = "",
		initial_date: String = "",
		initial_activity_id: String = "",
		initial_rabbit_name: String = "",
		initial_title: String = "",
		initial_content: String = "",
		initial_created_at: float = 0.0
) -> void:
	journal_id = initial_journal_id.strip_edges()
	activity_record_id = initial_activity_record_id.strip_edges()
	date = initial_date.strip_edges()
	activity_id = initial_activity_id.strip_edges().to_lower()
	rabbit_name = initial_rabbit_name.strip_edges()
	title = initial_title.strip_edges()
	content = initial_content.strip_edges()

	if initial_created_at <= 0.0:
		created_at = Time.get_unix_time_from_system()
	else:
		created_at = initial_created_at


## 將日記轉成可寫入 JSON 的 Dictionary。
func to_dict() -> Dictionary:
	return {
		"journal_id": journal_id,
		"activity_record_id": activity_record_id,
		"date": date,
		"activity_id": activity_id,
		"rabbit_name": rabbit_name,
		"title": title,
		"content": content,
		"created_at": created_at
	}


## 將存檔中的 Dictionary 還原成 JournalEntry。
static func from_dict(data: Dictionary) -> JournalEntry:
	return JournalEntry.new(
		str(data.get("journal_id", "")),
		str(data.get("activity_record_id", "")),
		str(data.get("date", "")),
		str(data.get("activity_id", "")),
		str(data.get("rabbit_name", "")),
		str(data.get("title", "")),
		str(data.get("content", "")),
		float(data.get("created_at", 0.0))
	)


## 檢查是否具備一篇正式日記所需的基本資料。
func is_valid() -> bool:
	return (
		not journal_id.is_empty()
		and not activity_record_id.is_empty()
		and not date.is_empty()
		and not activity_id.is_empty()
		and not title.is_empty()
		and not content.is_empty()
	)