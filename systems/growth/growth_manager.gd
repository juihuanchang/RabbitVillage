class_name GrowthManager
extends Node

signal growth_event_created(event: GrowthEventData)
signal growth_mark_unlocked(mark: GrowthMarkData, event: GrowthEventData)
signal growth_progress_changed
signal growth_path_updated(growth_path: String, old_stage: int, new_stage: int, source_event_id: String)
signal growth_event_triggered(event_data: GrowthEventData)
signal growth_event_confirmed(event_data: GrowthEventData)
signal final_growth_completed(result: FinalGrowthResult)

var _rabbit: RabbitData
var _marks: Dictionary = {}
var _activity_records: Array[Dictionary] = []
var _growth_tendencies: Dictionary = {"forest": 0, "lake": 0, "home": 0}
var _progress := GrowthPathProgressData.new()
var _completed_life_event_ids: Array[String] = []
const DOMINANT_SAFE_GAP := 3
const FINAL_DELAY_SECONDS := 86400.0
const FINAL_FORMS := ["none", "forest_rabbit", "lakeside_rabbit"]

func _init() -> void:
	_marks["leaf_mark"] = GrowthMarkData.create_leaf_mark()
	_marks["sprout_mark"] = GrowthMarkData.create("sprout_mark", "forest", 2)
	_marks["lake_interest"] = GrowthMarkData.create("lake_interest", "lakeside", 1)
	_marks["forest_stage3"] = GrowthMarkData.create("forest_stage3", "forest", 3)
	_marks["lakeside_stage2"] = GrowthMarkData.create("lakeside_stage2", "lakeside", 2)

func setup(rabbit: RabbitData) -> void:
	_rabbit = rabbit
	if _rabbit.move_in_date.is_empty(): _rabbit.move_in_date = Time.get_date_string_from_system()
	if not FINAL_FORMS.has(_rabbit.current_final_form): _rabbit.current_final_form = "none"
	for mark: GrowthMarkData in _marks.values(): mark.is_unlocked = false; mark.unlocked_at = 0.0
	for saved_mark: Dictionary in rabbit.unlocked_growth_marks:
		var mark_id := str(saved_mark.get("id", ""))
		if _marks.has(mark_id):
			var mark := _marks[mark_id] as GrowthMarkData; mark.is_unlocked = true
			mark.unlocked_at = float(saved_mark.get("unlocked_at", 0.0))
	_progress.forest_stage = 3 if has_growth_mark("forest_stage3") else (2 if has_growth_mark("sprout_mark") else (1 if has_growth_mark("leaf_mark") else 0))
	_progress.lakeside_stage = 2 if has_growth_mark("lakeside_stage2") else (1 if has_growth_mark("lake_interest") else 0)
	if _rabbit.current_final_form == "forest_rabbit": _progress.forest_stage = maxi(_progress.forest_stage, 4)
	elif _rabbit.current_final_form == "lakeside_rabbit": _progress.lakeside_stage = maxi(_progress.lakeside_stage, 3)
	_update_tendency_levels(); growth_progress_changed.emit()

func load_from_save_data(data: SaveData) -> void:
	_activity_records.clear()
	for record: Dictionary in data.all_activity_records: _activity_records.append(record.duplicate(true))
	if _activity_records.is_empty():
		for record_id: String in data.completed_activity_ids: _activity_records.append({"activity_record_id": record_id})
	_growth_tendencies = data.growth_tendencies.duplicate(true)
	_progress.forest_stage = maxi(_progress.forest_stage, int(data.growth_path_progress.get("forest_stage", 0)))
	_progress.lakeside_stage = maxi(_progress.lakeside_stage, int(data.growth_path_progress.get("lakeside_stage", 0)))
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
		and not _has_completed_growth_event("growth_sprout_mark_001") \
		and _rabbit.forest_experience >= 60 and _rabbit.forest_activity_count >= 8 \
		and _activity_count("forest_explore") >= 3 and _rabbit.intimacy >= 10
