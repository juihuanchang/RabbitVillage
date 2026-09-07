class_name GrowthHistoryManager
extends Node

signal history_changed

const DIRECTION_EVENT_ID := "growth_direction_001"
const VALID_FINAL_FORMS := ["none", "forest_rabbit", "lakeside_rabbit"]

var growth_direction_choice: Dictionary = {}
var final_growth_state: Dictionary = {"state": "not_completed", "branch": "balanced", "pending_at": 0.0, "complete_at": 0.0, "completed_at": 0.0, "result_applied": false}
var final_growth_history: Array[Dictionary] = []

func setup_from_save(save: SaveData) -> void:
	growth_direction_choice = save.growth_direction_choice.duplicate(true)
	final_growth_state = save.final_growth_state.duplicate(true)
	if final_growth_state.is_empty():
		final_growth_state = _default_final_state()
	final_growth_history = _sanitize_final_history(save.final_growth_history)

func sync_from_runtime(rabbit: RabbitData, growth_manager: GrowthManager) -> void:
	if rabbit == null:
		return
	if not rabbit.growth_direction_choice.is_empty():
		var choice := GrowthDirectionChoiceData.from_dict(rabbit.growth_direction_choice)
		record_choice(choice)
	if not rabbit.final_growth_state.is_empty():
		final_growth_state = rabbit.final_growth_state.duplicate(true)
	elif final_growth_state.is_empty():
		final_growth_state = _default_final_state()
	if growth_manager != null:
		repair_consistency(rabbit, growth_manager)

func record_choice(choice: GrowthDirectionChoiceData) -> GrowthDirectionChoiceHistoryEntry:
	if choice == null or choice.choice_id.is_empty():
		return null
	if not growth_direction_choice.is_empty() and not str(growth_direction_choice.get("choice_id", "")).is_empty():
		return GrowthDirectionChoiceHistoryEntry.from_dict(growth_direction_choice)
	var entry := GrowthDirectionChoiceHistoryEntry.new()
	entry.choice_id = choice.choice_id
	entry.selected_at = maxf(0.0, choice.confirmed_at)
	entry.source_event_id = choice.event_id if not choice.event_id.is_empty() else DIRECTION_EVENT_ID
	entry.resolved_branch = choice.resolved_branch
	growth_direction_choice = entry.to_dict()
	growth_direction_choice["event_id"] = entry.source_event_id
	growth_direction_choice["state"] = choice.state
	growth_direction_choice["confirmed_at"] = entry.selected_at
	history_changed.emit()
	return entry

func record_final_growth(result: FinalGrowthResult, old_stage: int = -1) -> FinalGrowthHistoryEntry:
	if result == null or not result.success or result.branch not in ["forest", "lakeside"]:
		return null
	var expected_form := "forest_rabbit" if result.branch == "forest" else "lakeside_rabbit"
	var completed_at := maxf(0.0, result.completed_at)
	var record_id := _record_id(result.branch, completed_at)
	for raw: Dictionary in final_growth_history:
		var existing := FinalGrowthHistoryEntry.from_dict(raw)
		if existing.final_growth_record_id == record_id or (existing.growth_path == result.branch and existing.final_form == expected_form):
			return existing
	var entry := FinalGrowthHistoryEntry.new()
	entry.final_growth_record_id = record_id
	entry.growth_path = result.branch
	entry.old_stage = old_stage if old_stage >= 0 else (3 if result.branch == "forest" else 2)
	entry.new_stage = 4 if result.branch == "forest" else 3
	entry.final_form = expected_form
	entry.completed_at = completed_at
	final_growth_history.append(entry.to_dict())
	final_growth_state = {
		"state": GrowthDirectionChoiceData.FINAL_COMPLETED,
		"branch": result.branch,
		"pending_at": float(final_growth_state.get("pending_at", 0.0)),
		"complete_at": float(final_growth_state.get("complete_at", 0.0)),
		"completed_at": completed_at,
		"result_applied": true
	}
	history_changed.emit()
	return entry

