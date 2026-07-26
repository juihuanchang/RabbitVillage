class_name DiaryManager
extends Node


signal journal_added(entry: JournalEntry)
signal journals_changed


var _journals: Array[JournalEntry] = []


## 接收一筆已完成的活動，產生並新增正式日記。
func create_journal_from_activity(
		active_activity: ActiveActivityData
) -> JournalEntry:
	if active_activity == null:
		push_error("DiaryManager：活動資料不存在。")
		return null

	if active_activity.activity_record_id.is_empty():
		push_error("DiaryManager：活動紀錄編號不可為空。")
		return null

	# 同一筆活動只能產生一篇日記。
	if has_activity_record_id(
		active_activity.activity_record_id
	):
		print(
			"DiaryManager：此活動已經產生日記：",
			active_activity.activity_record_id
		)
		return null

	var journal_id := _create_next_journal_id()

	var entry := JournalGenerator.generate(
		active_activity,
		journal_id
	)

	if entry == null:
		push_error("DiaryManager：日記產生失敗。")
		return null

	if not add_journal(entry):
		return null

	return entry


## 新增一篇日記。
func add_journal(entry: JournalEntry) -> bool:
	if entry == null:
		push_error("DiaryManager：JournalEntry 不可為 null。")
		return false

	if not entry.is_valid():
		push_error("DiaryManager：日記資料不完整。")
		return false

	if has_activity_record_id(entry.activity_record_id):
		print(
			"DiaryManager：拒絕重複日記，活動紀錄編號：",
			entry.activity_record_id
		)
		return false

	_journals.append(entry)
	sort_journals_by_date()

	journal_added.emit(entry)
	journals_changed.emit()

	return true


## 依索引讀取一篇日記。
## 最新日記的索引通常是 0。
func get_journal(index: int) -> JournalEntry:
	if index < 0 or index >= _journals.size():
		return null

	return _journals[index]


## 取得全部日記。
## 沒有日記時會回傳空陣列。
func get_all_journals() -> Array[JournalEntry]:
	sort_journals_by_date()

	var result: Array[JournalEntry] = []
	result.assign(_journals)
	return result


## 取得最新一篇日記。
## 沒有日記時回傳 null。
func get_latest_journal() -> JournalEntry:
	if _journals.is_empty():
		return null

	sort_journals_by_date()
	return _journals[0]


func get_journal_count() -> int:
	return _journals.size()


## 檢查某一筆活動是否已產生日記。
func has_activity_record_id(
		activity_record_id: String
) -> bool:
	var target_id := activity_record_id.strip_edges()

	if target_id.is_empty():
		return false

	for entry: JournalEntry in _journals:
		if entry.activity_record_id == target_id:
			return true

	return false


## 最新日記排列在最前面。
func sort_journals_by_date() -> void:
	_journals.sort_custom(_sort_newest_first)


## 清除全部日記，主要供讀檔或建立新存檔使用。
func clear_journals() -> void:
	_journals.clear()
	journals_changed.emit()


## 將全部日記轉成可寫入 JSON 的陣列。
func to_array() -> Array[Dictionary]:
	sort_journals_by_date()

	var result: Array[Dictionary] = []

	for entry: JournalEntry in _journals:
		result.append(entry.to_dict())

	return result


## 從存檔資料還原多篇日記。
func load_from_array(data: Array) -> void:
	_journals.clear()

	for item: Variant in data:
		if not (item is Dictionary):
			push_warning("DiaryManager：忽略格式錯誤的日記資料。")
			continue

		var entry := JournalEntry.from_dict(
			item as Dictionary
		)

		if entry == null or not entry.is_valid():
			push_warning("DiaryManager：忽略內容不完整的日記。")
			continue

		# 存檔中如果有重複活動紀錄，只保留第一篇。
		if has_activity_record_id(
			entry.activity_record_id
		):
			push_warning(
				"DiaryManager：忽略重複活動日記：" +
				entry.activity_record_id
			)
			continue

		_journals.append(entry)

	sort_journals_by_date()
	journals_changed.emit()


## sort_custom 使用的比較函式。
## created_at 較大的日記排在前面。
func _sort_newest_first(
		first: JournalEntry,
		second: JournalEntry
) -> bool:
	if is_equal_approx(
		first.created_at,
		second.created_at
	):
		return first.journal_id > second.journal_id

	return first.created_at > second.created_at


## 自動產生下一個日記編號。
## 例如 journal_001、journal_002。
func _create_next_journal_id() -> String:
	var largest_number := 0

	for entry: JournalEntry in _journals:
		if not entry.journal_id.begins_with(
			"journal_"
		):
			continue

		var number_text := entry.journal_id.trim_prefix(
			"journal_"
		)

		if not number_text.is_valid_int():
			continue

		largest_number = maxi(
			largest_number,
			number_text.to_int()
		)

	return "journal_%03d" % (largest_number + 1)