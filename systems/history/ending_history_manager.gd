class_name EndingHistoryManager
extends Node

signal history_changed

const STAGE1_EVENT_ID := "village_stage1_complete_001"

var stage1_completion_state: Dictionary = {"state": "not_completed", "completed_at": 0.0, "source_event_id": STAGE1_EVENT_ID}
var stage1_completion_history: Array[Dictionary] = []
var ending_state: Dictionary = {"state": "locked", "ending_id": "stage1_ending", "created_at": 0.0, "completed_at": 0.0}
var ending_history: Array[Dictionary] = []
var ending_snapshots: Array[Dictionary] = []
var ending_seen := false
var post_ending_state: Dictionary = {"is_post_ending": false, "started_at": 0.0, "ending_id": ""}

func setup_from_save(save: SaveData) -> void:
	stage1_completion_state = save.stage1_completion_state.duplicate(true)
	if stage1_completion_state.is_empty(): stage1_completion_state = _default_stage_state()
	stage1_completion_history = _sanitize_stage_history(save.stage1_completion_history)
	ending_state = save.ending_state.duplicate(true)
	if ending_state.is_empty(): ending_state = _default_ending_state()
	ending_history = _sanitize_ending_history(save.ending_history)
	ending_snapshots = _sanitize_snapshots(save.ending_snapshots)
	ending_seen = save.ending_seen
	post_ending_state = save.post_ending_state.duplicate(true)
	if post_ending_state.is_empty(): post_ending_state = _default_post_state()
	repair_basic_consistency()

func record_stage1_completion(result: StageCompletionResult) -> StageCompletionHistoryEntry:
	if result == null or not result.success:
		return null
	for raw: Dictionary in stage1_completion_history:
		var existing := StageCompletionHistoryEntry.from_dict(raw)
		if existing.stage_id == result.stage_id:
			return existing
	var entry := StageCompletionHistoryEntry.new()
	entry.stage_id = result.stage_id if not result.stage_id.is_empty() else "stage1"
	entry.completed_at = maxf(0.0, result.completed_at)
	entry.source_event_id = STAGE1_EVENT_ID
	stage1_completion_history.append(entry.to_dict())
	stage1_completion_state = {"state": "completed", "completed_at": entry.completed_at, "source_event_id": entry.source_event_id}
	history_changed.emit()
	return entry

func sync_ending_state(state: EndingStateData) -> void:
	if state == null:
		return
	var incoming := state.to_dict()
	if ending_state != incoming:
		ending_state = incoming
		history_changed.emit()

func record_ending(result: EndingResult, profile_snapshot: RabbitLifeProfileSnapshot, save: SaveData, milestones: Array[Dictionary]) -> EndingHistoryEntry:
	if result == null or result.ending_id.is_empty() or result.completed_at <= 0.0:
		return null
	var existing := get_ending_history(result.ending_id)
	if existing != null:
		ending_seen = true
		_ensure_post_ending(existing.ending_id, existing.completed_at)
		if get_snapshot(existing.snapshot_id) == null:
			repair_missing_snapshot(result, profile_snapshot, save, milestones)
		return existing
	var snapshot_id := "ending_snapshot_%s" % result.ending_id
	var snapshot := _create_snapshot(snapshot_id, result, profile_snapshot, save, milestones)
	var entry := EndingHistoryEntry.new()
	entry.ending_id = result.ending_id
	entry.ending_type = result.ending_type
	entry.completed_at = maxf(0.0, result.completed_at)
	entry.final_form = result.current_form
	entry.snapshot_id = snapshot.snapshot_id if snapshot != null else snapshot_id
	ending_history.append(entry.to_dict())
	ending_state = {"state": EndingStateData.COMPLETED, "ending_id": result.ending_id, "created_at": float(ending_state.get("created_at", 0.0)), "completed_at": entry.completed_at}
	ending_seen = true
	_ensure_post_ending(entry.ending_id, entry.completed_at)
	history_changed.emit()
	return entry

