class_name RabbitLifeHistoryManager
extends Node

signal history_changed

var rabbit_life_milestones: Array[Dictionary] = []
var rabbit_life_profile: Dictionary = {}

func setup_from_save(save: SaveData) -> void:
	rabbit_life_milestones = _sanitize_milestones(save.rabbit_life_milestones)
	rabbit_life_profile = save.rabbit_life_profile.duplicate(true)

func rebuild_from_reliable_history(save: SaveData, rabbit: RabbitData, growth_history: GrowthHistoryManager) -> void:
	if save == null or rabbit == null:
		return
	# Do not backfill Move In from RabbitData.move_in_date here.
	# B initializes that field to today's date when an old save has no date, so using it
	# during migration would invent a historical milestone. Fresh saves record Move In
	# explicitly through record_move_in() with a real timestamp.

	var first_activity := _earliest_record(save.all_activity_records, ["completed_at", "started_at"])
	if not first_activity.is_empty():
		_ensure_milestone("first_activity", _record_time(first_activity, ["completed_at", "started_at"]), "activity", str(first_activity.get("activity_record_id", "")))
	var first_forest := _earliest_filtered(save.all_activity_records, func(raw: Dictionary) -> bool: return str(raw.get("location_id", "")) == "forest", ["completed_at", "started_at"])
	if not first_forest.is_empty():
		_ensure_milestone("first_forest", _record_time(first_forest, ["completed_at", "started_at"]), "activity", str(first_forest.get("activity_record_id", "")))
	var first_fishing := _earliest_filtered(save.all_activity_records, func(raw: Dictionary) -> bool: return str(raw.get("activity_id", "")) == "fishing", ["completed_at", "started_at"])
	if not first_fishing.is_empty():
		_ensure_milestone("first_fishing", _record_time(first_fishing, ["completed_at", "started_at"]), "activity", str(first_fishing.get("activity_record_id", "")))

	var first_journal := _earliest_record(save.journals, ["created_at"])
	if not first_journal.is_empty():
		_ensure_milestone("first_journal", float(first_journal.get("created_at", 0.0)), "journal", str(first_journal.get("journal_id", "")))
	var first_food := _earliest_record(save.food_use_history, ["used_at"])
	if not first_food.is_empty():
		_ensure_milestone("first_food", float(first_food.get("used_at", 0.0)), "food", str(first_food.get("food_use_record_id", "")))
	var first_purchase := _earliest_record(save.purchase_history, ["purchased_at"])
	if not first_purchase.is_empty():
		_ensure_milestone("first_purchase", float(first_purchase.get("purchased_at", 0.0)), "purchase", str(first_purchase.get("purchase_record_id", "")))
	var first_cooking := _earliest_record(save.cooking_history, ["cooked_at"])
	if not first_cooking.is_empty():
		_ensure_milestone("first_cooking", float(first_cooking.get("cooked_at", 0.0)), "cooking", str(first_cooking.get("cooking_record_id", "")))

	var growth_fact := _first_growth_fact(save)
	if not growth_fact.is_empty():
		_ensure_milestone("first_growth_mark", float(growth_fact.get("at", 0.0)), "growth", str(growth_fact.get("source_id", "")))
	var first_building := _first_completed_building(save)
	if not first_building.is_empty():
		_ensure_milestone("first_building", float(first_building.get("at", 0.0)), "building", str(first_building.get("source_id", "")))
	if not save.building_unlock_history.is_empty():
		var first_unlock := _earliest_filtered(save.building_unlock_history, func(raw: Dictionary) -> bool: return str(raw.get("building_id", "")) == "cafe", ["unlocked_at"])
		if not first_unlock.is_empty():
			_ensure_milestone("cafe_unlock", float(first_unlock.get("unlocked_at", 0.0)), "building_unlock", str(first_unlock.get("source_event_id", "")))
	var cafe_complete := _first_completed_cafe(save.construction_history)
	if not cafe_complete.is_empty():
		_ensure_milestone("cafe_complete", float(cafe_complete.get("completed_at", 0.0)), "construction", str(cafe_complete.get("construction_record_id", cafe_complete.get("construction_id", ""))))
	if growth_history != null:
		var final_entry := growth_history.get_completed_final_growth()
		if final_entry != null:
			_ensure_milestone("final_growth", final_entry.completed_at, "final_growth", final_entry.final_growth_record_id)

