class_name LifeLocationHistoryManager
extends Node

signal history_changed

const VALID_LOCATION_ID := "picnic_area"
const VALID_ACTIVITY_IDS := ["picnic_rest", "picnic_eat", "picnic_relax"]

var _history: Array[LifeLocationHistoryEntry] = []

func setup(saved_history: Array = []) -> void:
	_history.clear()
	var seen := {}
	for raw: Variant in saved_history:
		if not (raw is Dictionary):
			continue
		var entry := LifeLocationHistoryEntry.from_dict(raw)
		if entry.location_record_id.is_empty() or entry.location_id != VALID_LOCATION_ID or not VALID_ACTIVITY_IDS.has(entry.activity_id) or seen.has(entry.location_record_id):
			continue
		seen[entry.location_record_id] = true
		_history.append(entry)
	history_changed.emit()

func record_activity(result: LifeLocationResult, food_id := "") -> LifeLocationHistoryEntry:
	if result == null or not result.success or result.location_record_id.is_empty():
		return null
	if result.location_id != VALID_LOCATION_ID or not VALID_ACTIVITY_IDS.has(result.activity_id):
		return null
	var existing := get_history(result.location_record_id)
	if existing != null:
		return existing
	var entry := LifeLocationHistoryEntry.new()
	entry.location_record_id = result.location_record_id
	entry.location_id = result.location_id
	entry.activity_id = result.activity_id
	entry.completed_at = maxf(0.0, result.completed_at)
	entry.date_key = _date_key(entry.completed_at)
	entry.result = {
		"food_use_record_id": result.food_use_record_id,
		"food_id": food_id,
		"energy_change": result.energy_change,
		"mood_change": result.mood_change,
		"intimacy_change": result.intimacy_change,
		"success": result.success
	}
	_history.append(entry)
	history_changed.emit()
	return entry

func has_history(record_id: String) -> bool:
	return get_history(record_id) != null

func get_history(record_id: String) -> LifeLocationHistoryEntry:
	for entry: LifeLocationHistoryEntry in _history:
		if entry.location_record_id == record_id:
			return entry
	return null

func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: LifeLocationHistoryEntry in _history:
		result.append(entry.to_dict())
	return result

func _date_key(timestamp: float) -> String:
	if timestamp <= 0.0:
		return ""
	var date := TimeManager.get_local_datetime(timestamp)
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]