func check_lakeside_interest_condition() -> bool:
	return _rabbit != null and not has_growth_mark("lake_interest") \
		and not _has_completed_growth_event("growth_lake_interest_001") \
		and _rabbit.fishing_experience >= 40 and _activity_count("fishing") >= 5 \
		and _location_count("lake") >= 7 and _rabbit.intimacy >= 8
func set_completed_life_event_ids(ids: Array[String]) -> void: _completed_life_event_ids = ids.duplicate()
func check_forest_stage3_condition() -> bool:
	return _rabbit != null and get_forest_growth_stage() >= 2 and not has_growth_mark("forest_stage3") and _rabbit.forest_experience >= 85 and _location_count("forest") >= 12 and _count_life_events("forest") >= 2 and _rabbit.intimacy >= 15
func check_lakeside_stage2_condition() -> bool:
	return _rabbit != null and get_lakeside_growth_stage() >= 1 and not has_growth_mark("lakeside_stage2") and _rabbit.fishing_experience >= 65 and _location_count("lake") >= 10 and _count_life_events("lake") >= 2 and _rabbit.intimacy >= 12
func _count_life_events(path: String) -> int:
	var count := 0
	for id: String in _completed_life_event_ids:
		if id.contains(path) or (path == "lake" and id.contains("fishing")): count += 1
	return count

func _has_completed_growth_event(event_id: String) -> bool:
	if event_id == "growth_sprout_mark_001":
		return has_growth_mark("sprout_mark")
	if event_id == "growth_lake_interest_001":
		return has_growth_mark("lake_interest")
	if event_id == "growth_forest_stage3_001": return has_growth_mark("forest_stage3")
	if event_id == "growth_lakeside_stage2_001": return has_growth_mark("lakeside_stage2")
	return false

func check_growth_path_events() -> GrowthEventData:
	if has_pending_growth_event(): return get_pending_growth_event()
	if check_sprout_mark_condition(): return _create_pending_event("growth_sprout_mark_001", "sprout_mark")
	if check_lakeside_interest_condition(): return _create_pending_event("growth_lake_interest_001", "lake_interest")
	if check_forest_stage3_condition(): return _create_pending_event("growth_forest_stage3_001", "forest_stage3")
	if check_lakeside_stage2_condition(): return _create_pending_event("growth_lakeside_stage2_001", "lakeside_stage2")
	return null
func check_growth_conditions() -> GrowthEventData:
	check_final_growth_conditions()
	if get_final_growth_state().state == GrowthDirectionChoiceData.FINAL_PENDING: return null
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
	if mark_id == "forest_stage3": return check_forest_stage3_condition()
	if mark_id == "lakeside_stage2": return check_lakeside_stage2_condition()
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
	var is_forest := event.growth_mark_id in ["leaf_mark", "sprout_mark", "forest_stage3"]
	var old_stage := get_forest_growth_stage() if is_forest else get_lakeside_growth_stage()
	if event.growth_mark_id == "leaf_mark": _progress.forest_stage = maxi(_progress.forest_stage, 1)
	elif event.growth_mark_id == "sprout_mark": _progress.forest_stage = 2
	elif event.growth_mark_id == "lake_interest": _progress.lakeside_stage = 1
	elif event.growth_mark_id == "forest_stage3": _progress.forest_stage = 3
	elif event.growth_mark_id == "lakeside_stage2": _progress.lakeside_stage = 2
	var path := "forest" if is_forest else "lakeside"
	var new_stage := get_forest_growth_stage() if path == "forest" else get_lakeside_growth_stage()
	event.is_confirmed = true; event.is_applied = true; _progress.last_updated_at = TimeManager.get_now(); _rabbit.pending_growth_event = {}
	growth_mark_unlocked.emit(_marks[event.growth_mark_id], event); growth_path_updated.emit(path, old_stage, new_stage, event.event_id)
	growth_event_confirmed.emit(event)
	growth_progress_changed.emit()
	# 若森林與湖畔條件同時成立，確認目前事件後自動建立下一個 pending。
	call_deferred("check_growth_path_events")
	return true

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
func get_dominant_tendency() -> String:
	var forest := int(_growth_tendencies.get("forest", 0)); var lake := int(_growth_tendencies.get("lake", 0))
	if absi(forest - lake) < DOMINANT_SAFE_GAP: return "balanced"
	return "forest" if forest > lake else "lakeside"