func repair_missing_snapshot(result: EndingResult, profile_snapshot: RabbitLifeProfileSnapshot, save: SaveData, milestones: Array[Dictionary]) -> EndingMemorySnapshot:
	if result == null or result.ending_id.is_empty():
		return null
	var history := get_ending_history(result.ending_id)
	if history == null:
		return null
	var existing := get_snapshot(history.snapshot_id)
	if existing != null:
		return existing
	# Repair only from traceable ending payload and records dated no later than the ending.
	# No random memory selection is performed here.
	var repaired := _create_snapshot(history.snapshot_id, result, profile_snapshot, save, milestones)
	if repaired != null:
		repaired.ending_payload["snapshot_repaired"] = true
		_replace_snapshot(repaired)
		history_changed.emit()
	return repaired

func repair_basic_consistency() -> void:
	stage1_completion_history = _sanitize_stage_history(stage1_completion_history)
	ending_history = _sanitize_ending_history(ending_history)
	ending_snapshots = _sanitize_snapshots(ending_snapshots)
	if not ending_history.is_empty():
		var first := EndingHistoryEntry.from_dict(ending_history[0])
		ending_seen = true
		ending_state = {"state": EndingStateData.COMPLETED, "ending_id": first.ending_id, "created_at": float(ending_state.get("created_at", 0.0)), "completed_at": first.completed_at}
		_ensure_post_ending(first.ending_id, first.completed_at)
	if not stage1_completion_history.is_empty():
		var stage := StageCompletionHistoryEntry.from_dict(stage1_completion_history[0])
		stage1_completion_state = {"state": "completed", "completed_at": stage.completed_at, "source_event_id": stage.source_event_id}

func get_stage1_history() -> StageCompletionHistoryEntry:
	for raw: Dictionary in stage1_completion_history:
		var entry := StageCompletionHistoryEntry.from_dict(raw)
		if entry.stage_id == "stage1": return entry
	return null

func get_ending_history(ending_id: String) -> EndingHistoryEntry:
	for raw: Dictionary in ending_history:
		var entry := EndingHistoryEntry.from_dict(raw)
		if entry.ending_id == ending_id: return entry
	return null

func get_snapshot(snapshot_id: String) -> EndingMemorySnapshot:
	for raw: Dictionary in ending_snapshots:
		var snapshot := EndingMemorySnapshot.from_dict(raw)
		if snapshot.snapshot_id == snapshot_id: return snapshot
	return null

func get_replay_snapshot(ending_id: String) -> EndingMemorySnapshot:
	var history := get_ending_history(ending_id)
	return get_snapshot(history.snapshot_id) if history != null else null

func stage1_history_to_array() -> Array[Dictionary]: return stage1_completion_history.duplicate(true)
func ending_history_to_array() -> Array[Dictionary]: return ending_history.duplicate(true)
func ending_snapshots_to_array() -> Array[Dictionary]: return ending_snapshots.duplicate(true)

func _create_snapshot(snapshot_id: String, result: EndingResult, profile_snapshot: RabbitLifeProfileSnapshot, save: SaveData, milestones: Array[Dictionary]) -> EndingMemorySnapshot:
	if result == null or save == null:
		return null
	var existing := get_snapshot(snapshot_id)
	if existing != null:
		return existing
	var snapshot := EndingMemorySnapshot.new()
	snapshot.snapshot_id = snapshot_id
	snapshot.ending_id = result.ending_id
	snapshot.created_at = maxf(0.0, result.completed_at)
	if profile_snapshot != null:
		snapshot.profile_snapshot_id = profile_snapshot.snapshot_id
		snapshot.profile_snapshot = profile_snapshot.to_dict()
	snapshot.timeline = _timeline_before(milestones, snapshot.created_at)
	snapshot.important_memories = _merge_ending_memories(profile_snapshot, result, save, snapshot.created_at)
	snapshot.growth_album_highlights = _album_before(save.growth_album_entries, snapshot.created_at)
	snapshot.ending_payload = result.to_dict()
	ending_snapshots.append(snapshot.to_dict())
	history_changed.emit()
	return snapshot

