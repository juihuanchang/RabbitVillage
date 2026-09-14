class_name ResidentManager
extends Node

signal resident_arrived(resident: ResidentData)
signal relationship_stage_changed(result: ResidentInteractionResult)
signal resident_event_created(event_id: String, resident_id: String)
signal resident_progress_changed(resident: ResidentData)
signal resident_location_changed(resident_id: String, location_id: String, changed_at: float)
signal resident_interaction_completed(result: ResidentInteractionResult, interaction_type: String, completed_at: float)
signal shared_activity_completed(result: SharedActivityResult, location_id: String, completed_at: float)
signal resident_visit_completed(event_id: String, resident_id: String, location_id: String, completed_at: float)
signal resident_gift_received(event_id: String, resident_id: String, item_id: String, amount: int, completed_at: float)
signal resident_letter_received(event_id: String, resident_id: String, reaction_tag: String, completed_at: float)
signal resident_invitation_changed(resident_id: String, invitation: Dictionary, changed_at: float)

const CAFE_OWNER := "cafe_owner"
const VALID_RESIDENT_IDS := [CAFE_OWNER]
const VALID_LOCATIONS := ["home", "forest", "lake", "lakeside", "cafe", "picnic"]
const DAILY_INTERACTION_LIMIT := 3
const HOME_VISIT_COOLDOWN_SECONDS := 172800.0

var _rabbit: RabbitData
var _buildings: BuildingManager
var _growth: GrowthManager
var _inventory: InventoryManager
var _residents: Dictionary = {}

func setup(rabbit: RabbitData, buildings: BuildingManager, growth: GrowthManager = null, inventory: InventoryManager = null) -> void:
	_rabbit = rabbit; _buildings = buildings; _growth = growth; _inventory = inventory; _residents.clear()
	var saved: Dictionary = rabbit.resident_runtime if rabbit != null else {}
	var source: Dictionary = saved.get("residents", {}) if saved.get("residents", {}) is Dictionary else {}
	if source.has(CAFE_OWNER) and source[CAFE_OWNER] is Dictionary: _residents[CAFE_OWNER] = ResidentData.from_dict(source[CAFE_OWNER])
	else: _residents[CAFE_OWNER] = _new_cafe_owner()
	_repair_cafe_owner_migration(); _sanitize(); _commit()
func _new_cafe_owner() -> ResidentData:
	var resident := ResidentData.new(); resident.resident_id = CAFE_OWNER; resident.display_name = "Café Owner"; resident.relationship.resident_id = CAFE_OWNER; return resident
func _repair_cafe_owner_migration() -> void:
	var resident := get_resident(CAFE_OWNER)
	if resident == null or _buildings == null: return
	if resident.state.state == ResidentStateData.LOCKED and _buildings.is_building_completed("coffee_shop"):
		resident.state.state = ResidentStateData.RESIDENT; resident.state.arrived_at = _building_completion_time(); resident.state.current_location = "cafe"
func _building_completion_time() -> float:
	var raw: Dictionary = _buildings.data.building_records.get("coffee_shop", {}) if _buildings != null and _buildings.data != null else {}
	var completed_at := float(raw.get("completed_at", 0.0)); return completed_at if completed_at > 0.0 else TimeManager.get_now()
func _sanitize() -> void:
	for id: String in _residents.keys():
		if not VALID_RESIDENT_IDS.has(id): _residents.erase(id); continue
		var resident := _residents[id] as ResidentData
		if not VALID_LOCATIONS.has(resident.state.current_location): resident.state.current_location = "cafe"
func _commit() -> void:
	if _rabbit == null: return
	var raw := {"residents": {}}
	for id: String in _residents: raw["residents"][id] = (_residents[id] as ResidentData).to_dict()
	_rabbit.resident_runtime = raw

func commit_runtime_state() -> void:
	_commit()

func restore_resident_states(states: Dictionary) -> void:
	# C-side permanent state can repair a missing/corrupt RabbitData.resident_runtime
	# without replaying rewards, relationship EXP, gifts, or events.
	for raw_id: Variant in states.keys():
		var resident_id := str(raw_id)
		if not VALID_RESIDENT_IDS.has(resident_id) or not (states[raw_id] is Dictionary):
			continue
		var restored := ResidentData.from_dict(states[raw_id])
		restored.resident_id = resident_id
		restored.relationship.resident_id = resident_id
		_residents[resident_id] = restored
	_sanitize()
	_commit()
