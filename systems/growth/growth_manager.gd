class_name GrowthManager
extends Node

signal growth_event_created(event: GrowthEventData)
signal growth_mark_unlocked(mark: GrowthMarkData, event: GrowthEventData)
signal growth_progress_changed

var _rabbit: RabbitData
var _marks: Dictionary = {}
var _activity_records: Array[Dictionary] = []
var _growth_tendencies: Dictionary = {"forest": 0, "lake": 0, "home": 0}

func _init() -> void:
	_marks["leaf_mark"] = GrowthMarkData.create_leaf_mark()
	var lake_placeholder := GrowthMarkData.new()
	lake_placeholder.id = "grass_hat_mark"
	lake_placeholder.display_name = "草帽印記"
	lake_placeholder.growth_path = "lake"
	lake_placeholder.stage = 1
	lake_placeholder.description = "湖畔成長路徑的預留印記。"
	_marks[lake_placeholder.id] = lake_placeholder

func setup(rabbit: RabbitData) -> void:
	_rabbit = rabbit
	for mark: GrowthMarkData in _marks.values():
		mark.is_unlocked = false
		mark.unlocked_at = 0.0
	for saved_mark: Dictionary in rabbit.unlocked_growth_marks:
		var mark_id := str(saved_mark.get("id", ""))
		if _marks.has(mark_id):
			var mark: GrowthMarkData = _marks[mark_id]
			mark.is_unlocked = true
			mark.unlocked_at = float(saved_mark.get("unlocked_at", 0.0))
	growth_progress_changed.emit()

func load_from_save_data(data: SaveData) -> void:
	_activity_records.clear()
	for record: Dictionary in data.all_activity_records:
		_activity_records.append(record.duplicate(true))
	if _activity_records.is_empty():
		for legacy_record_id: String in data.completed_activity_ids:
			_activity_records.append({"activity_record_id": legacy_record_id})
	_growth_tendencies = data.growth_tendencies.duplicate(true)
	if _growth_tendencies.is_empty():
		_growth_tendencies = {"forest": 0, "lake": 0, "home": 0}
	growth_progress_changed.emit()

func record_completed_activity(active: ActiveActivityData) -> bool:
	if active == null or active.activity == null or active.activity_record_id.is_empty():
		return false
	if has_activity_record(active.activity_record_id):
		return false
	var completion := active.get_completion_data()
	_activity_records.append(completion)
	var location_id := active.activity.location_id
	_growth_tendencies[location_id] = int(_growth_tendencies.get(location_id, 0)) + 1
	if location_id == "forest":
		check_growth_conditions()
	growth_progress_changed.emit()
	return true

func has_activity_record(record_id: String) -> bool:
	for record: Dictionary in _activity_records:
		if str(record.get("activity_record_id", "")) == record_id:
			return true
	return false

func get_all_activity_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: Dictionary in _activity_records:
		result.append(record.duplicate(true))
	return result

func check_growth_conditions() -> GrowthEventData:
	if not can_unlock_mark("leaf_mark"): return null
	if has_pending_growth_event(): return get_pending_growth_event()
	var event := GrowthEventData.create_leaf_event()
	_rabbit.pending_growth_event = event.to_dict()
	growth_event_created.emit(event)
	growth_progress_changed.emit()
	return event

func can_unlock_mark(mark_id: String) -> bool:
	if _rabbit == null or not _marks.has(mark_id) or has_growth_mark(mark_id): return false
	var mark: GrowthMarkData = _marks[mark_id]
	return _rabbit.forest_experience >= mark.required_experience and _rabbit.forest_activity_count >= mark.required_visit_count

func has_growth_mark(mark_id: String) -> bool:
	if _rabbit == null: return false
	for mark: Dictionary in _rabbit.unlocked_growth_marks:
		if str(mark.get("id", "")) == mark_id: return true
	return false

func unlock_growth_mark(mark_id: String) -> bool:
	if _rabbit == null or not _marks.has(mark_id) or has_growth_mark(mark_id): return false
	var mark: GrowthMarkData = _marks[mark_id]
	mark.is_unlocked = true
	mark.unlocked_at = TimeManager.get_now()
	_rabbit.unlocked_growth_marks.append(mark.to_dict())
	growth_progress_changed.emit()
	return true

func get_unlocked_growth_marks() -> Array[GrowthMarkData]:
	var result: Array[GrowthMarkData] = []
	for mark: GrowthMarkData in _marks.values():
		if has_growth_mark(mark.id): result.append(mark)
	return result

func has_pending_growth_event() -> bool: return _rabbit != null and not _rabbit.pending_growth_event.is_empty()
func get_pending_growth_event() -> GrowthEventData:
	return GrowthEventData.from_dict(_rabbit.pending_growth_event) if has_pending_growth_event() else null

func confirm_growth_event(event_id: String) -> bool:
	var event := get_pending_growth_event()
	if event == null or event.event_id != event_id or event.is_applied: return false
	if has_growth_mark(event.growth_mark_id):
		_rabbit.pending_growth_event = {}
		growth_progress_changed.emit()
		return false
	if not unlock_growth_mark(event.growth_mark_id): return false
	event.is_confirmed = true
	event.is_applied = true
	_rabbit.pending_growth_event = {}
	growth_mark_unlocked.emit(_marks[event.growth_mark_id], event)
	growth_progress_changed.emit()
	return true

func get_growth_tendency(path_id: String) -> String:
	var value := int(_growth_tendencies.get(path_id, 0))
	if value <= 0:
		return "none"
	if value < 3:
		return "weak"
	if value < 6:
		return "steady"
	return "strong"

func get_growth_tendencies() -> Dictionary:
	return _growth_tendencies.duplicate(true)

func CheckGrowthConditions() -> GrowthEventData: return check_growth_conditions()
func CanUnlockMark(mark_id: String) -> bool: return can_unlock_mark(mark_id)
func HasGrowthMark(mark_id: String) -> bool: return has_growth_mark(mark_id)
func UnlockGrowthMark(mark_id: String) -> bool: return unlock_growth_mark(mark_id)
func GetUnlockedGrowthMarks() -> Array[GrowthMarkData]: return get_unlocked_growth_marks()
func HasPendingGrowthEvent() -> bool: return has_pending_growth_event()
func GetPendingGrowthEvent() -> GrowthEventData: return get_pending_growth_event()
func ConfirmGrowthEvent(event_id: String) -> bool: return confirm_growth_event(event_id)
func GetGrowthTendency(path_id: String) -> String: return get_growth_tendency(path_id)
func GetGrowthTendencies() -> Dictionary: return get_growth_tendencies()
func GetAllActivityRecords() -> Array[Dictionary]: return get_all_activity_records()
func HasActivityRecord(record_id: String) -> bool: return has_activity_record(record_id)
func RecordCompletedActivity(active: ActiveActivityData) -> bool: return record_completed_activity(active)
