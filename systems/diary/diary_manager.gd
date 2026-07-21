class_name DiaryManager
extends Node


signal journal_added(entry: JournalEntry)
signal journals_changed


var _journals: Array[JournalEntry] = []


## 新增一篇日記。
func add_journal(entry: JournalEntry) -> bool:
	if entry == null:
		return false

	if entry.content.is_empty():
		return false

	_journals.append(entry)

	journal_added.emit(entry)
	journals_changed.emit()

	return true


## 依照索引讀取一篇日記。
func get_journal(index: int) -> JournalEntry:
	if index < 0 or index >= _journals.size():
		return null

	return _journals[index]


## 取得全部日記。
func get_all_journals() -> Array[JournalEntry]:
	var result: Array[JournalEntry] = []
	result.assign(_journals)
	return result


## 取得日記數量。
func get_journal_count() -> int:
	return _journals.size()


## 清除全部日記，讀檔時會使用。
func clear_journals() -> void:
	_journals.clear()
	journals_changed.emit()


## 將全部日記轉成可存檔的 Array。
func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for entry: JournalEntry in _journals:
		result.append(entry.to_dict())

	return result


## 從存檔資料還原日記。
func load_from_array(data: Array) -> void:
	_journals.clear()

	for item: Variant in data:
		if item is Dictionary:
			var entry := JournalEntry.from_dict(item)

			if entry != null:
				_journals.append(entry)

	journals_changed.emit()