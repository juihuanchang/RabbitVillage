class_name CookingHistoryManager
extends Node

signal history_changed

const CANONICAL_RECIPE_IDS := [
	"recipe_carrot_sandwich", "recipe_forest_salad", "recipe_berry_toast", "recipe_picnic_snack"
]
const RECIPE_ALIASES := {
	"carrot_sandwich": "recipe_carrot_sandwich",
	"forest_salad": "recipe_forest_salad",
	"berry_toast": "recipe_berry_toast",
	"picnic_snack": "recipe_picnic_snack"
}

var _cooking_history: Array[CookingHistoryEntry] = []
var _recipe_unlock_history: Dictionary = {}

func setup(cooking_history: Array = [], recipe_unlock_history: Array = []) -> void:
	_cooking_history.clear()
	_recipe_unlock_history.clear()
	var seen := {}
	for raw: Variant in cooking_history:
		if not (raw is Dictionary):
			continue
		var entry := CookingHistoryEntry.from_dict(raw)
		entry.recipe_id = canonical_recipe_id(entry.recipe_id)
		if entry.cooking_record_id.is_empty() or not is_valid_recipe_id(entry.recipe_id) or seen.has(entry.cooking_record_id):
			continue
		seen[entry.cooking_record_id] = true
		_cooking_history.append(entry)
	for raw: Variant in recipe_unlock_history:
		if not (raw is Dictionary):
			continue
		var entry := RecipeUnlockHistoryEntry.from_dict(raw)
		entry.recipe_id = canonical_recipe_id(entry.recipe_id)
		if not is_valid_recipe_id(entry.recipe_id):
			continue
		var current := _recipe_unlock_history.get(entry.recipe_id) as RecipeUnlockHistoryEntry
		if current == null or _is_earlier(entry.unlocked_at, current.unlocked_at):
			_recipe_unlock_history[entry.recipe_id] = entry
	history_changed.emit()

func record_cooking(result: CookingResult, ingredients: Dictionary = {}) -> CookingHistoryEntry:
	if result == null or not result.success or result.cooking_record_id.is_empty():
		return null
	var existing := get_cooking(result.cooking_record_id)
	if existing != null:
		return existing
	var canonical := canonical_recipe_id(result.recipe_id)
	if not is_valid_recipe_id(canonical):
		return null
	var entry := CookingHistoryEntry.new()
	entry.cooking_record_id = result.cooking_record_id
	entry.recipe_id = canonical
	entry.ingredients = ingredients.duplicate(true)
	entry.result_item = result.result_item_id
	entry.result_amount = maxi(0, result.result_amount)
	entry.cooked_at = maxf(0.0, result.cooked_at)
	_cooking_history.append(entry)
	history_changed.emit()
	return entry

func record_recipe_unlock(recipe_id: String, unlocked_at: float, source_type: String, source_id: String) -> RecipeUnlockHistoryEntry:
	var canonical := canonical_recipe_id(recipe_id)
	if not is_valid_recipe_id(canonical):
		return null
	var existing := get_recipe_unlock(canonical)
	if existing != null:
		return existing
	var entry := RecipeUnlockHistoryEntry.new()
	entry.recipe_id = canonical
	entry.unlocked_at = TimeManager.get_now() if unlocked_at <= 0.0 else unlocked_at
	entry.source_type = source_type
	entry.source_id = source_id
	_recipe_unlock_history[canonical] = entry
	history_changed.emit()
	return entry

func has_cooking(record_id: String) -> bool:
	return get_cooking(record_id) != null

func get_cooking(record_id: String) -> CookingHistoryEntry:
	for entry: CookingHistoryEntry in _cooking_history:
		if entry.cooking_record_id == record_id:
			return entry
	return null

func get_recipe_unlock(recipe_id: String) -> RecipeUnlockHistoryEntry:
	return _recipe_unlock_history.get(canonical_recipe_id(recipe_id)) as RecipeUnlockHistoryEntry

func cooking_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: CookingHistoryEntry in _cooking_history:
		result.append(entry.to_dict())
	return result

func recipe_unlock_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: RecipeUnlockHistoryEntry in _recipe_unlock_history.values():
		result.append(entry.to_dict())
	return result

static func canonical_recipe_id(recipe_id: String) -> String:
	if RECIPE_ALIASES.has(recipe_id):
		return str(RECIPE_ALIASES[recipe_id])
	return recipe_id

static func runtime_recipe_id(recipe_id: String) -> String:
	var canonical := canonical_recipe_id(recipe_id)
	for raw_id: Variant in RECIPE_ALIASES.keys():
		if str(RECIPE_ALIASES[raw_id]) == canonical:
			return str(raw_id)
	return recipe_id

static func is_valid_recipe_id(recipe_id: String) -> bool:
	return CANONICAL_RECIPE_IDS.has(canonical_recipe_id(recipe_id))

func _is_earlier(candidate: float, current: float) -> bool:
	if current <= 0.0:
		return candidate > 0.0
	if candidate <= 0.0:
		return false
	return candidate < current
