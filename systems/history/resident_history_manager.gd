class_name ResidentHistoryManager
extends Node

signal history_changed

var resident_states: Dictionary = {}
var resident_arrival_history: Array[Dictionary] = []
var resident_first_meeting_history: Array[Dictionary] = []
var resident_interaction_history: Array[Dictionary] = []
var resident_relationship_history: Array[Dictionary] = []
var shared_activity_history: Array[Dictionary] = []
var resident_visit_history: Array[Dictionary] = []
var resident_gift_history: Array[Dictionary] = []
var resident_letter_history: Array[Dictionary] = []
var resident_invitation_history: Array[Dictionary] = []
var resident_social_experience_history: Array[Dictionary] = []

func setup_from_save(save: SaveData) -> void:
	resident_states = save.resident_states.duplicate(true)
	resident_arrival_history = _dedup_history(save.resident_arrival_history, "resident_id")
	resident_first_meeting_history = _dedup_history(save.resident_first_meeting_history, "resident_id")
	resident_interaction_history = _dedup_history(save.resident_interaction_history, "interaction_id")
	resident_relationship_history = _dedup_history(save.resident_relationship_history, "relationship_history_id")
	shared_activity_history = _dedup_history(save.shared_activity_history, "activity_record_id")
	resident_visit_history = _dedup_history(save.resident_visit_history, "event_id")
	resident_gift_history = _dedup_history(save.resident_gift_history, "event_id")
	resident_letter_history = _dedup_history(save.resident_letter_history, "event_id")
	resident_invitation_history = _dedup_history(save.resident_invitation_history, "invitation_id")
	resident_social_experience_history = _dedup_history(save.resident_social_experience_history, "source_id")
	_repair_event_id_uniqueness()

func sync_from_runtime(manager: ResidentManager, fallback_at := 0.0) -> void:
	if manager == null:
		return
	var at := TimeManager.get_now() if fallback_at <= 0.0 else fallback_at
	for resident_id: String in ResidentManager.VALID_RESIDENT_IDS:
		var resident := manager.get_resident(resident_id)
		if resident == null:
			continue
		sync_resident_state(resident)
		if resident.state.state != ResidentStateData.LOCKED:
			record_arrival(resident, _arrival_source_for(resident), resident.state.arrived_at if resident.state.arrived_at > 0.0 else at)
		_import_runtime_relationship_history(resident, at)
		_import_runtime_social_history(resident, at)
		_repair_first_meeting(resident, at)
		_repair_runtime_guards(resident)
		_repair_relationship_state(resident, at)
		sync_resident_state(resident)
	manager.commit_runtime_state()

func sync_resident_state(resident: ResidentData) -> void:
	if resident == null or resident.resident_id.is_empty():
		return
	resident_states[resident.resident_id] = resident.to_dict()

func record_arrival(resident: ResidentData, source_event_id := "", at := -1.0) -> ResidentHistoryEntry:
	if resident == null or resident.resident_id.is_empty() or resident.state.state == ResidentStateData.LOCKED:
		return null
	var existing := get_arrival(resident.resident_id)
	if existing != null:
		sync_resident_state(resident)
		return existing
	var entry := ResidentHistoryEntry.new()
	entry.resident_id = resident.resident_id
	entry.history_type = ResidentHistoryEntry.ARRIVAL
	entry.source_event_id = source_event_id
	entry.created_at = resident.state.arrived_at if at <= 0.0 else at
	if entry.created_at <= 0.0:
		entry.created_at = TimeManager.get_now()
	entry.location_id = resident.state.current_location
	entry.history_id = "resident_arrival_%s_%d" % [resident.resident_id, int(round(entry.created_at * 1000.0))]
	resident_arrival_history.append(entry.to_dict())
	sync_resident_state(resident)
	history_changed.emit()
	return entry