func get_appearance_state() -> String:
	if _rabbit != null and _rabbit.current_final_form == "forest_rabbit": return "forest_final"
	if _rabbit != null and _rabbit.current_final_form == "lakeside_rabbit": return "lakeside_final"
	if get_forest_growth_stage() >= 3: return "forest_stage3"
	if get_lakeside_growth_stage() >= 2: return "lakeside_stage2"
	if has_growth_mark("sprout_mark"): return "sprout"
	if has_growth_mark("leaf_mark"): return "leaf"
	return "normal"

func can_show_growth_direction_event() -> bool:
	if _rabbit == null or _rabbit.current_final_form != "none": return false
	var choice := get_growth_direction_choice()
	return choice.choice_id.is_empty() and (get_forest_growth_stage() >= 3 or get_lakeside_growth_stage() >= 2)
func get_growth_direction_options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in GrowthDirectionChoiceData.VALID_CHOICES: result.append({"choice_id": id, "available": can_show_growth_direction_event()})
	return result
func get_growth_direction_choice() -> GrowthDirectionChoiceData:
	var value := GrowthDirectionChoiceData.from_dict(_rabbit.growth_direction_choice) if _rabbit != null and not _rabbit.growth_direction_choice.is_empty() else GrowthDirectionChoiceData.new()
	if value.choice_id.is_empty() and can_show_growth_direction_event_unchecked(): value.state = GrowthDirectionChoiceData.AVAILABLE
	return value
func can_show_growth_direction_event_unchecked() -> bool: return _rabbit != null and _rabbit.current_final_form == "none" and (get_forest_growth_stage() >= 3 or get_lakeside_growth_stage() >= 2)
func submit_growth_direction_choice(choice_id: String) -> GrowthDirectionResult:
	var result := GrowthDirectionResult.new(); result.choice_id = choice_id
	if _rabbit == null or not GrowthDirectionChoiceData.VALID_CHOICES.has(choice_id): result.reason = "invalid_choice"; return result
	var existing := get_growth_direction_choice()
	if not existing.choice_id.is_empty(): result.reason = "choice_already_confirmed"; result.state = existing.state; result.resolved_branch = existing.resolved_branch; return result
	if not can_show_growth_direction_event(): result.reason = "choice_not_available"; return result
	var branch := "balanced"
	match choice_id:
		"encourage_forest": branch = "forest"
		"encourage_lakeside": branch = "lakeside"
		"let_rabbit_decide": branch = _decide_final_branch()
	var choice := GrowthDirectionChoiceData.new(); choice.choice_id = choice_id; choice.resolved_branch = branch; choice.confirmed_at = TimeManager.get_now(); choice.state = GrowthDirectionChoiceData.CHOICE_CONFIRMED
	_rabbit.growth_direction_choice = choice.to_dict(); result.success = true; result.resolved_branch = branch; result.state = choice.state
	check_final_growth_conditions(); growth_progress_changed.emit(); return result
func _decide_final_branch() -> String:
	var forest_score := _rabbit.forest_experience + _location_count("forest") * 5 + _count_life_events("forest") * 10 + get_forest_tendency_level() * 8
	var lake_score := _rabbit.fishing_experience + _location_count("lake") * 5 + _count_life_events("lake") * 10 + get_lakeside_tendency_level() * 8
	if absi(forest_score - lake_score) < 15: return "balanced"
	return "forest" if forest_score > lake_score else "lakeside"
func get_final_growth_condition(branch: String) -> FinalGrowthConditionData:
	var condition := FinalGrowthConditionData.new(); condition.branch = branch
	if branch == "forest": condition.required_stage = 3; condition.required_experience = 120; condition.required_activity_count = 16; condition.required_event_count = 3; condition.required_intimacy = 20
	elif branch == "lakeside": condition.required_stage = 2; condition.required_experience = 100; condition.required_activity_count = 14; condition.required_event_count = 3; condition.required_intimacy = 18
	return condition