func repair_missing_snapshot_from_history(history: EndingHistoryEntry, profile_snapshot: RabbitLifeProfileSnapshot, save: SaveData, milestones: Array[Dictionary]) -> EndingMemorySnapshot:
	if history == null or save == null or history.ending_id.is_empty():
		return null
	var snapshot_id := history.snapshot_id if not history.snapshot_id.is_empty() else "ending_snapshot_%s" % history.ending_id
	var existing := get_snapshot(snapshot_id)
	if existing != null:
		return existing
	# Conservative repair path for an old/corrupt save where EndingHistory survived but
	# B's original EndingResult did not. Only traceable permanent data dated at or before
	# the original completion time is used. No memories are randomly re-selected.
	var snapshot := EndingMemorySnapshot.new()
	snapshot.snapshot_id = snapshot_id
	snapshot.ending_id = history.ending_id
	snapshot.created_at = maxf(0.0, history.completed_at)
	if profile_snapshot != null:
		var repaired_profile := RabbitLifeProfileSnapshot.from_dict(profile_snapshot.to_dict())
		# EndingHistory permanently records the form/type at completion; prefer those
		# traceable values over the rabbit's possibly-changed post-ending runtime state.
		repaired_profile.current_form = history.final_form
		if history.ending_type in ["forest", "lakeside"]:
			repaired_profile.dominant_tendency = history.ending_type
		elif history.ending_type == "maintain":
			repaired_profile.dominant_tendency = "balanced"
		snapshot.profile_snapshot_id = repaired_profile.snapshot_id
		snapshot.profile_snapshot = repaired_profile.to_dict()
		snapshot.important_memories = _memories_from_profile(repaired_profile, snapshot.created_at)
	snapshot.timeline = _timeline_before(milestones, snapshot.created_at)
	snapshot.growth_album_highlights = _album_before(save.growth_album_entries, snapshot.created_at)
	snapshot.ending_payload = {
		"ending_id": history.ending_id,
		"ending_type": history.ending_type,
		"current_form": history.final_form,
		"final_form": history.final_form,
		"completed_at": history.completed_at,
		"snapshot_repaired": true
	}
	ending_snapshots.append(snapshot.to_dict())
	# Keep a valid link even when an older history entry had an empty snapshot_id.
	for i in range(ending_history.size()):
		if str(ending_history[i].get("ending_id", "")) == history.ending_id:
			ending_history[i]["snapshot_id"] = snapshot_id
			break
	history_changed.emit()
	return snapshot

func _merge_ending_memories(profile_snapshot: RabbitLifeProfileSnapshot, result: EndingResult, save: SaveData, ending_at: float) -> Array[Dictionary]:
	var output := _memories_from_profile(profile_snapshot, ending_at)
	var seen := {}
	for raw: Dictionary in output:
		seen["%s:%s" % [str(raw.get("source_type", "")), str(raw.get("source_id", ""))]] = true
	for raw: Dictionary in _ending_memories_from_payload(result, save, ending_at):
		var key := "%s:%s" % [str(raw.get("source_type", "")), str(raw.get("source_id", ""))]
		if seen.has(key):
			continue
		seen[key] = true
		output.append(raw.duplicate(true))
	return output

func _memories_from_profile(profile_snapshot: RabbitLifeProfileSnapshot, ending_at: float) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if profile_snapshot == null:
		return output
	var seen := {}
	for raw: Dictionary in profile_snapshot.important_memories:
		var at := maxf(0.0, float(raw.get("at", 0.0)))
		if ending_at > 0.0 and at > ending_at:
			continue
		var key := "%s:%s" % [str(raw.get("source_type", "")), str(raw.get("source_id", ""))]
		if seen.has(key):
			continue
		seen[key] = true
		output.append(raw.duplicate(true))
	return output