func record_first_meeting(resident_id: String, source_id: String, at := -1.0, location_id := "") -> ResidentHistoryEntry:
	if resident_id.is_empty():
		return null
	var existing := get_first_meeting(resident_id)
	if existing != null:
		return existing
	var entry := ResidentHistoryEntry.new()
	entry.resident_id = resident_id
	entry.history_type = ResidentHistoryEntry.FIRST_MEETING
	entry.source_event_id = source_id
	entry.created_at = TimeManager.get_now() if at <= 0.0 else at
	entry.location_id = location_id
	entry.history_id = "resident_first_meeting_%s_%d" % [resident_id, int(round(entry.created_at * 1000.0))]
	resident_first_meeting_history.append(entry.to_dict())
	history_changed.emit()
	return entry

func record_interaction(result: ResidentInteractionResult, interaction_type: String, at := -1.0, location_id := "") -> ResidentInteractionHistoryEntry:
	if result == null or not result.success or result.interaction_id.is_empty() or result.resident_id.is_empty():
		return null
	var existing := get_interaction(result.interaction_id)
	if existing != null:
		return existing
	var entry := ResidentInteractionHistoryEntry.new()
	entry.interaction_id = result.interaction_id
	entry.resident_id = result.resident_id
	entry.interaction_type = interaction_type
	entry.relationship_change = result.relationship_change
	entry.social_experience_change = result.social_experience_change
	entry.relationship_state = result.relationship_state
	entry.reaction_tag = result.reaction_tag
	entry.interacted_at = TimeManager.get_now() if at <= 0.0 else at
	resident_interaction_history.append(entry.to_dict())
	record_first_meeting(entry.resident_id, entry.interaction_id, entry.interacted_at, location_id)
	history_changed.emit()
	return entry

func record_relationship_change(resident: ResidentData, source_id: String, at := -1.0) -> ResidentRelationshipHistoryEntry:
	if resident == null or resident.resident_id.is_empty():
		return null
	var runtime_raw := _runtime_relationship_change(resident, source_id)
	var new_state := str(runtime_raw.get("new_state", resident.relationship.state))
	var old_state := str(runtime_raw.get("old_state", _previous_relationship_state(resident.resident_id)))
	var changed_at := float(runtime_raw.get("changed_at", TimeManager.get_now() if at <= 0.0 else at))
	var history_id := _relationship_history_id(resident.resident_id, source_id, new_state)
	var existing := get_relationship_history(history_id)
	if existing != null:
		return existing
	var entry := ResidentRelationshipHistoryEntry.new()
	entry.relationship_history_id = history_id
	entry.resident_id = resident.resident_id
	entry.source_id = source_id
	entry.old_state = old_state
	entry.new_state = new_state
	entry.stage_changed_at = changed_at
	resident_relationship_history.append(entry.to_dict())
	sync_resident_state(resident)
	history_changed.emit()
	return entry

func record_shared_activity(result: SharedActivityResult, location_id := "", at := -1.0) -> SharedActivityHistoryEntry:
	if result == null or not result.success or result.activity_record_id.is_empty() or result.participant_resident_id.is_empty():
		return null
	var existing := get_shared_activity(result.activity_record_id)
	if existing != null:
		return existing
	var entry := SharedActivityHistoryEntry.new()
	entry.activity_record_id = result.activity_record_id
	entry.activity_id = result.activity_id
	entry.resident_id = result.participant_resident_id
	entry.location_id = location_id
	entry.relationship_change = result.relationship_change
	entry.social_experience_change = result.social_experience_change
	entry.relationship_state = result.relationship_state
	entry.reaction_tag = result.reaction_tag
	entry.completed_at = TimeManager.get_now() if at <= 0.0 else at
	shared_activity_history.append(entry.to_dict())
	record_first_meeting(entry.resident_id, entry.activity_record_id, entry.completed_at, entry.location_id)
	history_changed.emit()
	return entry

func record_visit(resident_id: String, event_id: String, location_id := "home", at := -1.0) -> ResidentVisitHistoryEntry:
	if resident_id.is_empty() or event_id.is_empty() or _event_id_used(event_id):
		return get_visit(event_id)
	var entry := ResidentVisitHistoryEntry.new()
	entry.event_id = event_id
	entry.resident_id = resident_id
	entry.location_id = location_id
	entry.visited_at = TimeManager.get_now() if at <= 0.0 else at
	resident_visit_history.append(entry.to_dict())
	history_changed.emit()
	return entry