func update_profile(save: SaveData, rabbit: RabbitData, growth_manager: GrowthManager, growth_history: GrowthHistoryManager, at: float = -1.0) -> RabbitLifeProfileSnapshot:
	if save == null or rabbit == null:
		return null
	rebuild_from_reliable_history(save, rabbit, growth_history)
	var profile := RabbitLifeProfileSnapshot.new()
	profile.snapshot_id = "rabbit_life_profile_current"
	profile.created_at = TimeManager.get_now() if at <= 0.0 else at
	profile.rabbit_name = rabbit.rabbit_name
	# Resume must only show a Move In date backed by a reliable milestone.
	# Older saves may have RabbitData.move_in_date defaulted to today by B, which is not historical evidence.
	profile.move_in_date = _milestone_display_before("move_in", profile.created_at)
	profile.first_activity = _milestone_display_before("first_activity", profile.created_at)
	profile.first_journal = _milestone_display_before("first_journal", profile.created_at)
	profile.first_forest = _milestone_display_before("first_forest", profile.created_at)
	profile.first_fishing = _milestone_display_before("first_fishing", profile.created_at)
	profile.first_food = _milestone_display_before("first_food", profile.created_at)
	profile.first_purchase = _milestone_display_before("first_purchase", profile.created_at)
	profile.first_cooking = _milestone_display_before("first_cooking", profile.created_at)
	profile.first_growth = _milestone_display_before("first_growth_mark", profile.created_at)
	profile.first_building = _milestone_display_before("first_building", profile.created_at)
	profile.cafe_unlock = _milestone_display_before("cafe_unlock", profile.created_at)
	profile.cafe_complete = _milestone_display_before("cafe_complete", profile.created_at)
	profile.final_growth = _milestone_display_before("final_growth", profile.created_at)
	profile.first_friend = _first_friend_from_history(save.resident_relationship_history, profile.created_at)
	profile.friend_list = _friend_list_from_history(save.resident_relationship_history, profile.created_at)
	profile.favorite_location = _favorite_key(save.all_activity_records, "location_id", profile.created_at)
	profile.favorite_food = _favorite_key(save.food_use_history, "food_id", profile.created_at)
	profile.most_used_activity = _favorite_key(save.all_activity_records, "activity_id", profile.created_at)
	profile.current_form = growth_manager.get_current_final_form() if growth_manager != null else rabbit.current_final_form
	profile.dominant_tendency = growth_manager.get_dominant_tendency() if growth_manager != null else "balanced"
	profile.important_memories = collect_important_memories(save, 16, profile.created_at)
	rabbit_life_profile = profile.to_dict()
	history_changed.emit()
	return profile

func create_frozen_profile_snapshot(snapshot_id: String, save: SaveData, rabbit: RabbitData, growth_manager: GrowthManager, growth_history: GrowthHistoryManager, at: float) -> RabbitLifeProfileSnapshot:
	var previous_profile := rabbit_life_profile.duplicate(true)
	var current := update_profile(save, rabbit, growth_manager, growth_history, at)
	if current == null:
		return null
	var frozen := RabbitLifeProfileSnapshot.from_dict(current.to_dict())
	frozen.snapshot_id = snapshot_id
	frozen.created_at = maxf(0.0, at)
	# Building a replay snapshot must not roll the current resume back to an old Ending date.
	if not previous_profile.is_empty():
		rabbit_life_profile = previous_profile
	return frozen

