class_name VillageDevelopmentHistoryManager
extends Node

signal history_changed

const CANONICAL_CAFE_ID := "cafe"
const RUNTIME_CAFE_ID := "coffee_shop"
const BUILDING_SLOTS := [
	"building_slot_01",
	"building_slot_02",
	"building_slot_03",
	"building_slot_04",
	"building_slot_05"
]
const RESERVED_BUILDING_IDS := ["cafe", "library", "flower_shop", "workshop"]
const BUILDABLE_BUILDING_IDS := ["cafe"]
const VALID_APPEARANCE_STATES := ["normal", "leaf", "sprout", "forest_stage3", "lakeside_stage2", "forest_final", "lakeside_final"]

var building_slots: Dictionary = {}
var unlocked_building_ids: Array[String] = []
var buildable_building_ids: Array[String] = ["cafe"]
var active_constructions: Array[Dictionary] = []
var building_unlock_history: Array[Dictionary] = []
var building_placement_history: Array[Dictionary] = []
var construction_history: Array[Dictionary] = []
var cafe_experience := 0
var cafe_activity_history: Array[Dictionary] = []
var cafe_experience_history: Array[Dictionary] = []
var village_progress_state: Dictionary = {}
var village_progress_history: Array[Dictionary] = []
var growth_appearance_state := "normal"
var growth_appearance_history: Array[Dictionary] = []

func _init() -> void:
	_reset_slots()

func setup_from_save(save: SaveData) -> void:
	_reset_slots()
	building_slots = _sanitize_slots(save.building_slots)
	unlocked_building_ids = _sanitize_unlocked(save.unlocked_building_ids)
	buildable_building_ids = ["cafe"]
	active_constructions = _sanitize_active_constructions(save.active_constructions)
	building_unlock_history = _sanitize_building_unlock_history(save.building_unlock_history)
	building_placement_history = _sanitize_building_placement_history(save.building_placement_history)
	construction_history = _sanitize_construction_history(save.construction_history)
	cafe_experience = maxi(0, save.cafe_experience)
	cafe_activity_history = _sanitize_cafe_activity_history(save.cafe_activity_history)
	cafe_experience_history = _sanitize_cafe_experience_history(save.cafe_experience_history)
	village_progress_state = save.village_progress_state.duplicate(true)
	village_progress_history = _sanitize_village_progress_history(save.village_progress_history)
	growth_appearance_state = _sanitize_appearance_state(save.growth_appearance_state)
	growth_appearance_history = _sanitize_appearance_history(save.growth_appearance_history)
	repair_consistency(TimeManager.get_now())

func record_building_unlock(building_id: String, unlocked_at: float, source_event_id: String) -> BuildingUnlockHistoryEntry:
	var canonical := canonical_building_id(building_id)
	if canonical != CANONICAL_CAFE_ID:
		return null
	for i in building_unlock_history.size():
		var existing := BuildingUnlockHistoryEntry.from_dict(building_unlock_history[i])
		if existing.building_id != canonical:
			continue
		if _time_is_earlier(unlocked_at, existing.unlocked_at):
			existing.unlocked_at = maxf(0.0, unlocked_at)
			existing.source_event_id = source_event_id
			building_unlock_history[i] = existing.to_dict()
		if not unlocked_building_ids.has(canonical):
			unlocked_building_ids.append(canonical)
		history_changed.emit()
		return existing
	var entry := BuildingUnlockHistoryEntry.new()
	entry.building_id = canonical
	entry.unlocked_at = maxf(0.0, unlocked_at)
	entry.source_event_id = source_event_id
	building_unlock_history.append(entry.to_dict())
	if not unlocked_building_ids.has(canonical):
		unlocked_building_ids.append(canonical)
	history_changed.emit()
	return entry