func record_gift(resident_id: String, event_id: String, item_id: String, amount: int, at := -1.0) -> ResidentGiftHistoryEntry:
	if resident_id.is_empty() or event_id.is_empty() or item_id.is_empty() or amount <= 0 or _event_id_used(event_id):
		return get_gift(event_id)
	var entry := ResidentGiftHistoryEntry.new()
	entry.event_id = event_id
	entry.resident_id = resident_id
	entry.item_id = item_id
	entry.amount = amount
	entry.received_at = TimeManager.get_now() if at <= 0.0 else at
	resident_gift_history.append(entry.to_dict())
	history_changed.emit()
	return entry

func record_letter(resident_id: String, event_id: String, reaction_tag := "", at := -1.0) -> ResidentLetterHistoryEntry:
	if resident_id.is_empty() or event_id.is_empty() or _event_id_used(event_id):
		return get_letter(event_id)
	var entry := ResidentLetterHistoryEntry.new()
	entry.event_id = event_id
	entry.resident_id = resident_id
	entry.reaction_tag = reaction_tag
	entry.received_at = TimeManager.get_now() if at <= 0.0 else at
	resident_letter_history.append(entry.to_dict())
	history_changed.emit()
	return entry

func record_invitation(resident_id: String, invitation: Dictionary, at := -1.0) -> ResidentInvitationHistoryEntry:
	var invitation_id := str(invitation.get("invitation_id", ""))
	if resident_id.is_empty() or invitation_id.is_empty():
		return null
	var existing := get_invitation(invitation_id)
	if existing != null:
		var old_state := existing.state
		existing.state = str(invitation.get("state", existing.state))
		if existing.state != "pending" and existing.responded_at <= 0.0:
			existing.responded_at = TimeManager.get_now() if at <= 0.0 else at
		_replace_invitation(existing)
		if old_state != existing.state:
			history_changed.emit()
		return existing
	var entry := ResidentInvitationHistoryEntry.new()
	entry.invitation_id = invitation_id
	entry.resident_id = resident_id
	entry.activity_id = str(invitation.get("activity_id", ""))
	entry.state = str(invitation.get("state", "pending"))
	entry.created_at = TimeManager.get_now() if at <= 0.0 else at
	if entry.state != "pending":
		entry.responded_at = entry.created_at
	resident_invitation_history.append(entry.to_dict())
	history_changed.emit()
	return entry

func record_social_experience(resident_id: String, source_type: String, source_id: String, amount: int, at := -1.0) -> ResidentSocialExperienceHistoryEntry:
	if resident_id.is_empty() or source_id.is_empty() or amount <= 0:
		return null
	var existing := get_social_experience(source_id)
	if existing != null:
		return existing
	var entry := ResidentSocialExperienceHistoryEntry.new()
	entry.resident_id = resident_id
	entry.source_type = source_type
	entry.source_id = source_id
	entry.amount = amount
	entry.created_at = TimeManager.get_now() if at <= 0.0 else at
	resident_social_experience_history.append(entry.to_dict())
	history_changed.emit()
	return entry

func get_arrival(resident_id: String) -> ResidentHistoryEntry:
	for raw: Dictionary in resident_arrival_history:
		if str(raw.get("resident_id", "")) == resident_id:
			return ResidentHistoryEntry.from_dict(raw)
	return null

func get_first_meeting(resident_id: String) -> ResidentHistoryEntry:
	for raw: Dictionary in resident_first_meeting_history:
		if str(raw.get("resident_id", "")) == resident_id:
			return ResidentHistoryEntry.from_dict(raw)
	return null

func get_interaction(interaction_id: String) -> ResidentInteractionHistoryEntry:
	for raw: Dictionary in resident_interaction_history:
		if str(raw.get("interaction_id", "")) == interaction_id:
			return ResidentInteractionHistoryEntry.from_dict(raw)
	return null

