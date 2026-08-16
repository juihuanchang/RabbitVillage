class_name GrowthManager
extends Node

signal growth_event_created(event: GrowthEventData)
signal growth_mark_unlocked(mark: GrowthMarkData, event: GrowthEventData)
signal growth_progress_changed
signal growth_path_updated(growth_path: String, old_stage: int, new_stage: int, source_event_id: String)
signal growth_event_triggered(event_data: GrowthEventData)
signal growth_event_confirmed(event_data: GrowthEventData)

var _rabbit: RabbitData
var _marks: Dictionary = {}
var _activity_records: Array[Dictionary] = []
var _growth_tendencies: Dictionary = {"forest": 0, "lake": 0, "home": 0}
var _progress := GrowthPathProgressData.new()

func _init() -> void:
	_marks["leaf_mark"] = GrowthMarkData.create_leaf_mark()
	_marks["sprout_mark"] = GrowthMarkData.create("sprout_mark", "forest", 2)
	_marks["lake_interest"] = GrowthMarkData.create("lake_interest", "lakeside", 1)

func setup(rabbit: RabbitData) -> void:
	_rabbit = rabbit
	for mark: GrowthMarkData in _marks.values(): mark.is_unlocked = false; mark.unlocked_at = 0.0
	for saved_mark: Dictionary in rabbit.unlocked_growth_marks:
		var mark_id := str(saved_mark.get("id", ""))
		if _marks.has(mark_id):
			var mark := _marks[mark_id] as GrowthMarkData; mark.is_unlocked = true
			mark.unlocked_at = float(saved_mark.get("unlocked_at", 0.0))
	_progress.forest_stage = 2 if has_growth_mark("sprout_mark") else (1 if has_growth_mark("leaf_mark") else 0)
	_progress.lakeside_stage = 1 if has_growth_mark("lake_interest") else 0
	_update_tendency_levels(); growth_progress_changed.emit()

func load_from_save_data(data: SaveData) -> void:
	_activity_records.clear()
	for record: Dictionary in data.all_activity_records: _activity_records.append(record.duplicate(true))
	if _activity_records.is_empty():
		for record_id: String in data.completed_activity_ids: _activity_records.append({"activity_record_id": record_id})
	_growth_tendencies = data.growth_tendencies.duplicate(true)
	if _growth_tendencies.is_empty(): _growth_tendencies = {"forest": 0, "lake": 0, "home": 0}
	_update_tendency_levels(); growth_progress_changed.emit()

func record_completed_activity(active: ActiveActivityData) -> bool:
	if active == null or active.activity == null or active.activity_record_id.is_empty() or has_activity_record(active.activity_record_id): return false
	_activity_records.append(active.get_completion_data()); var location_id := active.activity.location_id
	_growth_tendencies[location_id] = int(_growth_tendencies.get(location_id, 0)) + 1
	_update_tendency_levels(); check_growth_conditions(); growth_progress_changed.emit(); return true

func has_activity_record(record_id: String) -> bool:
	for record: Dictionary in _activity_records:
		if str(record.get("activity_record_id", "")) == record_id: return true
	return false
func get_all_activity_records() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: Dictionary in _activity_records: result.append(record.duplicate(true))
	return result
func _activity_count(activity_id: String) -> int:
	var count := 0
	for record: Dictionary in _activity_records:
		if str(record.get("activity_id", "")) == activity_id: count += 1
	return count
func _location_count(location_id: String) -> int:
	var count := 0
	for record: Dictionary in _activity_records:
		if str(record.get("location_id", "")) == location_id: count += 1
	return count

func check_sprout_mark_condition() -> bool:
	return _rabbit != null and has_growth_mark("leaf_mark") and not has_growth_mark("sprout_mark") \
		and _rabbit.forest_experience >= 35 and _rabbit.forest_activity_count >= 5 and _activity_count("forest_explore") >= 2
func check_lakeside_interest_condition() -> bool:
	return _rabbit != null and not has_growth_mark("lake_interest") and _rabbit.fishing_experience >= 20 \
		and _activity_count("fishing") >= 3 and _location_count("lake") >= 4

func check_growth_path_events() -> GrowthEventData:
	if has_pending_growth_event(): return get_pending_growth_event()
	if check_sprout_mark_condition(): return _create_pending_event("growth_sprout_mark_001", "sprout_mark")
	if check_lakeside_interest_condition(): return _create_pending_event("growth_lake_interest_001", "lake_interest")
	return null
func check_growth_conditions() -> GrowthEventData:
	if _rabbit != null and not has_growth_mark("leaf_mark") and can_unlock_mark("leaf_mark") and not has_pending_growth_event():
		return _create_pending_event("growth_leaf_mark_001", "leaf_mark")
	return check_growth_path_events()