func record_building_placement(building_id: String, slot_id: String, placed_at: float) -> BuildingPlacementHistoryEntry:
	var canonical_building := canonical_building_id(building_id)
	var canonical_slot := canonical_slot_id(slot_id)
	if canonical_building != CANONICAL_CAFE_ID or canonical_slot.is_empty():
		return null
	# The Week 7 scope has no building relocation. The earliest legal café placement wins.
	for raw: Dictionary in building_placement_history:
		var existing := BuildingPlacementHistoryEntry.from_dict(raw)
		if existing.building_id == canonical_building:
			if _time_is_earlier(placed_at, existing.placed_at):
				existing.slot_id = canonical_slot
				existing.placed_at = maxf(0.0, placed_at)
				_replace_placement(existing)
			_rebuild_slots_from_placement_history()
			history_changed.emit()
			return existing
	var entry := BuildingPlacementHistoryEntry.new()
	entry.building_id = canonical_building
	entry.slot_id = canonical_slot
	entry.placed_at = maxf(0.0, placed_at)
	building_placement_history.append(entry.to_dict())
	_rebuild_slots_from_placement_history()
	history_changed.emit()
	return entry

func record_construction_start(record: ConstructionRecord, coin_cost: int = 0, material_costs: Dictionary = {}) -> ConstructionHistoryEntry:
	if record == null or record.construction_record_id.is_empty():
		return null
	var canonical_building := canonical_building_id(record.building_id)
	var canonical_slot := canonical_slot_id(record.slot_id)
	if canonical_building != CANONICAL_CAFE_ID or canonical_slot.is_empty():
		return null
	for raw: Dictionary in construction_history:
		var existing := ConstructionHistoryEntry.from_dict(raw)
		if existing.construction_record_id == record.construction_record_id:
			return existing
	var entry := ConstructionHistoryEntry.new()
	entry.construction_record_id = record.construction_record_id
	entry.building_id = canonical_building
	entry.slot_id = canonical_slot
	entry.started_at = maxf(0.0, record.started_at)
	entry.complete_at = maxf(entry.started_at, record.ends_at)
	entry.completed_at = maxf(0.0, record.completed_at)
	entry.coin_cost = maxi(0, coin_cost)
	entry.material_costs = material_costs.duplicate(true)
	entry.is_completed = record.is_completed or entry.completed_at > 0.0
	construction_history.append(entry.to_dict())
	_set_active_construction(entry)
	record_building_placement(canonical_building, canonical_slot, record.started_at)
	history_changed.emit()
	return entry

func record_construction_complete(result: ConstructionResult) -> ConstructionHistoryEntry:
	if result == null or result.construction_record_id.is_empty():
		return null
	for i in construction_history.size():
		var entry := ConstructionHistoryEntry.from_dict(construction_history[i])
		if entry.construction_record_id != result.construction_record_id:
			continue
		entry.building_id = CANONICAL_CAFE_ID if canonical_building_id(result.building_id) == CANONICAL_CAFE_ID else entry.building_id
		var canonical_slot := canonical_slot_id(result.slot_id)
		if not canonical_slot.is_empty():
			entry.slot_id = canonical_slot
		entry.started_at = entry.started_at if entry.started_at > 0.0 else maxf(0.0, result.started_at)
		entry.completed_at = maxf(entry.completed_at, result.completed_at)
		entry.complete_at = maxf(entry.complete_at, entry.started_at)
		entry.is_completed = true
		construction_history[i] = entry.to_dict()
		_remove_active_construction(entry.construction_record_id)
		record_building_placement(entry.building_id, entry.slot_id, entry.started_at)
		history_changed.emit()
		return entry
	var migrated_record := ConstructionRecord.new()
	migrated_record.construction_record_id = result.construction_record_id
	migrated_record.building_id = result.building_id
	migrated_record.slot_id = result.slot_id
	migrated_record.started_at = result.started_at
	migrated_record.ends_at = result.completed_at
	migrated_record.completed_at = result.completed_at
	migrated_record.is_completed = true
	var created := record_construction_start(migrated_record)
	if created != null:
		created.completed_at = maxf(0.0, result.completed_at)
		created.is_completed = true
		_replace_construction(created)
		_remove_active_construction(created.construction_record_id)
		history_changed.emit()
	return created

