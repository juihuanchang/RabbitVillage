class_name JournalEntry
extends Resource


## 日記建立時間，使用 Unix 時間。
@export var created_at: int = 0

## 兔子的名字。
@export var rabbit_name: String = ""

## 完成的活動名稱。
@export var activity_name: String = ""

## 日記內容。
@export_multiline var content: String = ""


func _init(
		initial_rabbit_name: String = "",
		initial_activity_name: String = "",
		initial_content: String = "",
		initial_created_at: int = 0
) -> void:
	rabbit_name = initial_rabbit_name
	activity_name = initial_activity_name
	content = initial_content

	if initial_created_at <= 0:
		created_at = int(Time.get_unix_time_from_system())
	else:
		created_at = initial_created_at


## 將 JournalEntry 轉成可以存入 JSON 的 Dictionary。
func to_dict() -> Dictionary:
	return {
		"created_at": created_at,
		"rabbit_name": rabbit_name,
		"activity_name": activity_name,
		"content": content
	}


## 將存檔中的 Dictionary 還原成 JournalEntry。
static func from_dict(data: Dictionary) -> JournalEntry:
	return JournalEntry.new(
		str(data.get("rabbit_name", "")),
		str(data.get("activity_name", "")),
		str(data.get("content", "")),
		int(data.get("created_at", 0))
	)