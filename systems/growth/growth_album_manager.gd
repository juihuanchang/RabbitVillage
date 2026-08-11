class_name GrowthAlbumManager
extends Node

signal album_entry_added(entry: GrowthAlbumEntry)
signal entries_changed

var _entries: Array[GrowthAlbumEntry] = []

func add_album_entry(entry: GrowthAlbumEntry) -> bool:
	if entry == null or not entry.is_valid() or has_entry_for_growth_mark(entry.growth_mark_id):
		return false
	_entries.append(entry)
	sort_by_unlocked_time()
	album_entry_added.emit(entry)
	entries_changed.emit()
	return true

func get_all_entries() -> Array[GrowthAlbumEntry]:
	var result: Array[GrowthAlbumEntry] = []
	result.assign(_entries)
	result.sort_custom(func(a: GrowthAlbumEntry, b: GrowthAlbumEntry) -> bool: return a.unlocked_at > b.unlocked_at)
	return result

func has_entry_for_growth_mark(growth_mark_id: String) -> bool:
	for entry: GrowthAlbumEntry in _entries:
		if entry.growth_mark_id == growth_mark_id:
			return true
	return false

func sort_by_unlocked_time() -> void:
	_entries.sort_custom(func(a: GrowthAlbumEntry, b: GrowthAlbumEntry) -> bool: return a.unlocked_at > b.unlocked_at)

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
		if raw is Dictionary:
			var entry := GrowthAlbumEntry.from_dict(raw)
			if entry.is_valid() and not has_entry_for_growth_mark(entry.growth_mark_id):
				_entries.append(entry)
	sort_by_unlocked_time()
	entries_changed.emit()