func collect_important_memories(save: SaveData, limit := 16, cutoff_at := 0.0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	for raw: Dictionary in save.journals:
		if not bool(raw.get("is_special_memory", false)):
			continue
		var journal_at := maxf(0.0, float(raw.get("created_at", 0.0)))
		if cutoff_at > 0.0 and journal_at > cutoff_at:
			continue
		_append_memory(result, seen, "journal", str(raw.get("journal_id", "")), str(raw.get("title", "")), journal_at)
	for raw: Dictionary in save.growth_album_entries:
		var album_at := maxf(0.0, float(raw.get("unlocked_at", 0.0)))
		if cutoff_at > 0.0 and album_at > cutoff_at:
			continue
		_append_memory(result, seen, "growth_album", str(raw.get("id", "")), str(raw.get("title", "")), album_at)
	for raw: Dictionary in save.life_event_history:
		var id := str(raw.get("life_event_id", ""))
		var event_at := maxf(0.0, float(raw.get("confirmed_at", raw.get("completed_at", raw.get("created_at", 0.0)))))
		if cutoff_at > 0.0 and event_at > cutoff_at:
			continue
		_append_memory(result, seen, "life_event", id, id, event_at)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var at_a := float(a.get("at", 0.0)); var at_b := float(b.get("at", 0.0))
		if at_a <= 0.0 and at_b > 0.0: return false
		if at_b <= 0.0 and at_a > 0.0: return true
		return at_a < at_b
	)
	while result.size() > limit:
		result.pop_back()
	return result

func record_move_in(at: float, rabbit_name: String, occurred_date := "") -> RabbitLifeMilestoneEntry:
	if at <= 0.0:
		return null
	return _ensure_milestone("move_in", at, "rabbit", rabbit_name, occurred_date)

func get_runtime_summary() -> Dictionary:
	if rabbit_life_profile.is_empty():
		return {}
	return {
		"favorite_location": str(rabbit_life_profile.get("favorite_location", "")),
		"favorite_food": str(rabbit_life_profile.get("favorite_food", "")),
		"most_used_activity": str(rabbit_life_profile.get("most_used_activity", "")),
		"first_growth_mark": str(rabbit_life_profile.get("first_growth", rabbit_life_profile.get("first_growth_mark", ""))),
		"first_building": str(rabbit_life_profile.get("first_building", "")),
		"first_friend": str(rabbit_life_profile.get("first_friend", "")),
		"friend_list": rabbit_life_profile.get("friend_list", []).duplicate() if rabbit_life_profile.get("friend_list", []) is Array else [],
		"first_forest": str(rabbit_life_profile.get("first_forest", "")),
		"first_fishing": str(rabbit_life_profile.get("first_fishing", "")),
		"important_memories": _memory_titles(rabbit_life_profile.get("important_memories", []))
	}

func _first_friend_from_history(history: Array[Dictionary], cutoff_at: float) -> String:
	var resident_id := ""
	var best_at := 0.0
	for raw: Dictionary in history:
		var entry := ResidentRelationshipHistoryEntry.from_dict(raw)
		if entry.new_state != ResidentRelationshipData.FRIEND:
			continue
		if cutoff_at > 0.0 and entry.stage_changed_at > cutoff_at:
			continue
		if resident_id.is_empty() or _time_is_earlier(entry.stage_changed_at, best_at):
			resident_id = entry.resident_id
			best_at = entry.stage_changed_at
	return resident_id

func _friend_list_from_history(history: Array[Dictionary], cutoff_at: float) -> Array[String]:
	var latest: Dictionary = {}
	for raw: Dictionary in history:
		var entry := ResidentRelationshipHistoryEntry.from_dict(raw)
		if cutoff_at > 0.0 and entry.stage_changed_at > cutoff_at:
			continue
		var current: Dictionary = latest.get(entry.resident_id, {}) if latest.get(entry.resident_id, {}) is Dictionary else {}
		if current.is_empty() or float(current.get("at", 0.0)) <= entry.stage_changed_at:
			latest[entry.resident_id] = {"state": entry.new_state, "at": entry.stage_changed_at}
	var result: Array[String] = []
	for resident_id: String in latest:
		if str((latest[resident_id] as Dictionary).get("state", "")) == ResidentRelationshipData.FRIEND:
			result.append(resident_id)
	result.sort()
	return result