func get_resident(resident_id: String) -> ResidentData: return _residents.get(resident_id) as ResidentData if VALID_RESIDENT_IDS.has(resident_id) else null
func get_all_residents() -> Array[ResidentData]:
	var result: Array[ResidentData] = []
	for resident: ResidentData in _residents.values():
		if resident.state.state != ResidentStateData.LOCKED: result.append(resident)
	return result
func get_resident_count() -> int:
	var count := 0
	for resident: ResidentData in _residents.values():
		if resident.state.state == ResidentStateData.RESIDENT: count += 1
	return count
func get_friend_count() -> int:
	var count := 0
	for resident: ResidentData in _residents.values():
		if resident.relationship.state == ResidentRelationshipData.FRIEND: count += 1
	return count
func has_resident_event(resident_id: String, event_id: String) -> bool:
	var resident := get_resident(resident_id); return resident != null and resident.completed_event_ids.has(event_id)
func get_relationship(resident_id: String) -> ResidentRelationshipData:
	var resident := get_resident(resident_id); return resident.relationship if resident != null else null
func get_social_experience_history(resident_id: String) -> Array[Dictionary]:
	var resident := get_resident(resident_id); return resident.social_experience_history.duplicate(true) if resident != null else []
func unlock_resident(resident_id: String, location := "cafe") -> bool:
	var resident := get_resident(resident_id)
	if resident == null or resident.state.state != ResidentStateData.LOCKED: return false
	resident.state.state = ResidentStateData.VISITOR; resident.state.arrived_at = TimeManager.get_now(); resident.state.current_location = location if VALID_LOCATIONS.has(location) else "cafe"; _commit(); resident_arrived.emit(resident); return true
func make_resident(resident_id: String) -> bool:
	var resident := get_resident(resident_id)
	if resident == null or resident.state.state == ResidentStateData.LOCKED: return false
	resident.state.state = ResidentStateData.RESIDENT; _commit(); return true
func set_resident_location(resident_id: String, location: String) -> bool:
	var resident := get_resident(resident_id)
	if resident == null or resident.state.state == ResidentStateData.LOCKED or not VALID_LOCATIONS.has(location): return false
	resident.state.current_location = location
	_commit()
	resident_location_changed.emit(resident_id, location, TimeManager.get_now())
	return true
func can_interact(resident_id: String, interaction_type: String) -> Dictionary:
	var resident := get_resident(resident_id)
	if resident == null or resident.state.state == ResidentStateData.LOCKED: return {"ok": false, "reason": "resident_unavailable"}
	var day := _day_key(); var count := int(resident.daily_interactions.get(day, 0))
	if count >= DAILY_INTERACTION_LIMIT: return {"ok": false, "reason": "daily_limit"}
	if interaction_type not in ["resident_talk", "cafe_chat"]: return {"ok": false, "reason": "invalid_interaction"}
	return {"ok": true, "reason": ""}
func can_start_shared_activity(resident_id: String, activity_id: String) -> Dictionary:
	var resident := get_resident(resident_id)
	if resident == null or resident.state.state == ResidentStateData.LOCKED: return {"ok": false, "reason": "resident_unavailable"}
	if activity_id in ["resident_talk", "cafe_chat"] and int(resident.daily_interactions.get(_day_key(), 0)) >= DAILY_INTERACTION_LIMIT: return {"ok": false, "reason": "daily_limit"}
	return {"ok": true, "reason": ""}
func interact(resident_id: String, interaction_type: String, interaction_id := "") -> ResidentInteractionResult:
	var result := ResidentInteractionResult.new(); result.resident_id = resident_id; result.interaction_id = interaction_id if not interaction_id.is_empty() else "interaction_%d_%d" % [int(TimeManager.get_now() * 1000000.0), randi_range(1000, 9999)]
	var check := can_interact(resident_id, interaction_type)
	if not check.ok: result.reason = check.reason; return result
	var resident := get_resident(resident_id)
	if resident.relationship.applied_source_ids.has(result.interaction_id): result.reason = "duplicate_source"; return result
	var day := _day_key(); resident.daily_interactions[day] = int(resident.daily_interactions.get(day, 0)) + 1
	result.relationship_change = 3 if interaction_type == "cafe_chat" else 2; result.social_experience_change = 2; result.mood_change = 2; result.intimacy_change = 1
	_apply_source(resident, "interaction", result.interaction_id, result.relationship_change, result.social_experience_change, result)
	_rabbit.mood += result.mood_change; _rabbit.intimacy += result.intimacy_change; result.success = true; result.reaction_tag = get_resident_reaction_tag(resident_id, interaction_type); _commit(); resident_interaction_completed.emit(result, interaction_type, TimeManager.get_now()); resident_progress_changed.emit(resident); return result