func record_cafe_activity(active: ActiveActivityData) -> CafeActivityHistoryEntry:
	if active == null or active.activity == null or active.activity_record_id.is_empty():
		return null
	if active.activity.location_id != "cafe" and not active.activity.activity_id.begins_with("cafe_"):
		return null
	for raw: Dictionary in cafe_activity_history:
		var existing := CafeActivityHistoryEntry.from_dict(raw)
		if existing.activity_record_id == active.activity_record_id:
			return existing
	var entry := CafeActivityHistoryEntry.new()
	entry.activity_record_id = active.activity_record_id
	entry.cafe_activity_id = active.activity.activity_id
	entry.started_at = maxf(0.0, active.started_at)
	entry.completed_at = maxf(0.0, active.completed_at)
	if active.activity is CafeActivityData:
		var cafe := active.activity as CafeActivityData
		entry.cafe_experience_change = maxi(0, cafe.cafe_experience_change)
		entry.social_experience_change = maxi(0, cafe.social_experience_change)
		entry.coin_reward = maxi(0, cafe.coin_reward)
	cafe_activity_history.append(entry.to_dict())
	var after := maxi(0, active.rabbit.cafe_experience) if active.rabbit != null else maxi(0, cafe_experience + entry.cafe_experience_change)
	var before := maxi(0, after - entry.cafe_experience_change)
	cafe_experience = maxi(cafe_experience, after)
	record_cafe_experience(entry.cafe_experience_change, "cafe_activity", entry.activity_record_id, entry.completed_at, before, after)
	history_changed.emit()
	return entry

func record_cafe_experience(amount_change: int, source_type: String, source_id: String, created_at: float, amount_before: int = -1, amount_after: int = -1) -> CafeExperienceHistoryEntry:
	if source_id.is_empty():
		return null
	for raw: Dictionary in cafe_experience_history:
		var existing := CafeExperienceHistoryEntry.from_dict(raw)
		if existing.source_type == source_type and existing.source_id == source_id:
			return existing
	var entry := CafeExperienceHistoryEntry.new()
	entry.history_id = "cafe_exp_%s" % source_id
	entry.amount_change = maxi(0, amount_change)
	entry.amount_before = maxi(0, cafe_experience - entry.amount_change) if amount_before < 0 else maxi(0, amount_before)
	entry.amount_after = maxi(entry.amount_before, entry.amount_before + entry.amount_change) if amount_after < 0 else maxi(0, amount_after)
	entry.source_type = source_type
	entry.source_id = source_id
	entry.created_at = maxf(0.0, created_at)
	cafe_experience = maxi(cafe_experience, entry.amount_after)
	cafe_experience_history.append(entry.to_dict())
	history_changed.emit()
	return entry

func record_village_progress(progress: VillageProgressData, at_time: float = -1.0) -> VillageProgressHistoryEntry:
	if progress == null:
		return null
	var old_level := maxi(0, int(village_progress_state.get("village_level", 0)))
	var old_exp := maxi(0, int(village_progress_state.get("village_experience", 0)))
	var new_level := maxi(0, progress.village_level)
	var new_exp := maxi(0, progress.village_experience)
	village_progress_state = progress.to_dict()
	if old_level == new_level and old_exp == new_exp:
		return null
	var event_id := "village_progress_%d_%d" % [new_level, new_exp]
	for raw: Dictionary in village_progress_history:
		if str(raw.get("village_progress_event_id", "")) == event_id:
			return VillageProgressHistoryEntry.from_dict(raw)
	var entry := VillageProgressHistoryEntry.new()
	entry.history_id = "history_%s" % event_id
	entry.village_progress_event_id = event_id
	entry.old_level = old_level
	entry.new_level = new_level
	entry.old_experience = old_exp
	entry.new_experience = new_exp
	entry.changed_at = TimeManager.get_now() if at_time <= 0.0 else at_time
	village_progress_history.append(entry.to_dict())
	history_changed.emit()
	return entry