func milestones_to_array() -> Array[Dictionary]:
	return rabbit_life_milestones.duplicate(true)

func get_milestone(milestone_id: String) -> RabbitLifeMilestoneEntry:
	for raw: Dictionary in rabbit_life_milestones:
		var entry := RabbitLifeMilestoneEntry.from_dict(raw)
		if entry.milestone_id == milestone_id:
			return entry
	return null

func _ensure_milestone(milestone_id: String, occurred_at: float, source_type: String, source_id: String, occurred_date := "") -> RabbitLifeMilestoneEntry:
	var existing := get_milestone(milestone_id)
	if existing != null:
		return existing
	# Never invent a date. A timestamp or a reliable date string is required.
	if occurred_at <= 0.0 and occurred_date.is_empty():
		return null
	var entry := RabbitLifeMilestoneEntry.new()
	entry.milestone_id = milestone_id
	entry.occurred_at = maxf(0.0, occurred_at)
	entry.occurred_date = occurred_date if not occurred_date.is_empty() else _format_date(occurred_at)
	entry.source_type = source_type
	entry.source_id = source_id
	rabbit_life_milestones.append(entry.to_dict())
	history_changed.emit()
	return entry

func _milestone_display(milestone_id: String) -> String:
	var entry := get_milestone(milestone_id)
	if entry == null:
		return ""
	if not entry.occurred_date.is_empty():
		return entry.occurred_date
	return _format_date(entry.occurred_at)

func _milestone_display_before(milestone_id: String, cutoff_at: float) -> String:
	var entry := get_milestone(milestone_id)
	if entry == null:
		return ""
	if cutoff_at > 0.0 and entry.occurred_at > 0.0 and entry.occurred_at > cutoff_at:
		return ""
	if not entry.occurred_date.is_empty():
		return entry.occurred_date
	return _format_date(entry.occurred_at)

func _earliest_record(source: Variant, time_keys: Array[String]) -> Dictionary:
	return _earliest_filtered(source, func(_raw: Dictionary) -> bool: return true, time_keys)

func _earliest_filtered(source: Variant, predicate: Callable, time_keys: Array[String]) -> Dictionary:
	var best: Dictionary = {}
	var best_at := 0.0
	if not (source is Array):
		return best
	for raw: Variant in source:
		if not (raw is Dictionary) or not predicate.call(raw):
			continue
		var at := _record_time(raw, time_keys)
		if at <= 0.0:
			continue
		if best.is_empty() or at < best_at:
			best = raw.duplicate(true)
			best_at = at
	return best

func _record_time(raw: Dictionary, time_keys: Array[String]) -> float:
	for key: String in time_keys:
		var value := maxf(0.0, float(raw.get(key, 0.0)))
		if value > 0.0:
			return value
	return 0.0

func _first_growth_fact(save: SaveData) -> Dictionary:
	var best := {}
	var best_at := 0.0
	for raw: Dictionary in save.unlocked_growth_marks:
		var at := maxf(0.0, float(raw.get("unlocked_at", 0.0)))
		if at > 0.0 and (best.is_empty() or at < best_at):
			best = {"at": at, "source_id": str(raw.get("id", ""))}; best_at = at
	for raw: Dictionary in save.growth_path_history:
		var at := maxf(0.0, float(raw.get("changed_at", 0.0)))
		if at > 0.0 and (best.is_empty() or at < best_at):
			best = {"at": at, "source_id": str(raw.get("source_event_id", ""))}; best_at = at
	return best

