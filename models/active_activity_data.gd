class_name ActiveActivityData
extends Resource


## 每次活動的唯一紀錄編號，用來避免重複產生日記。
@export var activity_record_id: String = ""

@export var rabbit: RabbitData
@export var activity: ActivityData

## 使用真實世界 Unix 時間。
@export var started_at: float = 0.0
@export var ends_at: float = 0.0

## 活動是否已經完成。
@export var is_completed: bool = false


func _init(
		initial_rabbit: RabbitData = null,
		initial_activity: ActivityData = null,
		initial_started_at: float = 0.0,
		initial_record_id: String = "",
		initial_ends_at: float = -1.0,
		initial_is_completed: bool = false
) -> void:
	rabbit = initial_rabbit
	activity = initial_activity
	started_at = initial_started_at
	is_completed = initial_is_completed

	# 新活動自動建立唯一活動紀錄編號。
	if initial_record_id.is_empty():
		activity_record_id = _generate_activity_record_id()
	else:
		activity_record_id = initial_record_id

	# 讀檔時使用存檔中的 ends_at；
	# 新活動則依活動時間自動計算。
	if initial_ends_at >= 0.0:
		ends_at = initial_ends_at
	elif activity != null:
		ends_at = started_at + activity.duration_seconds


func get_remaining_seconds(now: float) -> float:
	if is_completed:
		return 0.0

	return maxf(ends_at - now, 0.0)


## 將活動標記為完成。
func mark_completed() -> void:
	is_completed = true


## 轉成可以寫入 JSON 的 Dictionary。
func to_dict() -> Dictionary:
	var saved_rabbit_name := ""

	if rabbit != null:
		saved_rabbit_name = rabbit.rabbit_name

	var saved_activity: Dictionary = {}

	if activity != null:
		saved_activity = activity.to_dict()

	return {
		"activity_record_id": activity_record_id,
		"rabbit_name": saved_rabbit_name,
		"activity": saved_activity,
		"started_at": started_at,
		"ends_at": ends_at,
		"is_completed": is_completed
	}


## 從存檔資料還原活動。
## restored_rabbit 是 RabbitManager 中已經還原好的兔子。
static func from_dict(
		data: Dictionary,
		restored_rabbit: RabbitData
) -> ActiveActivityData:
	if restored_rabbit == null:
		push_error("ActiveActivityData：無法還原活動，兔子資料不存在。")
		return null

	var raw_activity: Variant = data.get("activity", {})

	if not (raw_activity is Dictionary):
		push_error("ActiveActivityData：存檔中的活動資料格式錯誤。")
		return null

	var restored_activity := ActivityData.from_dict(
		raw_activity as Dictionary
	)

	if restored_activity.activity_id.is_empty():
		push_error("ActiveActivityData：存檔中的 activity_id 為空。")
		return null

	return ActiveActivityData.new(
		restored_rabbit,
		restored_activity,
		float(data.get("started_at", 0.0)),
		str(data.get("activity_record_id", "")),
		float(data.get("ends_at", 0.0)),
		bool(data.get("is_completed", false))
	)


## 建立活動紀錄編號，例如：
## activity_1785076123456789_4821
static func _generate_activity_record_id() -> String:
	var timestamp := int(
		Time.get_unix_time_from_system() * 1000000.0
	)

	var random_suffix := randi_range(1000, 9999)

	return "activity_%d_%d" % [
		timestamp,
		random_suffix
	]