func get_relationship_history(history_id: String) -> ResidentRelationshipHistoryEntry:
	for raw: Dictionary in resident_relationship_history:
		if str(raw.get("relationship_history_id", "")) == history_id:
			return ResidentRelationshipHistoryEntry.from_dict(raw)
	return null

func get_shared_activity(record_id: String) -> SharedActivityHistoryEntry:
	for raw: Dictionary in shared_activity_history:
		if str(raw.get("activity_record_id", "")) == record_id:
			return SharedActivityHistoryEntry.from_dict(raw)
	return null

func get_visit(event_id: String) -> ResidentVisitHistoryEntry:
	for raw: Dictionary in resident_visit_history:
		if str(raw.get("event_id", "")) == event_id:
			return ResidentVisitHistoryEntry.from_dict(raw)
	return null

func get_gift(event_id: String) -> ResidentGiftHistoryEntry:
	for raw: Dictionary in resident_gift_history:
		if str(raw.get("event_id", "")) == event_id:
			return ResidentGiftHistoryEntry.from_dict(raw)
	return null

func get_letter(event_id: String) -> ResidentLetterHistoryEntry:
	for raw: Dictionary in resident_letter_history:
		if str(raw.get("event_id", "")) == event_id:
			return ResidentLetterHistoryEntry.from_dict(raw)
	return null

func get_invitation(invitation_id: String) -> ResidentInvitationHistoryEntry:
	for raw: Dictionary in resident_invitation_history:
		if str(raw.get("invitation_id", "")) == invitation_id:
			return ResidentInvitationHistoryEntry.from_dict(raw)
	return null

func get_social_experience(source_id: String) -> ResidentSocialExperienceHistoryEntry:
	for raw: Dictionary in resident_social_experience_history:
		if str(raw.get("source_id", "")) == source_id:
			return ResidentSocialExperienceHistoryEntry.from_dict(raw)
	return null

func get_first_friend_id() -> String:
	var best_id := ""
	var best_at := 0.0
	for raw: Dictionary in resident_relationship_history:
		var entry := ResidentRelationshipHistoryEntry.from_dict(raw)
		if entry.new_state != ResidentRelationshipData.FRIEND:
			continue
		if best_id.is_empty() or _earlier(entry.stage_changed_at, best_at):
			best_id = entry.resident_id
			best_at = entry.stage_changed_at
	return best_id

func get_friend_ids() -> Array[String]:
	var latest: Dictionary = {}
	for raw: Dictionary in resident_relationship_history:
		var entry := ResidentRelationshipHistoryEntry.from_dict(raw)
		var previous: Dictionary = latest.get(entry.resident_id, {}) if latest.get(entry.resident_id, {}) is Dictionary else {}
		if previous.is_empty() or float(previous.get("at", 0.0)) <= entry.stage_changed_at:
			latest[entry.resident_id] = {"state": entry.new_state, "at": entry.stage_changed_at}
	var result: Array[String] = []
	for resident_id: String in latest:
		if str((latest[resident_id] as Dictionary).get("state", "")) == ResidentRelationshipData.FRIEND:
			result.append(resident_id)
	result.sort()
	return result

func get_relationship_state(resident_id: String) -> String:
	var latest := _latest_relationship_entry(resident_id)
	if latest != null:
		return latest.new_state
	var raw: Variant = resident_states.get(resident_id, {})
	if raw is Dictionary:
		var resident := ResidentData.from_dict(raw)
		return resident.relationship.state
	return ResidentRelationshipData.STRANGER

func _import_runtime_relationship_history(resident: ResidentData, fallback_at: float) -> void:
	for raw: Dictionary in resident.relationship_history:
		var source_id := str(raw.get("source_id", ""))
		var new_state := str(raw.get("new_state", resident.relationship.state))
		var history_id := _relationship_history_id(resident.resident_id, source_id, new_state)
		if get_relationship_history(history_id) != null:
			continue
		var entry := ResidentRelationshipHistoryEntry.new()
		entry.relationship_history_id = history_id
		entry.resident_id = resident.resident_id
		entry.source_id = source_id
		entry.old_state = str(raw.get("old_state", ResidentRelationshipData.STRANGER))
		entry.new_state = new_state
		entry.stage_changed_at = maxf(0.0, float(raw.get("changed_at", fallback_at)))
		resident_relationship_history.append(entry.to_dict())