func record_appearance(appearance_state_id: String, source_event_id: String, changed_at: float) -> GrowthAppearanceHistoryEntry:
	var state := _sanitize_appearance_state(appearance_state_id)
	if source_event_id.is_empty() or state == "normal" and appearance_state_id != "normal":
		return null
	for raw: Dictionary in growth_appearance_history:
		var existing := GrowthAppearanceHistoryEntry.from_dict(raw)
		if existing.source_event_id == source_event_id:
			growth_appearance_state = existing.appearance_state_id
			return existing
	var entry := GrowthAppearanceHistoryEntry.new()
	entry.appearance_state_id = state
	entry.source_event_id = source_event_id
	entry.changed_at = maxf(0.0, changed_at)
	growth_appearance_history.append(entry.to_dict())
	growth_appearance_state = state
	history_changed.emit()
	return entry

func repair_consistency(now: float = -1.0) -> void:
	var check_time := TimeManager.get_now() if now <= 0.0 else now
	building_unlock_history = _sanitize_building_unlock_history(building_unlock_history)
	building_placement_history = _sanitize_building_placement_history(building_placement_history)
	construction_history = _sanitize_construction_history(construction_history)
	cafe_activity_history = _sanitize_cafe_activity_history(cafe_activity_history)
	cafe_experience_history = _sanitize_cafe_experience_history(cafe_experience_history)
	village_progress_history = _sanitize_village_progress_history(village_progress_history)
	growth_appearance_history = _sanitize_appearance_history(growth_appearance_history)
	active_constructions = _sanitize_active_constructions(active_constructions)
	for i in construction_history.size():
		var entry := ConstructionHistoryEntry.from_dict(construction_history[i])
		if not entry.is_completed and entry.complete_at > 0.0 and entry.complete_at <= check_time:
			entry.is_completed = true
			entry.completed_at = entry.complete_at
			construction_history[i] = entry.to_dict()
		# A completed History record is authoritative. Even if a stale active entry is
		# reloaded or re-synced later, Repair must remove it without re-spending costs.
		if entry.is_completed:
			_remove_active_construction(entry.construction_record_id)
			if not entry.slot_id.is_empty():
				record_building_placement(entry.building_id, entry.slot_id, entry.started_at)
	_rebuild_slots_from_placement_history()
	if growth_appearance_history.size() > 0:
		var latest := GrowthAppearanceHistoryEntry.from_dict(growth_appearance_history[0])
		for raw: Dictionary in growth_appearance_history:
			var candidate := GrowthAppearanceHistoryEntry.from_dict(raw)
			if candidate.changed_at >= latest.changed_at:
				latest = candidate
		growth_appearance_state = latest.appearance_state_id
	cafe_experience = maxi(0, cafe_experience)
	for raw: Dictionary in cafe_experience_history:
		cafe_experience = maxi(cafe_experience, CafeExperienceHistoryEntry.from_dict(raw).amount_after)

func building_unlock_history_to_array() -> Array[Dictionary]: return building_unlock_history.duplicate(true)
func building_placement_history_to_array() -> Array[Dictionary]: return building_placement_history.duplicate(true)
func construction_history_to_array() -> Array[Dictionary]: return construction_history.duplicate(true)
func cafe_activity_history_to_array() -> Array[Dictionary]: return cafe_activity_history.duplicate(true)
func cafe_experience_history_to_array() -> Array[Dictionary]: return cafe_experience_history.duplicate(true)
func village_progress_history_to_array() -> Array[Dictionary]: return village_progress_history.duplicate(true)
func growth_appearance_history_to_array() -> Array[Dictionary]: return growth_appearance_history.duplicate(true)