func repair_consistency(rabbit: RabbitData, growth_manager: GrowthManager) -> void:
	if rabbit == null:
		return
	# Restore C-owned persistent choice/pending state back into B runtime only when
	# the runtime copy is missing. This keeps pending target/date stable across reload
	# without re-evaluating B's final-growth rules.
	if rabbit.growth_direction_choice.is_empty() and not growth_direction_choice.is_empty():
		rabbit.growth_direction_choice = {
			"event_id": str(growth_direction_choice.get("source_event_id", growth_direction_choice.get("event_id", DIRECTION_EVENT_ID))),
			"state": str(growth_direction_choice.get("state", GrowthDirectionChoiceData.CHOICE_CONFIRMED)),
			"choice_id": str(growth_direction_choice.get("choice_id", "")),
			"resolved_branch": str(growth_direction_choice.get("resolved_branch", "balanced")),
			"confirmed_at": maxf(0.0, float(growth_direction_choice.get("selected_at", growth_direction_choice.get("confirmed_at", 0.0))))
		}
	if rabbit.final_growth_state.is_empty() and not final_growth_state.is_empty():
		rabbit.final_growth_state = final_growth_state.duplicate(true)
	final_growth_history = _sanitize_final_history(final_growth_history)
	var runtime_form := rabbit.current_final_form if VALID_FINAL_FORMS.has(rabbit.current_final_form) else "none"
	var chosen := _choose_legal_final_history(runtime_form)
	if chosen != null:
		# A legal permanent FinalHistory is authoritative for corrupted mutually-exclusive final forms.
		rabbit.current_final_form = chosen.final_form
		if growth_manager != null:
			var progress_variant: Variant = growth_manager.get("_progress")
			if progress_variant is GrowthPathProgressData:
				var progress: GrowthPathProgressData = progress_variant
				if chosen.final_form == "forest_rabbit": progress.forest_stage = maxi(progress.forest_stage, 4)
				elif chosen.final_form == "lakeside_rabbit": progress.lakeside_stage = maxi(progress.lakeside_stage, 3)
		final_growth_history = [chosen.to_dict()]
		final_growth_state["state"] = GrowthDirectionChoiceData.FINAL_COMPLETED
		final_growth_state["branch"] = chosen.growth_path
		final_growth_state["completed_at"] = chosen.completed_at
		final_growth_state["result_applied"] = true
	elif runtime_form in ["forest_rabbit", "lakeside_rabbit"]:
		# Completed runtime form but missing C history: backfill from B's traceable final state.
		var branch := "forest" if runtime_form == "forest_rabbit" else "lakeside"
		var state := FinalGrowthStateData.from_dict(rabbit.final_growth_state) if not rabbit.final_growth_state.is_empty() else FinalGrowthStateData.new()
		var synthetic := FinalGrowthResult.new()
		synthetic.success = true
		synthetic.branch = branch
		synthetic.current_form = runtime_form
		synthetic.completed_at = maxf(0.0, state.completed_at)
		record_final_growth(synthetic)
		if growth_manager != null:
			var progress_variant: Variant = growth_manager.get("_progress")
			if progress_variant is GrowthPathProgressData:
				var progress: GrowthPathProgressData = progress_variant
				if branch == "forest": progress.forest_stage = maxi(progress.forest_stage, 4)
				else: progress.lakeside_stage = maxi(progress.lakeside_stage, 3)
	else:
		# Week7 Stage3 / Stage2 alone must never become a final form during migration/load.
		if str(final_growth_state.get("state", "")).is_empty() or str(final_growth_state.get("state", "")) == GrowthDirectionChoiceData.FINAL_COMPLETED:
			final_growth_state = _default_final_state()

func get_choice_entry() -> GrowthDirectionChoiceHistoryEntry:
	return GrowthDirectionChoiceHistoryEntry.from_dict(growth_direction_choice) if not growth_direction_choice.is_empty() else null

func get_final_growth(final_growth_record_id: String) -> FinalGrowthHistoryEntry:
	for raw: Dictionary in final_growth_history:
		var entry := FinalGrowthHistoryEntry.from_dict(raw)
		if entry.final_growth_record_id == final_growth_record_id:
			return entry
	return null

func get_completed_final_growth() -> FinalGrowthHistoryEntry:
	return _choose_legal_final_history("none")

func final_growth_history_to_array() -> Array[Dictionary]:
	return final_growth_history.duplicate(true)

func _choose_legal_final_history(preferred_form: String) -> FinalGrowthHistoryEntry:
	var candidates: Array[FinalGrowthHistoryEntry] = []
	for raw: Dictionary in final_growth_history:
		var entry := FinalGrowthHistoryEntry.from_dict(raw)
		if entry.growth_path not in ["forest", "lakeside"]:
			continue
		if entry.final_form not in ["forest_rabbit", "lakeside_rabbit"]:
			continue
		if entry.new_stage < (4 if entry.growth_path == "forest" else 3):
			continue
		candidates.append(entry)
	if candidates.is_empty():
		return null
	if preferred_form in ["forest_rabbit", "lakeside_rabbit"]:
		for entry: FinalGrowthHistoryEntry in candidates:
			if entry.final_form == preferred_form:
				return entry
	candidates.sort_custom(func(a: FinalGrowthHistoryEntry, b: FinalGrowthHistoryEntry) -> bool:
		if a.completed_at <= 0.0 and b.completed_at > 0.0: return false
		if b.completed_at <= 0.0 and a.completed_at > 0.0: return true
		return a.completed_at < b.completed_at
	)
	return candidates[0]

func _sanitize_final_history(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array):
		return result
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := FinalGrowthHistoryEntry.from_dict(raw)
		if entry.final_growth_record_id.is_empty():
			entry.final_growth_record_id = _record_id(entry.growth_path, entry.completed_at)
		if entry.growth_path not in ["forest", "lakeside"] or entry.final_form not in ["forest_rabbit", "lakeside_rabbit"]:
			continue
		if seen.has(entry.final_growth_record_id):
			continue
		seen[entry.final_growth_record_id] = true
		result.append(entry.to_dict())
	return result

func _record_id(branch: String, completed_at: float) -> String:
	var suffix := int(round(maxf(0.0, completed_at) * 1000.0))
	return "final_growth_%s_%d" % [branch, suffix]

func _default_final_state() -> Dictionary:
	return {"state": "not_completed", "branch": "balanced", "pending_at": 0.0, "complete_at": 0.0, "completed_at": 0.0, "result_applied": false}