func _import_runtime_social_history(resident: ResidentData, fallback_at: float) -> void:
	for raw: Dictionary in resident.social_experience_history:
		var source_id := str(raw.get("source_id", ""))
		if source_id.is_empty() or get_social_experience(source_id) != null:
			continue
		var entry := ResidentSocialExperienceHistoryEntry.new()
		entry.resident_id = resident.resident_id
		entry.source_type = str(raw.get("source_type", ""))
		entry.source_id = source_id
		entry.amount = maxi(0, int(raw.get("amount", 0)))
		entry.created_at = maxf(0.0, float(raw.get("created_at", fallback_at)))
		if entry.amount > 0:
			resident_social_experience_history.append(entry.to_dict())

func _repair_first_meeting(resident: ResidentData, fallback_at: float) -> void:
	if get_first_meeting(resident.resident_id) != null:
		return
	if resident.relationship.interaction_count <= 0 and resident.relationship.shared_activity_count <= 0:
		return
	var source_id := ""
	var source_at := 0.0
	for raw: Dictionary in resident_social_experience_history:
		if str(raw.get("resident_id", "")) != resident.resident_id:
			continue
		var source_type := str(raw.get("source_type", ""))
		if source_type not in ["interaction", "shared_activity"]:
			continue
		var candidate_at := float(raw.get("created_at", 0.0))
		if source_id.is_empty() or _earlier(candidate_at, source_at):
			source_id = str(raw.get("source_id", ""))
			source_at = candidate_at
	if source_id.is_empty():
		source_id = "week9_first_meeting_repair_%s" % resident.resident_id
		source_at = fallback_at
	record_first_meeting(resident.resident_id, source_id, source_at, resident.state.current_location)

func _repair_runtime_guards(resident: ResidentData) -> void:
	for raw: Dictionary in resident_interaction_history:
		if str(raw.get("resident_id", "")) == resident.resident_id:
			var source_id := str(raw.get("interaction_id", ""))
			if not source_id.is_empty() and not resident.relationship.applied_source_ids.has(source_id):
				resident.relationship.applied_source_ids.append(source_id)
	for raw: Dictionary in shared_activity_history:
		if str(raw.get("resident_id", "")) == resident.resident_id:
			var source_id := str(raw.get("activity_record_id", ""))
			if not source_id.is_empty() and not resident.relationship.applied_source_ids.has(source_id):
				resident.relationship.applied_source_ids.append(source_id)
	for collection: Array in [resident_visit_history, resident_gift_history, resident_letter_history]:
		for raw: Dictionary in collection:
			if str(raw.get("resident_id", "")) != resident.resident_id:
				continue
			var event_id := str(raw.get("event_id", ""))
			if not event_id.is_empty() and not resident.completed_event_ids.has(event_id):
				resident.completed_event_ids.append(event_id)

func _repair_relationship_state(resident: ResidentData, fallback_at: float) -> void:
	var latest := _latest_relationship_entry(resident.resident_id)
	if latest == null:
		if resident.relationship.state == ResidentRelationshipData.STRANGER:
			return
		_append_relationship_repair(resident.resident_id, ResidentRelationshipData.STRANGER, resident.relationship.state, fallback_at)
		return
	if resident.relationship.state == latest.new_state:
		return
	# History is authoritative for resume/UI, but do not roll back a newer legitimate
	# runtime stage merely because an older C history entry is missing. In that case
	# append the missing transition. If runtime is behind history, repair runtime.
	if _relationship_rank(resident.relationship.state) > _relationship_rank(latest.new_state):
		_append_relationship_repair(resident.resident_id, latest.new_state, resident.relationship.state, fallback_at)
	else:
		resident.relationship.state = latest.new_state