func apply_shared_activity(active: ActiveActivityData) -> SharedActivityResult:
	var result := SharedActivityResult.new()
	if active == null or active.activity == null: return result
	var resident_id := active.activity.participant_resident_id; var resident := get_resident(resident_id)
	if resident == null or resident.state.state == ResidentStateData.LOCKED or resident.relationship.applied_source_ids.has(active.activity_record_id): return result
	resident.state.current_location = "lakeside" if active.activity.location_id == "lake" else active.activity.location_id
	var relationship_change := 4; var social_change := 3
	if active.activity.activity_id in ["resident_talk", "cafe_chat"]:
		var day := _day_key(); resident.daily_interactions[day] = int(resident.daily_interactions.get(day, 0)) + 1
	if active.activity is SharedActivityData:
		var shared := active.activity as SharedActivityData; relationship_change = shared.relationship_change; social_change = shared.social_experience_change
	elif active.activity is CafeActivityData:
		social_change = (active.activity as CafeActivityData).social_experience_change
	result.activity_record_id = active.activity_record_id; result.activity_id = active.activity.activity_id; result.participant_resident_id = resident_id; result.relationship_change = relationship_change; result.social_experience_change = social_change; result.mood_change = maxi(0, active.activity.mood_change); result.intimacy_change = maxi(0, active.activity.intimacy_change)
	_apply_source(resident, "shared_activity", active.activity_record_id, relationship_change, social_change, null, active.activity is CafeActivityData)
	result.success = true; result.relationship_state = resident.relationship.state; result.reaction_tag = get_resident_reaction_tag(resident_id, active.activity.location_id); _commit(); shared_activity_completed.emit(result, resident.state.current_location, TimeManager.get_now()); resident_location_changed.emit(resident_id, resident.state.current_location, TimeManager.get_now()); resident_progress_changed.emit(resident); return result
func apply_event_relationship(resident_id: String, event_id: String, progress := 5, social_exp := 2) -> bool:
	var resident := get_resident(resident_id)
	if resident == null or event_id.is_empty() or resident.completed_event_ids.has(event_id): return false
	resident.completed_event_ids.append(event_id); resident.relationship.event_count += 1; _apply_source(resident, "event", event_id, progress, social_exp); _commit(); resident_progress_changed.emit(resident); return true
func _apply_source(resident: ResidentData, source_type: String, source_id: String, progress: int, social_exp: int, interaction_result: ResidentInteractionResult = null, social_already_applied := false) -> void:
	if resident.relationship.applied_source_ids.has(source_id): return
	var old_state := resident.relationship.state; resident.relationship.applied_source_ids.append(source_id); resident.relationship.progress += maxi(0, progress)
	if source_type == "interaction": resident.relationship.interaction_count += 1
	elif source_type == "shared_activity": resident.relationship.shared_activity_count += 1
	elif source_type == "gift": resident.relationship.gift_count += 1
	if social_exp > 0:
		if not social_already_applied: _rabbit.social_experience += social_exp
		resident.social_experience_history.append({"source_type": source_type, "source_id": source_id, "amount": social_exp, "created_at": TimeManager.get_now()})
	_update_relationship_state(resident)
	if interaction_result != null: interaction_result.relationship_state = resident.relationship.state
	if old_state != resident.relationship.state:
		var stage_result := ResidentInteractionResult.new(); stage_result.success = true; stage_result.resident_id = resident.resident_id; stage_result.interaction_id = source_id; stage_result.relationship_state = resident.relationship.state; resident.relationship_history.append({"source_id": source_id, "old_state": old_state, "new_state": resident.relationship.state, "changed_at": TimeManager.get_now()}); relationship_stage_changed.emit(stage_result)
func _update_relationship_state(resident: ResidentData) -> void:
	if resident.relationship.progress >= 40 and resident.relationship.interaction_count >= 5 and resident.relationship.shared_activity_count >= 3 and resident.relationship.event_count >= 1 and _rabbit.social_experience >= 15: resident.relationship.state = ResidentRelationshipData.FRIEND
	elif resident.relationship.progress >= 10 and resident.relationship.interaction_count >= 2: resident.relationship.state = ResidentRelationshipData.ACQUAINTANCE
