class_name RecipeCollectionManager
extends Node

signal collection_changed
signal recipe_registered(entry: RecipeCollectionEntry)

var _entries: Dictionary = {}

func setup(saved_collection: Array = []) -> void:
	_entries.clear()
	for raw: Variant in saved_collection:
		if not (raw is Dictionary):
			continue
		var incoming := RecipeCollectionEntry.from_dict(raw)
		incoming.recipe_id = CookingHistoryManager.canonical_recipe_id(incoming.recipe_id)
		if not CookingHistoryManager.is_valid_recipe_id(incoming.recipe_id) or not incoming.is_discovered:
			continue
		var current := _entries.get(incoming.recipe_id) as RecipeCollectionEntry
		if current == null:
			_entries[incoming.recipe_id] = incoming
		else:
			_merge(current, incoming)
	collection_changed.emit()

func register_discovery(recipe_id: String, cooked_at: float, source_type: String, source_id: String) -> RecipeCollectionEntry:
	var canonical := CookingHistoryManager.canonical_recipe_id(recipe_id)
	if not CookingHistoryManager.is_valid_recipe_id(canonical):
		return null
	var existing := get_collection_entry(canonical)
	if existing != null:
		return existing
	var entry := RecipeCollectionEntry.new()
	entry.recipe_id = canonical
	entry.is_discovered = true
	entry.first_cooked_at = TimeManager.get_now() if cooked_at <= 0.0 else cooked_at
	entry.first_source_type = source_type
	entry.first_source_id = source_id
	entry.total_cook_count = 0
	_entries[canonical] = entry
	recipe_registered.emit(entry)
	collection_changed.emit()
	return entry

func record_cook(recipe_id: String, cooked_at: float, source_type: String, source_id: String) -> RecipeCollectionEntry:
	var entry := register_discovery(recipe_id, cooked_at, source_type, source_id)
	if entry == null:
		return null
	entry.total_cook_count += 1
	collection_changed.emit()
	return entry


func ensure_minimum_cook_count(recipe_id: String, minimum_count: int, cooked_at: float = 0.0, source_type := "repair", source_id := "cooking_history") -> RecipeCollectionEntry:
	var canonical := CookingHistoryManager.canonical_recipe_id(recipe_id)
	if not CookingHistoryManager.is_valid_recipe_id(canonical):
		return null
	var entry := get_collection_entry(canonical)
	if entry == null:
		entry = register_discovery(canonical, cooked_at, source_type, source_id)
	if entry == null:
		return null
	var repaired_count := maxi(0, minimum_count)
	if entry.total_cook_count < repaired_count:
		entry.total_cook_count = repaired_count
		collection_changed.emit()
	return entry

func has_discovered_recipe(recipe_id: String) -> bool:
	var entry := get_collection_entry(recipe_id)
	return entry != null and entry.is_discovered

func get_collection_entry(recipe_id: String) -> RecipeCollectionEntry:
	return _entries.get(CookingHistoryManager.canonical_recipe_id(recipe_id)) as RecipeCollectionEntry

func get_recipe_collection() -> Array[RecipeCollectionEntry]:
	var result: Array[RecipeCollectionEntry] = []
	result.assign(_entries.values())
	result.sort_custom(func(a: RecipeCollectionEntry, b: RecipeCollectionEntry) -> bool:
		return a.first_cooked_at < b.first_cooked_at
	)
	return result

func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: RecipeCollectionEntry in get_recipe_collection():
		result.append(entry.to_dict())
	return result

func _merge(current: RecipeCollectionEntry, incoming: RecipeCollectionEntry) -> void:
	if current == null or incoming == null:
		return
	if _is_earlier(incoming.first_cooked_at, current.first_cooked_at):
		current.first_cooked_at = incoming.first_cooked_at
		current.first_source_type = incoming.first_source_type
		current.first_source_id = incoming.first_source_id
	current.total_cook_count = maxi(current.total_cook_count, incoming.total_cook_count)
	current.is_discovered = current.is_discovered or incoming.is_discovered

func _is_earlier(candidate: float, current: float) -> bool:
	if current <= 0.0:
		return candidate > 0.0
	if candidate <= 0.0:
		return false
	return candidate < current