func is_final_growth_eligible(branch: String) -> bool:
	if _rabbit == null or _rabbit.current_final_form != "none": return false
	var choice := get_growth_direction_choice(); if choice.choice_id == "maintain_current" or choice.resolved_branch != branch: return false
	var c := get_final_growth_condition(branch)
	if branch == "forest": return get_forest_growth_stage() >= c.required_stage and _rabbit.forest_experience >= c.required_experience and _location_count("forest") >= c.required_activity_count and _count_life_events("forest") >= c.required_event_count and _rabbit.intimacy >= c.required_intimacy
	if branch == "lakeside": return get_lakeside_growth_stage() >= c.required_stage and _rabbit.fishing_experience >= c.required_experience and _location_count("lake") >= c.required_activity_count and _count_life_events("lake") >= c.required_event_count and _rabbit.intimacy >= c.required_intimacy
	return false
func get_final_growth_state() -> FinalGrowthStateData: return FinalGrowthStateData.from_dict(_rabbit.final_growth_state) if _rabbit != null and not _rabbit.final_growth_state.is_empty() else FinalGrowthStateData.new()
func check_final_growth_conditions() -> FinalGrowthStateData:
	var state := get_final_growth_state()
	if _rabbit == null or _rabbit.current_final_form != "none" or state.state == GrowthDirectionChoiceData.FINAL_COMPLETED or state.state == GrowthDirectionChoiceData.FINAL_PENDING: return state
	var choice := get_growth_direction_choice()
	if choice.choice_id == "maintain_current" or choice.resolved_branch == "balanced": return state
	if is_final_growth_eligible(choice.resolved_branch):
		state.state = GrowthDirectionChoiceData.FINAL_PENDING; state.branch = choice.resolved_branch; state.pending_at = TimeManager.get_now(); state.complete_at = state.pending_at + FINAL_DELAY_SECONDS; _rabbit.final_growth_state = state.to_dict(); choice.state = GrowthDirectionChoiceData.FINAL_PENDING; _rabbit.growth_direction_choice = choice.to_dict(); growth_progress_changed.emit()
	return state
func check_final_growth_completion(now: float = -1.0) -> FinalGrowthResult:
	var result := FinalGrowthResult.new(); var state := get_final_growth_state(); var check_time := TimeManager.get_now() if now < 0.0 else now
	if state.state != GrowthDirectionChoiceData.FINAL_PENDING or check_time < state.complete_at: return result
	if state.result_applied or _rabbit.current_final_form != "none": return result
	state.result_applied = true; state.state = GrowthDirectionChoiceData.FINAL_COMPLETED; state.completed_at = check_time
	if state.branch == "forest": _progress.forest_stage = maxi(_progress.forest_stage, 4); _rabbit.current_final_form = "forest_rabbit"
	elif state.branch == "lakeside": _progress.lakeside_stage = maxi(_progress.lakeside_stage, 3); _rabbit.current_final_form = "lakeside_rabbit"
	else: return result
	_rabbit.final_growth_state = state.to_dict(); var choice := get_growth_direction_choice(); choice.state = GrowthDirectionChoiceData.FINAL_COMPLETED; _rabbit.growth_direction_choice = choice.to_dict()
	result.success = true; result.branch = state.branch; result.current_form = _rabbit.current_final_form; result.completed_at = check_time; result.first_completion = true; growth_progress_changed.emit(); final_growth_completed.emit(result); return result
func get_current_final_form() -> String: return _rabbit.current_final_form if _rabbit != null else "none"
func get_branch_reaction_context(context_id: String) -> Dictionary:
	var branch := get_dominant_tendency(); var form := get_current_final_form()
	if form == "forest_rabbit": branch = "forest"
	elif form == "lakeside_rabbit": branch = "lakeside"
	return {"context_id": context_id, "branch": branch, "current_form": form, "reaction_tag": "%s_%s" % [branch, context_id], "mood_bonus": 2 if (branch == "forest" and context_id == "forest") or (branch == "lakeside" and context_id == "lakeside") else 0, "reward_chance_bonus": 0.05 if (branch == "forest" and context_id == "forest") or (branch == "lakeside" and context_id == "lakeside") else 0.0, "growth_form": form}
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