func _append_relationship_repair(resident_id: String, old_state: String, new_state: String, at: float) -> void:
	var entry := ResidentRelationshipHistoryEntry.new()
	entry.resident_id = resident_id
	entry.source_id = "week9_relationship_repair_%s_%s" % [resident_id, new_state]
	entry.old_state = old_state
	entry.new_state = new_state
	entry.stage_changed_at = at if at > 0.0 else TimeManager.get_now()
	entry.relationship_history_id = _relationship_history_id(entry.resident_id, entry.source_id, entry.new_state)
	if get_relationship_history(entry.relationship_history_id) == null:
		resident_relationship_history.append(entry.to_dict())
		history_changed.emit()

func _relationship_rank(state: String) -> int:
	match state:
		ResidentRelationshipData.ACQUAINTANCE:
			return 1
		ResidentRelationshipData.FRIEND:
			return 2
	return 0

func _latest_relationship_entry(resident_id: String) -> ResidentRelationshipHistoryEntry:
	var best: ResidentRelationshipHistoryEntry = null
	for raw: Dictionary in resident_relationship_history:
		var entry := ResidentRelationshipHistoryEntry.from_dict(raw)
		if entry.resident_id != resident_id:
			continue
		if best == null or best.stage_changed_at <= entry.stage_changed_at:
			best = entry
	return best

func _runtime_relationship_change(resident: ResidentData, source_id: String) -> Dictionary:
	for index: int in range(resident.relationship_history.size() - 1, -1, -1):
		var raw: Dictionary = resident.relationship_history[index]
		if source_id.is_empty() or str(raw.get("source_id", "")) == source_id:
			return raw.duplicate(true)
	return {}

func _previous_relationship_state(resident_id: String) -> String:
	var latest := _latest_relationship_entry(resident_id)
	return latest.new_state if latest != null else ResidentRelationshipData.STRANGER

func _relationship_history_id(resident_id: String, source_id: String, new_state: String) -> String:
	return "relationship_%s_%s_%s" % [resident_id, source_id if not source_id.is_empty() else "repair", new_state]

func _arrival_source_for(resident: ResidentData) -> String:
	if resident.resident_id == ResidentManager.CAFE_OWNER:
		return "cafe_barista_arrives_001"
	return "resident_arrival_%s" % resident.resident_id

func _replace_invitation(entry: ResidentInvitationHistoryEntry) -> void:
	for index: int in range(resident_invitation_history.size()):
		if str(resident_invitation_history[index].get("invitation_id", "")) == entry.invitation_id:
			resident_invitation_history[index] = entry.to_dict()
			return

func _event_id_used(event_id: String) -> bool:
	if event_id.is_empty():
		return false
	for collection: Array in [resident_visit_history, resident_gift_history, resident_letter_history]:
		for raw: Dictionary in collection:
			if str(raw.get("event_id", "")) == event_id:
				return true
	return false

func _repair_event_id_uniqueness() -> void:
	var seen := {}
	resident_visit_history = _clean_global_events(resident_visit_history, seen)
	resident_gift_history = _clean_global_events(resident_gift_history, seen)
	resident_letter_history = _clean_global_events(resident_letter_history, seen)

func _clean_global_events(source: Array[Dictionary], seen: Dictionary) -> Array[Dictionary]:
	var cleaned: Array[Dictionary] = []
	for raw: Dictionary in source:
		var event_id := str(raw.get("event_id", ""))
		if event_id.is_empty() or seen.has(event_id):
			continue
		seen[event_id] = true
		cleaned.append(raw.duplicate(true))
	return cleaned

func _dedup_history(source: Array[Dictionary], key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	for raw: Dictionary in source:
		var id := str(raw.get(key, ""))
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		result.append(raw.duplicate(true))
	return result

func _earlier(candidate: float, current: float) -> bool:
	if current <= 0.0:
		return candidate > 0.0
	if candidate <= 0.0:
		return false
	return candidate < current