func _first_completed_building(save: SaveData) -> Dictionary:
	var village := VillageData.from_dict(save.village_data)
	var best := {}
	var best_at := 0.0
	for raw: Dictionary in village.building_history:
		var at := maxf(0.0, float(raw.get("completed_at", 0.0)))
		if at > 0.0 and (best.is_empty() or at < best_at):
			best = {"at": at, "source_id": str(raw.get("building_id", ""))}; best_at = at
	for raw: Dictionary in save.construction_history:
		if not bool(raw.get("is_completed", false)):
			continue
		var at := maxf(0.0, float(raw.get("completed_at", 0.0)))
		if at > 0.0 and (best.is_empty() or at < best_at):
			best = {"at": at, "source_id": str(raw.get("building_id", ""))}; best_at = at
	return best

func _first_completed_cafe(source: Variant) -> Dictionary:
	var best := {}
	var best_at := 0.0
	if not (source is Array):
		return best
	for raw: Variant in source:
		if not (raw is Dictionary) or str(raw.get("building_id", "")) != "cafe" or not bool(raw.get("is_completed", false)):
			continue
		var at := maxf(0.0, float(raw.get("completed_at", 0.0)))
		if at > 0.0 and (best.is_empty() or at < best_at):
			best = raw.duplicate(true); best_at = at
	return best

func _favorite_key(source: Variant, key: String, cutoff_at := 0.0) -> String:
	var counts := {}
	var first_at := {}
	if not (source is Array):
		return ""
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var id := str(raw.get(key, ""))
		if id.is_empty():
			continue
		var at := _record_time(raw, ["completed_at", "started_at", "used_at", "purchased_at", "cooked_at", "confirmed_at", "created_at"])
		if cutoff_at > 0.0 and at > cutoff_at:
			continue
		counts[id] = int(counts.get(id, 0)) + 1
		if not first_at.has(id) or (at > 0.0 and (float(first_at[id]) <= 0.0 or at < float(first_at[id]))):
			first_at[id] = at
	var best := ""
	for id: String in counts:
		if best.is_empty() or int(counts[id]) > int(counts[best]) or (int(counts[id]) == int(counts[best]) and float(first_at.get(id, 0.0)) < float(first_at.get(best, 0.0))):
			best = id
	return best

func _append_memory(result: Array[Dictionary], seen: Dictionary, source_type: String, source_id: String, title: String, at: float) -> void:
	if source_id.is_empty():
		return
	var key := "%s:%s" % [source_type, source_id]
	if seen.has(key):
		return
	seen[key] = true
	result.append({"source_type": source_type, "source_id": source_id, "title": title if not title.is_empty() else source_id, "at": maxf(0.0, at)})

func _memory_titles(source: Variant) -> Array[String]:
	var result: Array[String] = []
	if source is Array:
		for raw: Variant in source:
			if raw is Dictionary:
				var title := str(raw.get("title", raw.get("source_id", "")))
				if not title.is_empty(): result.append(title)
			else:
				result.append(str(raw))
	return result

func _sanitize_milestones(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array):
		return result
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := RabbitLifeMilestoneEntry.from_dict(raw)
		if entry.milestone_id.is_empty() or seen.has(entry.milestone_id):
			continue
		# Week8's first overlay could create a migrated Move In with occurred_at = 0
		# from B's fallback-to-today move_in_date. It is not reliable history, so drop it.
		if entry.milestone_id == "move_in" and entry.occurred_at <= 0.0 and entry.source_type == "rabbit":
			continue
		if entry.occurred_at <= 0.0 and entry.occurred_date.is_empty():
			continue
		seen[entry.milestone_id] = true
		result.append(entry.to_dict())
	return result

func _time_is_earlier(candidate: float, current: float) -> bool:
	if current <= 0.0:
		return candidate > 0.0
	if candidate <= 0.0:
		return false
	return candidate < current

func _format_date(timestamp: float) -> String:
	if timestamp <= 0.0:
		return ""
	var date := TimeManager.get_local_datetime(timestamp)
	return "%04d/%02d/%02d" % [date.year, date.month, date.day]
