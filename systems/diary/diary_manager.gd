class_name DiaryManager
extends Node

signal journal_added(entry: JournalEntry)
signal journals_changed
var _journals: Array[JournalEntry] = []

func create_journal_from_activity(active: ActiveActivityData) -> JournalEntry:
	if active == null or active.activity_record_id.is_empty() or has_activity_record_id(active.activity_record_id):
		return null
	var entry := JournalGenerator.generate(active, _generate_next_journal_id())
	if entry != null:
		_journals.append(entry)
		journal_added.emit(entry)
		journals_changed.emit()
	return entry

func create_growth_journal(rabbit_name: String, growth_mark_id: String, created_at: float = -1.0) -> JournalEntry:
	if growth_mark_id.is_empty() or has_journal_for_growth_mark(growth_mark_id):
		return null
	var entry := JournalGenerator.generate_growth_journal(rabbit_name, _generate_next_journal_id(), growth_mark_id, created_at)
	if entry != null:
		_journals.append(entry)
		journal_added.emit(entry)
		journals_changed.emit()
	return entry

func has_activity_record_id(record_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if not record_id.is_empty() and entry.activity_record_id == record_id:
			return true
	return false

func has_journal_for_growth_mark(growth_mark_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.growth_mark_id == growth_mark_id:
			return true
	return false

func get_all_journals() -> Array[JournalEntry]:
	var result: Array[JournalEntry] = []
	result.assign(_journals)
	result.sort_custom(func(a: JournalEntry, b: JournalEntry) -> bool: return a.created_at > b.created_at)
	return result

func get_latest_journal() -> JournalEntry:
	var all := get_all_journals()
	return all[0] if not all.is_empty() else null

func get_journal_count() -> int:
	return _journals.size()

func clear_journals() -> void:
	_journals.clear()
	journals_changed.emit()

func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: JournalEntry in _journals:
		result.append(entry.to_dict())
	return result

func load_from_array(data: Array) -> void:
	_journals.clear()
	for raw: Variant in data:
		if raw is Dictionary:
			var entry := JournalEntry.from_dict(raw)
			if not entry.is_valid():
				continue
			if entry.journal_type == "growth":
				if not has_journal_for_growth_mark(entry.growth_mark_id):
					_journals.append(entry)
			elif not has_activity_record_id(entry.activity_record_id):
				_journals.append(entry)
			
	journals_changed.emit()

func _generate_next_journal_id() -> String:
	return "journal_%03d" % (_journals.size() + 1)