static func canonical_building_id(building_id: String) -> String:
	match building_id:
		"cafe", "coffee_shop": return "cafe"
		"library", "flower_shop", "workshop": return building_id
	return ""

static func canonical_slot_id(slot_id: String) -> String:
	if BUILDING_SLOTS.has(slot_id):
		return slot_id
	if slot_id.begins_with("Slot"):
		var suffix := slot_id.trim_prefix("Slot")
		if suffix.is_valid_int():
			var index := int(suffix)
			if index >= 1 and index <= 5:
				return "building_slot_%02d" % index
	return ""

static func runtime_slot_id(slot_id: String) -> String:
	var canonical := canonical_slot_id(slot_id)
	if canonical.is_empty():
		return ""
	return "Slot%02d" % int(canonical.trim_prefix("building_slot_"))

func _reset_slots() -> void:
	building_slots = {}
	for slot_id: String in BUILDING_SLOTS:
		building_slots[slot_id] = ""

func _sanitize_slots(source: Variant) -> Dictionary:
	var result := {}
	for slot_id: String in BUILDING_SLOTS:
		result[slot_id] = ""
	if not (source is Dictionary):
		return result
	var used_buildings := {}
	for raw_slot: Variant in source.keys():
		var slot_id := canonical_slot_id(str(raw_slot))
		var building_id := canonical_building_id(str(source[raw_slot]))
		if slot_id.is_empty() or building_id != CANONICAL_CAFE_ID or used_buildings.has(building_id):
			continue
		result[slot_id] = building_id
		used_buildings[building_id] = true
	return result

func _sanitize_unlocked(source: Variant) -> Array[String]:
	var result: Array[String] = []
	if source is Array:
		for raw: Variant in source:
			var id := canonical_building_id(str(raw))
			if RESERVED_BUILDING_IDS.has(id) and not result.has(id):
				result.append(id)
	return result

func _sanitize_active_constructions(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array):
		return result
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := ConstructionHistoryEntry.from_dict(raw)
		entry.building_id = canonical_building_id(entry.building_id)
		entry.slot_id = canonical_slot_id(entry.slot_id)
		if entry.construction_record_id.is_empty() or entry.building_id != CANONICAL_CAFE_ID or entry.slot_id.is_empty() or entry.is_completed or seen.has(entry.construction_record_id):
			continue
		seen[entry.construction_record_id] = true
		result.append(entry.to_dict())
	return result

func _sanitize_building_unlock_history(source: Variant) -> Array[Dictionary]:
	var earliest: BuildingUnlockHistoryEntry = null
	if source is Array:
		for raw: Variant in source:
			if not (raw is Dictionary): continue
			var entry := BuildingUnlockHistoryEntry.from_dict(raw)
			entry.building_id = canonical_building_id(entry.building_id)
			if entry.building_id != CANONICAL_CAFE_ID: continue
			if earliest == null or _time_is_earlier(entry.unlocked_at, earliest.unlocked_at): earliest = entry
	var result: Array[Dictionary] = []
	if earliest != null: result.append(earliest.to_dict())
	return result

func _sanitize_building_placement_history(source: Variant) -> Array[Dictionary]:
	var earliest: BuildingPlacementHistoryEntry = null
	if source is Array:
		for raw: Variant in source:
			if not (raw is Dictionary): continue
			var entry := BuildingPlacementHistoryEntry.from_dict(raw)
			entry.building_id = canonical_building_id(entry.building_id)
			entry.slot_id = canonical_slot_id(entry.slot_id)
			if entry.building_id != CANONICAL_CAFE_ID or entry.slot_id.is_empty(): continue
			if earliest == null or _time_is_earlier(entry.placed_at, earliest.placed_at): earliest = entry
	var result: Array[Dictionary] = []
	if earliest != null: result.append(earliest.to_dict())
	return result