func get_resident_reaction_tag(resident_id: String, context_id: String) -> String:
	if get_resident(resident_id) == null: return "resident_unknown"
	var branch: String = str(_growth.get_branch_reaction_context(context_id).get("branch", "balanced")) if _growth != null else "balanced"
	return "%s_%s_%s" % [resident_id, branch, context_id]
func can_trigger_home_visit(resident_id: String, now := -1.0) -> bool:
	var resident := get_resident(resident_id); var check_time := TimeManager.get_now() if now < 0.0 else now
	return resident != null and resident.relationship.state != ResidentRelationshipData.STRANGER and check_time - float(resident.daily_interactions.get("last_home_visit_at", 0.0)) >= HOME_VISIT_COOLDOWN_SECONDS
func trigger_home_visit(resident_id: String, event_id := "resident_first_visit_001", now := -1.0) -> bool:
	var check_time := TimeManager.get_now() if now < 0.0 else now
	if not can_trigger_home_visit(resident_id, check_time): return false
	var resident := get_resident(resident_id); resident.daily_interactions["last_home_visit_at"] = check_time; resident.state.current_location = "home"; apply_event_relationship(resident_id, event_id); resident_event_created.emit(event_id, resident_id); _commit(); resident_visit_completed.emit(event_id, resident_id, "home", check_time); resident_location_changed.emit(resident_id, "home", check_time); return true
func give_resident_gift(resident_id: String, event_id: String, item_id := "carrot", amount := 1) -> bool:
	var resident := get_resident(resident_id)
	if resident == null or resident.completed_event_ids.has(event_id) or _inventory == null or not _inventory.add_item(item_id, amount, "resident_gift", event_id): return false
	resident.completed_event_ids.append(event_id); _apply_source(resident, "gift", event_id, 4, 2); resident_event_created.emit(event_id, resident_id); _commit(); resident_gift_received.emit(event_id, resident_id, item_id, amount, TimeManager.get_now()); resident_progress_changed.emit(resident); return true
func receive_resident_gift(resident_id: String, event_id: String, item_id := "carrot", amount := 1) -> bool: return give_resident_gift(resident_id, event_id, item_id, amount)
func create_letter(resident_id: String, event_id: String) -> Dictionary:
	var resident := get_resident(resident_id)
	if resident == null or resident.completed_event_ids.has(event_id): return {}
	resident.completed_event_ids.append(event_id); resident_event_created.emit(event_id, resident_id); var reaction_tag := get_resident_reaction_tag(resident_id, "letter"); _commit(); resident_letter_received.emit(event_id, resident_id, reaction_tag, TimeManager.get_now()); return {"event_id": event_id, "resident_id": resident_id, "reaction_tag": reaction_tag}
func create_invitation(resident_id: String, activity_id: String, invitation_id: String) -> Dictionary:
	var resident := get_resident(resident_id)
	if resident == null or not resident.pending_invitation.is_empty(): return {}
	resident.pending_invitation = {"invitation_id": invitation_id, "activity_id": activity_id, "state": "pending"}; _commit(); resident_invitation_changed.emit(resident_id, resident.pending_invitation.duplicate(true), TimeManager.get_now()); return resident.pending_invitation.duplicate(true)
func respond_to_invitation(resident_id: String, invitation_id: String, accept: bool) -> Dictionary:
	var resident := get_resident(resident_id)
	if resident == null or str(resident.pending_invitation.get("invitation_id", "")) != invitation_id: return {"ok": false, "reason": "invalid_invitation"}
	var result := resident.pending_invitation.duplicate(true); result["state"] = "accepted" if accept else "declined"; resident.pending_invitation = {}; _commit(); resident_invitation_changed.emit(resident_id, result.duplicate(true), TimeManager.get_now()); return {"ok": true, "invitation": result}
func create_building_request(resident_id: String, building_id: String, request_id: String) -> Dictionary:
	var resident := get_resident(resident_id)
	if resident == null or resident.relationship.state == ResidentRelationshipData.STRANGER: return {}
	resident.building_request = {"request_id": request_id, "building_id": building_id, "state": "unlock_candidate"}; _commit(); return resident.building_request.duplicate(true)
func _day_key() -> String:
	var date := TimeManager.get_local_datetime(); return "%04d-%02d-%02d" % [date.year, date.month, date.day]
