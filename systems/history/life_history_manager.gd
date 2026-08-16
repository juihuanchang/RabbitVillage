class_name LifeHistoryManager
extends Node

signal history_changed

var _food_use_history: Array[FoodUseHistoryEntry] = []
var _growth_path_history: Array[GrowthPathHistoryEntry] = []
var _life_event_history: Array[LifeEventHistoryEntry] = []

func setup(food_use_history: Array = [], growth_path_history: Array = [], life_event_history: Array = []) -> void:
	_food_use_history.clear()
	_growth_path_history.clear()
	_life_event_history.clear()

	for raw: Variant in food_use_history:
		if raw is Dictionary:
			var entry := FoodUseHistoryEntry.from_dict(raw)
			if not entry.food_use_record_id.is_empty() and not has_food_use(entry.food_use_record_id):
				_food_use_history.append(entry)

	for raw: Variant in growth_path_history:
		if raw is Dictionary:
			var entry := GrowthPathHistoryEntry.from_dict(raw)
			if not entry.source_event_id.is_empty() and not has_growth_path_history(entry.source_event_id):
				_growth_path_history.append(entry)

	for raw: Variant in life_event_history:
		if raw is Dictionary:
			var entry := LifeEventHistoryEntry.from_dict(raw)
			if not entry.life_event_id.is_empty() and not has_life_event_history(entry.life_event_id):
				_life_event_history.append(entry)

	history_changed.emit()

func record_food_use(result: FoodUseResult) -> FoodUseHistoryEntry:
	if result == null or result.food_use_record_id.is_empty() or result.food_id.is_empty():
		return null
	var existing := get_food_use(result.food_use_record_id)
	if existing != null:
		return existing
	var entry := FoodUseHistoryEntry.new()
	entry.food_use_record_id = result.food_use_record_id
	entry.food_id = result.food_id
	entry.used_at = maxf(0.0, result.used_at)
	entry.amount_used = maxi(0, result.amount_used)
	entry.hunger_before = clampi(result.hunger_before, 0, 100)
	entry.hunger_after = clampi(result.hunger_after, 0, 100)
	# B's FoodManager is runtime-only, so C derives the permanent first-use flag
	# from already-saved history instead of trusting a session-local boolean.
	entry.is_first_use = not has_food_use_for_food(result.food_id)
	_food_use_history.append(entry)
	history_changed.emit()
	return entry

func record_growth_path_change(
	growth_path: String,
	old_stage: int,
	new_stage: int,
	source_event_id: String,
	changed_at: float = -1.0
) -> GrowthPathHistoryEntry:
	if growth_path.is_empty() or source_event_id.is_empty():
		return null
	var existing := get_growth_path_history(source_event_id)
	if existing != null:
		return existing
	var entry := GrowthPathHistoryEntry.new()
	entry.changed_at = TimeManager.get_now() if changed_at <= 0.0 else changed_at
	entry.history_id = "growth_path_%s" % source_event_id
	entry.growth_path = growth_path
	entry.old_stage = maxi(0, old_stage)
	entry.new_stage = maxi(0, new_stage)
	entry.source_event_id = source_event_id
	_growth_path_history.append(entry)
	history_changed.emit()
	return entry

func record_life_event(event_result: LifeEventResult) -> LifeEventHistoryEntry:
	if event_result == null or event_result.event_id.is_empty():
		return null
	var existing := get_life_event_history(event_result.event_id)
	if existing != null:
		return existing
	var entry := LifeEventHistoryEntry.new()
	entry.life_event_id = event_result.event_id
	entry.confirmed_at = TimeManager.get_now() if event_result.confirmed_at <= 0.0 else event_result.confirmed_at
	entry.history_id = "life_history_%s" % event_result.event_id
	_life_event_history.append(entry)
	history_changed.emit()
	return entry

func has_food_use(food_use_record_id: String) -> bool:
	return get_food_use(food_use_record_id) != null

func get_food_use(food_use_record_id: String) -> FoodUseHistoryEntry:
	for entry: FoodUseHistoryEntry in _food_use_history:
		if entry.food_use_record_id == food_use_record_id:
			return entry
	return null

func has_food_use_for_food(food_id: String) -> bool:
	for entry: FoodUseHistoryEntry in _food_use_history:
		if entry.food_id == food_id:
			return true
	return false

func has_growth_path_history(source_event_id: String) -> bool:
	return get_growth_path_history(source_event_id) != null

func get_growth_path_history(source_event_id: String) -> GrowthPathHistoryEntry:
	for entry: GrowthPathHistoryEntry in _growth_path_history:
		if entry.source_event_id == source_event_id:
			return entry
	return null

func has_life_event_history(event_id: String) -> bool:
	return get_life_event_history(event_id) != null

func get_life_event_history(event_id: String) -> LifeEventHistoryEntry:
	for entry: LifeEventHistoryEntry in _life_event_history:
		if entry.life_event_id == event_id:
			return entry
	return null

func food_use_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: FoodUseHistoryEntry in _food_use_history:
		result.append(entry.to_dict())
	return result

func growth_path_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: GrowthPathHistoryEntry in _growth_path_history:
		result.append(entry.to_dict())
	return result

func life_event_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: LifeEventHistoryEntry in _life_event_history:
		result.append(entry.to_dict())
	return result