func _sanitize_construction_history(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array): return result
	for raw: Variant in source:
		if not (raw is Dictionary): continue
		var entry := ConstructionHistoryEntry.from_dict(raw)
		entry.building_id = canonical_building_id(entry.building_id)
		entry.slot_id = canonical_slot_id(entry.slot_id)
		if entry.construction_record_id.is_empty() or entry.building_id != CANONICAL_CAFE_ID or entry.slot_id.is_empty() or seen.has(entry.construction_record_id): continue
		seen[entry.construction_record_id] = true
		result.append(entry.to_dict())
	return result

func _sanitize_cafe_activity_history(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array): return result
	for raw: Variant in source:
		if not (raw is Dictionary): continue
		var entry := CafeActivityHistoryEntry.from_dict(raw)
		if entry.activity_record_id.is_empty() or not entry.cafe_activity_id.begins_with("cafe_") or seen.has(entry.activity_record_id): continue
		seen[entry.activity_record_id] = true
		result.append(entry.to_dict())
	return result

func _sanitize_cafe_experience_history(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array): return result
	for raw: Variant in source:
		if not (raw is Dictionary): continue
		var entry := CafeExperienceHistoryEntry.from_dict(raw)
		var key := "%s|%s" % [entry.source_type, entry.source_id]
		if entry.source_id.is_empty() or seen.has(key): continue
		seen[key] = true
		result.append(entry.to_dict())
	return result

func _sanitize_village_progress_history(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array): return result
	for raw: Variant in source:
		if not (raw is Dictionary): continue
		var entry := VillageProgressHistoryEntry.from_dict(raw)
		if entry.village_progress_event_id.is_empty() or seen.has(entry.village_progress_event_id): continue
		seen[entry.village_progress_event_id] = true
		result.append(entry.to_dict())
	return result

func _sanitize_appearance_history(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	if not (source is Array): return result
	for raw: Variant in source:
		if not (raw is Dictionary): continue
		var entry := GrowthAppearanceHistoryEntry.from_dict(raw)
		entry.appearance_state_id = _sanitize_appearance_state(entry.appearance_state_id)
		if entry.source_event_id.is_empty() or seen.has(entry.source_event_id): continue
		seen[entry.source_event_id] = true
		result.append(entry.to_dict())
	return result

func _sanitize_appearance_state(value: String) -> String:
	return value if VALID_APPEARANCE_STATES.has(value) else "normal"

func _replace_placement(entry: BuildingPlacementHistoryEntry) -> void:
	for i in building_placement_history.size():
		if str(building_placement_history[i].get("building_id", "")) == entry.building_id:
			building_placement_history[i] = entry.to_dict()
			return

func _replace_construction(entry: ConstructionHistoryEntry) -> void:
	for i in construction_history.size():
		if str(construction_history[i].get("construction_record_id", "")) == entry.construction_record_id:
			construction_history[i] = entry.to_dict()
			return

func _set_active_construction(entry: ConstructionHistoryEntry) -> void:
	_remove_active_construction(entry.construction_record_id)
	if not entry.is_completed:
		active_constructions.append(entry.to_dict())

func _remove_active_construction(record_id: String) -> void:
	for i in range(active_constructions.size() - 1, -1, -1):
		if str(active_constructions[i].get("construction_record_id", active_constructions[i].get("construction_id", ""))) == record_id:
			active_constructions.remove_at(i)

func _rebuild_slots_from_placement_history() -> void:
	_reset_slots()
	var earliest: BuildingPlacementHistoryEntry = null
	for raw: Dictionary in building_placement_history:
		var entry := BuildingPlacementHistoryEntry.from_dict(raw)
		if entry.building_id != CANONICAL_CAFE_ID or entry.slot_id.is_empty(): continue
		if earliest == null or _time_is_earlier(entry.placed_at, earliest.placed_at): earliest = entry
	if earliest != null:
		building_slots[earliest.slot_id] = CANONICAL_CAFE_ID

static func _time_is_earlier(candidate: float, current: float) -> bool:
	if current <= 0.0: return candidate > 0.0
	if candidate <= 0.0: return false
	return candidate < current