func _create_pending_event(event_id: String, mark_id: String) -> GrowthEventData:
	var event := GrowthEventData.create(event_id, mark_id); _rabbit.pending_growth_event = event.to_dict()
	growth_event_created.emit(event); growth_event_triggered.emit(event); growth_progress_changed.emit(); return event

func can_unlock_mark(mark_id: String) -> bool:
	if _rabbit == null or not _marks.has(mark_id) or has_growth_mark(mark_id): return false
	if mark_id == "sprout_mark": return check_sprout_mark_condition()
	if mark_id == "lake_interest": return check_lakeside_interest_condition()
	var mark := _marks[mark_id] as GrowthMarkData
	return _rabbit.forest_experience >= mark.required_experience and _rabbit.forest_activity_count >= mark.required_visit_count
func has_growth_mark(mark_id: String) -> bool:
	if _rabbit == null: return false
	for mark: Dictionary in _rabbit.unlocked_growth_marks:
		if str(mark.get("id", "")) == mark_id: return true
	return false
func unlock_growth_mark(mark_id: String) -> bool:
	if _rabbit == null or not _marks.has(mark_id) or has_growth_mark(mark_id): return false
	var mark := _marks[mark_id] as GrowthMarkData; mark.is_unlocked = true; mark.unlocked_at = TimeManager.get_now()
	_rabbit.unlocked_growth_marks.append(mark.to_dict()); growth_progress_changed.emit(); return true
func get_unlocked_growth_marks() -> Array[GrowthMarkData]:
	var result: Array[GrowthMarkData] = []
	for mark: GrowthMarkData in _marks.values():
		if has_growth_mark(mark.id): result.append(mark)
	return result
func has_pending_growth_event() -> bool: return _rabbit != null and not _rabbit.pending_growth_event.is_empty()
func get_pending_growth_event() -> GrowthEventData: return GrowthEventData.from_dict(_rabbit.pending_growth_event) if has_pending_growth_event() else null

func confirm_growth_event(event_id: String) -> bool:
	var event := get_pending_growth_event()
	if event == null or event.event_id != event_id or event.is_applied or has_growth_mark(event.growth_mark_id): return false
	if not unlock_growth_mark(event.growth_mark_id): return false
	var old_stage := get_forest_growth_stage() if event.growth_mark_id == "sprout_mark" else get_lakeside_growth_stage()
	if event.growth_mark_id == "leaf_mark": _progress.forest_stage = maxi(_progress.forest_stage, 1)
	elif event.growth_mark_id == "sprout_mark": _progress.forest_stage = 2
	elif event.growth_mark_id == "lake_interest": _progress.lakeside_stage = 1
	var path := "forest" if event.growth_mark_id != "lake_interest" else "lakeside"
	var new_stage := get_forest_growth_stage() if path == "forest" else get_lakeside_growth_stage()
	event.is_confirmed = true; event.is_applied = true; _progress.last_updated_at = TimeManager.get_now(); _rabbit.pending_growth_event = {}
	growth_mark_unlocked.emit(_marks[event.growth_mark_id], event); growth_path_updated.emit(path, old_stage, new_stage, event.event_id)
	growth_event_confirmed.emit(event); growth_progress_changed.emit(); return true

func get_forest_growth_stage() -> int: return _progress.forest_stage
func get_lakeside_growth_stage() -> int: return _progress.lakeside_stage
func get_forest_tendency_level() -> int: return _progress.forest_tendency_level
func get_lakeside_tendency_level() -> int: return _progress.lakeside_tendency_level
func get_growth_tendency(path_id: String) -> String:
	var level := get_lakeside_tendency_level() if path_id == "lake" or path_id == "lakeside" else get_forest_tendency_level()
	return ["none", "faint", "clear", "strong"][clampi(level, 0, 3)]
func get_growth_tendency_summary() -> Dictionary:
	return {"forest": get_growth_tendency("forest"), "lakeside": get_growth_tendency("lakeside")}
func get_growth_tendencies() -> Dictionary: return _growth_tendencies.duplicate(true)
func _update_tendency_levels() -> void:
	if _rabbit == null: return
	_progress.forest_tendency_level = 3 if _rabbit.forest_experience >= 60 and _rabbit.forest_activity_count >= 8 and _activity_count("forest_explore") >= 3 and _rabbit.intimacy >= 10 else (2 if check_sprout_mark_condition() or has_growth_mark("sprout_mark") else (1 if _rabbit.forest_experience > 0 else 0))
	_progress.lakeside_tendency_level = 3 if _rabbit.fishing_experience >= 40 and _activity_count("fishing") >= 5 and _location_count("lake") >= 7 and _rabbit.intimacy >= 8 else (2 if check_lakeside_interest_condition() or has_growth_mark("lake_interest") else (1 if _rabbit.fishing_experience > 0 else 0))

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
