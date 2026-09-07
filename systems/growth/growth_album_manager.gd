class_name GrowthAlbumManager
extends Node

signal album_entry_added(entry: GrowthAlbumEntry)
signal entries_changed

var _entries: Array[GrowthAlbumEntry] = []

func add_album_entry(entry: GrowthAlbumEntry) -> bool:
	if entry == null or not entry.is_valid():
		return false
	if has_entry_for_growth_mark(entry.growth_mark_id):
		return false
	if _is_week5_event_entry(entry) and has_entry_for_growth_event(_event_id_from_album_id(entry.id)):
		return false
	_entries.append(entry)
	sort_by_unlocked_time()
	album_entry_added.emit(entry)
	entries_changed.emit()
	return true

func add_week5_growth_entry(
	growth_mark_id: String,
	growth_event_id: String,
	title: String,
	description: String,
	growth_path: String,
	stage: int,
	unlocked_at: float,
	journal_id: String,
	illustration_id: String = ""
) -> bool:
	if growth_mark_id.is_empty() or growth_event_id.is_empty():
		return false
	if has_entry_for_growth_mark(growth_mark_id) or has_entry_for_growth_event(growth_event_id):
		return false
	var entry := GrowthAlbumEntry.new(
		"album_event_%s" % growth_event_id,
		growth_mark_id,
		title,
		description,
		growth_path,
		stage,
		unlocked_at,
		journal_id,
		illustration_id
	)
	return add_album_entry(entry)

func add_week7_moment(
	moment_id: String,
	source_event_id: String,
	title: String,
	description: String,
	growth_path: String,
	stage: int,
	unlocked_at: float,
	journal_id: String,
	illustration_id: String = ""
) -> bool:
	if moment_id.is_empty() or source_event_id.is_empty():
		return false
	if has_entry_for_growth_mark(moment_id) or has_entry_for_week7_event(source_event_id):
		return false
	var entry := GrowthAlbumEntry.new(
		"album_week7_%s_%s" % [moment_id, source_event_id],
		moment_id,
		title,
		description,
		growth_path,
		stage,
		unlocked_at,
		journal_id,
		illustration_id
	)
	return add_album_entry(entry)

func add_week8_moment(
	moment_id: String,
	source_event_id: String,
	title: String,
	description: String,
	growth_path: String,
	stage: int,
	unlocked_at: float,
	journal_id: String,
	illustration_id: String = ""
) -> bool:
	if moment_id.is_empty() or source_event_id.is_empty():
		return false
	if has_entry_for_growth_mark(moment_id) or has_entry_for_week8_event(source_event_id):
		return false
	var entry := GrowthAlbumEntry.new(
		"album_week8_%s_%s" % [moment_id, source_event_id],
		moment_id,
		title,
		description,
		growth_path,
		stage,
		unlocked_at,
		journal_id,
		illustration_id
	)
	return add_album_entry(entry)

func has_entry_for_week8_event(source_event_id: String) -> bool:
	if source_event_id.is_empty():
		return false
	for entry: GrowthAlbumEntry in _entries:
		if entry.id.begins_with("album_week8_") and entry.id.ends_with("_%s" % source_event_id):
			return true
	return false

func has_entry_for_week7_event(source_event_id: String) -> bool:
	if source_event_id.is_empty():
		return false
	for entry: GrowthAlbumEntry in _entries:
		if entry.id.ends_with("_%s" % source_event_id):
			return true
	return false

func get_all_entries() -> Array[GrowthAlbumEntry]:
	var result: Array[GrowthAlbumEntry] = []
	result.assign(_entries)
	result.sort_custom(func(a: GrowthAlbumEntry, b: GrowthAlbumEntry) -> bool:
		return a.unlocked_at > b.unlocked_at
	)
	return result

func has_entry_for_growth_mark(growth_mark_id: String) -> bool:
	if growth_mark_id.is_empty():
		return false
	for entry: GrowthAlbumEntry in _entries:
		if entry.growth_mark_id == growth_mark_id:
			return true
	return false

func has_entry_for_growth_event(growth_event_id: String) -> bool:
	if growth_event_id.is_empty():
		return false
	var expected_id := "album_event_%s" % growth_event_id
	for entry: GrowthAlbumEntry in _entries:
		if entry.id == expected_id:
			return true
	return false

func sort_by_unlocked_time() -> void:
	_entries.sort_custom(func(a: GrowthAlbumEntry, b: GrowthAlbumEntry) -> bool:
		return a.unlocked_at > b.unlocked_at
	)

func clear_entries() -> void:
	_entries.clear()
	entries_changed.emit()

func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: GrowthAlbumEntry in _entries:
		result.append(entry.to_dict())
	return result

func load_from_array(data: Array) -> void:
	_entries.clear()
	for raw: Variant in data:
		if not (raw is Dictionary):
			continue
		var entry := GrowthAlbumEntry.from_dict(raw)
		if not entry.is_valid() or has_entry_for_growth_mark(entry.growth_mark_id):
			continue
		if _is_week5_event_entry(entry) and has_entry_for_growth_event(_event_id_from_album_id(entry.id)):
			continue
		_entries.append(entry)
	sort_by_unlocked_time()
	entries_changed.emit()

func _is_week5_event_entry(entry: GrowthAlbumEntry) -> bool:
	return entry != null and entry.id.begins_with("album_event_")

func _event_id_from_album_id(album_id: String) -> String:
	return album_id.trim_prefix("album_event_")
