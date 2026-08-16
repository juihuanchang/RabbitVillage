class_name ItemCollectionManager
extends Node

signal collection_changed
signal item_registered(entry: ItemCollectionEntry)

const VALID_ITEM_IDS := ["carrot", "leaf", "twig", "small_stone", "driftwood"]

var _entries: Dictionary = {}

func setup(saved_collection: Array = []) -> void:
	_entries.clear()
	for raw: Variant in saved_collection:
		if not (raw is Dictionary):
			continue
		var incoming := ItemCollectionEntry.from_dict(raw)
		if not VALID_ITEM_IDS.has(incoming.item_id) or not incoming.is_discovered:
			continue
		if not _entries.has(incoming.item_id):
			_entries[incoming.item_id] = incoming
			continue
		var current := _entries[incoming.item_id] as ItemCollectionEntry
		if current == null or _is_earlier(incoming.first_obtained_at, current.first_obtained_at):
			_entries[incoming.item_id] = incoming
	collection_changed.emit()

func register_discovery(
	item_id: String,
	first_obtained_at: float,
	first_source_type: String,
	first_source_id: String
) -> ItemCollectionEntry:
	if not VALID_ITEM_IDS.has(item_id):
		return null
	var existing := get_collection_entry(item_id)
	if existing != null:
		return existing
	var entry := ItemCollectionEntry.new()
	entry.item_id = item_id
	entry.is_discovered = true
	entry.first_obtained_at = TimeManager.get_now() if first_obtained_at <= 0.0 else first_obtained_at
	entry.first_source_type = first_source_type
	entry.first_source_id = first_source_id
	_entries[item_id] = entry
	item_registered.emit(entry)
	collection_changed.emit()
	return entry

func has_discovered_item(item_id: String) -> bool:
	var entry := get_collection_entry(item_id)
	return entry != null and entry.is_discovered

func get_item_collection() -> Array[ItemCollectionEntry]:
	var result: Array[ItemCollectionEntry] = []
	for entry: ItemCollectionEntry in _entries.values():
		result.append(entry)
	result.sort_custom(func(a: ItemCollectionEntry, b: ItemCollectionEntry) -> bool:
		return a.first_obtained_at < b.first_obtained_at
	)
	return result

func get_collection_entry(item_id: String) -> ItemCollectionEntry:
	return _entries.get(item_id) as ItemCollectionEntry

func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: ItemCollectionEntry in get_item_collection():
		result.append(entry.to_dict())
	return result

func _is_earlier(candidate: float, current: float) -> bool:
	if current <= 0.0:
		return candidate > 0.0
	if candidate <= 0.0:
		return false
	return candidate < current