func _ending_memories_from_payload(result: EndingResult, save: SaveData, ending_at: float) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	var seen := {}
	for id: String in result.important_memories:
		if id.is_empty() or seen.has(id): continue
		seen[id] = true
		var at := 0.0
		for raw: Dictionary in save.life_event_history:
			if str(raw.get("life_event_id", "")) == id:
				at = maxf(0.0, float(raw.get("confirmed_at", 0.0))); break
		if ending_at > 0.0 and at > ending_at: continue
		output.append({"source_type": "life_event", "source_id": id, "title": id, "at": at})
	return output

func _album_before(source: Variant, ending_at: float, limit := 8) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	if source is Array:
		for raw: Variant in source:
			if not (raw is Dictionary): continue
			var at := maxf(0.0, float(raw.get("unlocked_at", 0.0)))
			if ending_at > 0.0 and at > ending_at: continue
			values.append(raw.duplicate(true))
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("unlocked_at", 0.0)) > float(b.get("unlocked_at", 0.0)))
	while values.size() > limit: values.pop_back()
	return values

func _timeline_before(source: Variant, ending_at: float) -> Array[Dictionary]:
	var values: Array[Dictionary] = []
	if source is Array:
		for raw: Variant in source:
			if not (raw is Dictionary): continue
			var at := maxf(0.0, float(raw.get("occurred_at", 0.0)))
			if ending_at > 0.0 and at > ending_at: continue
			values.append(raw.duplicate(true))
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var at_a := float(a.get("occurred_at", 0.0)); var at_b := float(b.get("occurred_at", 0.0))
		if at_a <= 0.0 and at_b > 0.0: return true
		if at_b <= 0.0 and at_a > 0.0: return false
		return at_a < at_b
	)
	return values

func _ensure_post_ending(ending_id: String, completed_at: float) -> void:
	post_ending_state = {"is_post_ending": true, "started_at": maxf(0.0, completed_at), "ending_id": ending_id}

func _replace_snapshot(snapshot: EndingMemorySnapshot) -> void:
	for i in range(ending_snapshots.size()):
		if str(ending_snapshots[i].get("snapshot_id", "")) == snapshot.snapshot_id:
			ending_snapshots[i] = snapshot.to_dict(); return
	ending_snapshots.append(snapshot.to_dict())

func _sanitize_stage_history(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array): return result
	for raw: Variant in source:
		if not (raw is Dictionary): continue
		var entry := StageCompletionHistoryEntry.from_dict(raw)
		if entry.stage_id.is_empty() or seen.has(entry.stage_id): continue
		seen[entry.stage_id] = true; result.append(entry.to_dict())
	return result

func _sanitize_ending_history(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array): return result
	for raw: Variant in source:
		if not (raw is Dictionary): continue
		var entry := EndingHistoryEntry.from_dict(raw)
		if entry.ending_id.is_empty() or seen.has(entry.ending_id): continue
		seen[entry.ending_id] = true; result.append(entry.to_dict())
	return result

func _sanitize_snapshots(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array): return result
	for raw: Variant in source:
		if not (raw is Dictionary): continue
		var snapshot := EndingMemorySnapshot.from_dict(raw)
		if snapshot.snapshot_id.is_empty() or seen.has(snapshot.snapshot_id): continue
		seen[snapshot.snapshot_id] = true; result.append(snapshot.to_dict())
	return result

func _default_stage_state() -> Dictionary:
	return {"state": "not_completed", "completed_at": 0.0, "source_event_id": STAGE1_EVENT_ID}
func _default_ending_state() -> Dictionary:
	return {"state": "locked", "ending_id": "stage1_ending", "created_at": 0.0, "completed_at": 0.0}
func _default_post_state() -> Dictionary:
	return {"is_post_ending": false, "started_at": 0.0, "ending_id": ""}
