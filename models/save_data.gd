class_name SaveData
extends Resource

const CURRENT_VERSION := 6
const VALID_ITEM_IDS := ["carrot", "leaf", "twig", "small_stone", "driftwood", "apple", "bread",
	"berry_juice", "small_snack", "carrot_sandwich", "forest_salad", "berry_toast", "picnic_snack"]

var save_version := CURRENT_VERSION
var rabbits: Array[Dictionary] = []
var current_activity: Dictionary = {}
var journals: Array[Dictionary] = []
var completed_activity_ids: Array[String] = []
var last_saved_at := 0.0
var forest_experience := 0
var fishing_experience := 0
var intimacy := 0
var forest_activity_count := 0
var fishing_activity_count := 0
var home_activity_count := 0
var total_activity_count := 0
var all_activity_records: Array[Dictionary] = []
var unlocked_growth_marks: Array[Dictionary] = []
var pending_growth_event: Dictionary = {}
var growth_album_entries: Array[Dictionary] = []
var growth_tendencies: Dictionary = {"forest": 0, "lake": 0, "home": 0}
var village_data: Dictionary = {}

# Week 5 permanent data.
var inventory: Dictionary = {}
var currency_data: Dictionary = {"currency_id": "coin", "amount": 0, "total_earned": 0, "total_spent": 0}
var reward_history: Array[Dictionary] = []
var inventory_history: Array[Dictionary] = []
var currency_history: Array[Dictionary] = []
var item_collection: Array[Dictionary] = []
var item_discovery_history: Array[Dictionary] = []
var food_use_history: Array[Dictionary] = []
var growth_path_progress: Dictionary = {"forest_stage": 0, "lakeside_stage": 0, "forest_tendency_level": 0, "lakeside_tendency_level": 0, "last_updated_at": 0.0}
var growth_path_history: Array[Dictionary] = []
var life_event_history: Array[Dictionary] = []
var pending_life_events: Array[Dictionary] = []
var completed_life_event_ids: Array[String] = []
var last_food_journal_date := ""
var last_needs_journal_date := ""
var shop_state: Dictionary = {}
var cooking_state: Dictionary = {}
var food_runtime_state: Dictionary = {}
var life_location_state: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"rabbits": rabbits.duplicate(true),
		"current_activity": current_activity.duplicate(true),
		"journals": journals.duplicate(true),
		"completed_activity_ids": completed_activity_ids.duplicate(),
		"last_saved_at": last_saved_at,
		"forest_experience": forest_experience,
		"fishing_experience": fishing_experience,
		"intimacy": intimacy,
		"forest_activity_count": forest_activity_count,
		"fishing_activity_count": fishing_activity_count,
		"home_activity_count": home_activity_count,
		"total_activity_count": total_activity_count,
		"all_activity_records": all_activity_records.duplicate(true),
		"unlocked_growth_marks": unlocked_growth_marks.duplicate(true),
		"pending_growth_event": pending_growth_event.duplicate(true),
		"growth_album_entries": growth_album_entries.duplicate(true),
		"growth_tendencies": growth_tendencies.duplicate(true),
		"village_data": village_data.duplicate(true),
		"inventory": inventory.duplicate(true),
		"currency_data": currency_data.duplicate(true),
		"reward_history": reward_history.duplicate(true),
		"inventory_history": inventory_history.duplicate(true),
		"currency_history": currency_history.duplicate(true),
		"item_collection": item_collection.duplicate(true),
		"item_discovery_history": item_discovery_history.duplicate(true),
		"food_use_history": food_use_history.duplicate(true),
		"growth_path_progress": growth_path_progress.duplicate(true),
		"growth_path_history": growth_path_history.duplicate(true),
		"life_event_history": life_event_history.duplicate(true),
		"pending_life_events": pending_life_events.duplicate(true),
		"completed_life_event_ids": completed_life_event_ids.duplicate(),
		"last_food_journal_date": last_food_journal_date,
		"last_needs_journal_date": last_needs_journal_date,
		"shop_state": shop_state.duplicate(true), "cooking_state": cooking_state.duplicate(true),
		"food_runtime_state": food_runtime_state.duplicate(true), "life_location_state": life_location_state.duplicate(true)
	}

static func from_dict(data: Dictionary) -> SaveData:
	var result := SaveData.new()
	result.save_version = int(data.get("save_version", data.get("version", 1)))
	_copy_dict_array(data.get("rabbits", []), result.rabbits)
	if data.get("current_activity", {}) is Dictionary:
		result.current_activity = data.get("current_activity", {}).duplicate(true)
	_copy_dict_array(data.get("journals", []), result.journals)
	if result.journals.is_empty():
		_copy_dict_array(data.get("village_journals", []), result.journals)
	for raw_id: Variant in data.get("completed_activity_ids", []):
		var activity_record_id := str(raw_id)
		if not activity_record_id.is_empty() and not result.completed_activity_ids.has(activity_record_id):
			result.completed_activity_ids.append(activity_record_id)
	result.last_saved_at = maxf(0.0, float(data.get("last_saved_at", 0.0)))
	result.forest_experience = maxi(0, int(data.get("forest_experience", 0)))
	result.fishing_experience = maxi(0, int(data.get("fishing_experience", 0)))
	result.intimacy = maxi(0, int(data.get("intimacy", 0)))
	result.forest_activity_count = maxi(0, int(data.get("forest_activity_count", 0)))
	result.fishing_activity_count = maxi(0, int(data.get("fishing_activity_count", 0)))
	result.home_activity_count = maxi(0, int(data.get("home_activity_count", 0)))
	result.total_activity_count = maxi(0, int(data.get("total_activity_count", 0)))
	_copy_dict_array(data.get("all_activity_records", []), result.all_activity_records)
	for item: Variant in data.get("unlocked_growth_marks", []):
		if item is Dictionary:
			result.unlocked_growth_marks.append(item.duplicate(true))
		else:
			result.unlocked_growth_marks.append({"id": str(item), "is_unlocked": true, "unlocked_at": 0.0})
	if data.get("pending_growth_event", {}) is Dictionary:
		result.pending_growth_event = data.get("pending_growth_event", {}).duplicate(true)
	_copy_dict_array(data.get("growth_album_entries", []), result.growth_album_entries)
	if data.get("growth_tendencies", {}) is Dictionary:
		result.growth_tendencies = data.get("growth_tendencies", {}).duplicate(true)
	result.village_data = _load_village_data(data)

	result.inventory = _load_inventory(data.get("inventory", {}))
	result.currency_data = _load_currency(data.get("currency_data", {}))
	_load_reward_history(data.get("reward_history", []), result.reward_history)
	_load_inventory_history(data.get("inventory_history", []), result.inventory_history)
	_load_currency_history(data.get("currency_history", []), result.currency_history)
	result.item_collection = _load_item_collection(data.get("item_collection", []))
	_load_item_discovery_history(data.get("item_discovery_history", []), result.item_discovery_history)
	_load_food_use_history(data.get("food_use_history", []), result.food_use_history)
	result.growth_path_progress = _load_growth_path_progress(data.get("growth_path_progress", {}))
	_load_growth_path_history(data.get("growth_path_history", []), result.growth_path_history)
	_load_life_event_history(data.get("life_event_history", []), result.life_event_history)
	_load_pending_life_events(data.get("pending_life_events", []), result.pending_life_events)
	for raw_id: Variant in data.get("completed_life_event_ids", []):
		var event_id := str(raw_id)
		if not event_id.is_empty() and not result.completed_life_event_ids.has(event_id):
			result.completed_life_event_ids.append(event_id)
	result.last_food_journal_date = str(data.get("last_food_journal_date", ""))
	result.last_needs_journal_date = str(data.get("last_needs_journal_date", ""))
	if data.get("shop_state", {}) is Dictionary: result.shop_state = data.get("shop_state", {}).duplicate(true)
	if data.get("cooking_state", {}) is Dictionary: result.cooking_state = data.get("cooking_state", {}).duplicate(true)
	if data.get("food_runtime_state", {}) is Dictionary: result.food_runtime_state = data.get("food_runtime_state", {}).duplicate(true)
	if data.get("life_location_state", {}) is Dictionary: result.life_location_state = data.get("life_location_state", {}).duplicate(true)
	_repair_growth_progress(result)
	return result

func is_supported_version() -> bool:
	return save_version >= 1 and save_version <= CURRENT_VERSION

static func _copy_dict_array(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	for item: Variant in source:
		if item is Dictionary:
			target.append(item.duplicate(true))

static func _load_inventory(source: Variant) -> Dictionary:
	var result := {}
	if not (source is Dictionary):
		return result
	for raw_id: Variant in source.keys():
		var item_id := str(raw_id)
		if not VALID_ITEM_IDS.has(item_id):
			continue
		var raw_entry: Variant = source[raw_id]
		if not (raw_entry is Dictionary):
			continue
		var entry := InventoryEntry.from_dict(raw_entry)
		entry.item_id = item_id
		entry.amount = maxi(0, entry.amount)
		entry.total_obtained = maxi(entry.amount, entry.total_obtained)
		result[item_id] = entry.to_dict()
	return result

static func _load_currency(source: Variant) -> Dictionary:
	if not (source is Dictionary):
		return CurrencyData.new().to_dict()
	var currency := CurrencyData.from_dict(source)
	currency.currency_id = "coin"
	currency.amount = maxi(0, currency.amount)
	currency.total_earned = maxi(currency.amount, currency.total_earned)
	return currency.to_dict()

static func _load_reward_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen_activity := {}
	var seen_reward := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := RewardHistoryEntry.from_dict(raw)
		if entry.reward_record_id.is_empty() or entry.activity_record_id.is_empty():
			continue
		if seen_activity.has(entry.activity_record_id) or seen_reward.has(entry.reward_record_id):
			continue
		var clean_items := {}
		for raw_id: Variant in entry.item_rewards.keys():
			var item_id := str(raw_id)
			var amount := maxi(0, int(entry.item_rewards[raw_id]))
			if VALID_ITEM_IDS.has(item_id) and amount > 0:
				clean_items[item_id] = amount
		entry.item_rewards = clean_items
		seen_activity[entry.activity_record_id] = true
		seen_reward[entry.reward_record_id] = true
		target.append(entry.to_dict())

static func _load_inventory_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := InventoryHistoryEntry.from_dict(raw)
		if not VALID_ITEM_IDS.has(entry.item_id):
			continue
		var key := entry.inventory_history_id
		if key.is_empty():
			key = "%s|%s|%s|%d" % [entry.item_id, entry.source_type, entry.source_id, entry.amount_after]
		if seen.has(key):
			continue
		seen[key] = true
		target.append(entry.to_dict())

static func _load_currency_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := CurrencyHistoryEntry.from_dict(raw)
		if entry.currency_id != "coin":
			continue
		var key := entry.currency_history_id
		if key.is_empty():
			key = "%s|%s|%d" % [entry.source_type, entry.source_id, entry.amount_after]
		if seen.has(key):
			continue
		seen[key] = true
		target.append(entry.to_dict())

static func _load_item_collection(source: Variant) -> Array[Dictionary]:
	var merged := {}
	if not (source is Array):
		var empty: Array[Dictionary] = []
		return empty
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := ItemCollectionEntry.from_dict(raw)
		if not VALID_ITEM_IDS.has(entry.item_id) or not entry.is_discovered:
			continue
		if not merged.has(entry.item_id):
			merged[entry.item_id] = entry
			continue
		var current := merged[entry.item_id] as ItemCollectionEntry
		if _time_is_earlier(entry.first_obtained_at, current.first_obtained_at):
			merged[entry.item_id] = entry
	var result: Array[Dictionary] = []
	for entry: ItemCollectionEntry in merged.values():
		result.append(entry.to_dict())
	return result

static func _load_item_discovery_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen_items := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := ItemDiscoveryHistoryEntry.from_dict(raw)
		if not VALID_ITEM_IDS.has(entry.item_id) or seen_items.has(entry.item_id):
			continue
		seen_items[entry.item_id] = true
		target.append(entry.to_dict())

static func _load_food_use_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := FoodUseHistoryEntry.from_dict(raw)
		if entry.food_use_record_id.is_empty() or not VALID_ITEM_IDS.has(entry.food_id) or seen.has(entry.food_use_record_id):
			continue
		seen[entry.food_use_record_id] = true
		target.append(entry.to_dict())

static func _load_growth_path_progress(source: Variant) -> Dictionary:
	var raw: Dictionary = source if source is Dictionary else {}
	return {
		"forest_stage": maxi(0, int(raw.get("forest_stage", 0))),
		"lakeside_stage": maxi(0, int(raw.get("lakeside_stage", 0))),
		"forest_tendency_level": clampi(int(raw.get("forest_tendency_level", 0)), 0, 3),
		"lakeside_tendency_level": clampi(int(raw.get("lakeside_tendency_level", 0)), 0, 3),
		"last_updated_at": maxf(0.0, float(raw.get("last_updated_at", 0.0)))
	}

static func _load_growth_path_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := GrowthPathHistoryEntry.from_dict(raw)
		if entry.source_event_id.is_empty() or seen.has(entry.source_event_id):
			continue
		seen[entry.source_event_id] = true
		target.append(entry.to_dict())

static func _load_life_event_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := LifeEventHistoryEntry.from_dict(raw)
		if entry.life_event_id.is_empty() or seen.has(entry.life_event_id):
			continue
		seen[entry.life_event_id] = true
		target.append(entry.to_dict())

static func _load_pending_life_events(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var event_id := str(raw.get("event_id", ""))
		if event_id.is_empty() or seen.has(event_id):
			continue
		seen[event_id] = true
		target.append(raw.duplicate(true))

static func _repair_growth_progress(data: SaveData) -> void:
	var forest_stage := maxi(0, int(data.growth_path_progress.get("forest_stage", 0)))
	var lakeside_stage := maxi(0, int(data.growth_path_progress.get("lakeside_stage", 0)))
	if _has_growth_mark(data.unlocked_growth_marks, "leaf_mark"):
		forest_stage = maxi(forest_stage, 1)
	if _has_growth_mark(data.unlocked_growth_marks, "sprout_mark"):
		forest_stage = maxi(forest_stage, 2)
	if _has_growth_mark(data.unlocked_growth_marks, "lake_interest") or _has_growth_event_journal(data.journals, "growth_lake_interest_001"):
		lakeside_stage = maxi(lakeside_stage, 1)
	data.growth_path_progress["forest_stage"] = forest_stage
	data.growth_path_progress["lakeside_stage"] = lakeside_stage

static func _has_growth_mark(marks: Array[Dictionary], mark_id: String) -> bool:
	for mark: Dictionary in marks:
		if str(mark.get("id", "")) == mark_id:
			return true
	return false

static func _has_growth_event_journal(journal_entries: Array[Dictionary], event_id: String) -> bool:
	for journal: Dictionary in journal_entries:
		if str(journal.get("growth_event_id", "")) == event_id:
			return true
	return false

static func _time_is_earlier(candidate: float, current: float) -> bool:
	if current <= 0.0:
		return candidate > 0.0
	if candidate <= 0.0:
		return false
	return candidate < current

static func _load_village_data(data: Dictionary) -> Dictionary:
	var nested: Variant = data.get("village_data", {})
	if nested is Dictionary and not nested.is_empty():
		return VillageData.from_dict(nested).to_dict()
	var legacy := {
		"progress": data.get("village_progress", {}),
		"pending_village_events": data.get("pending_village_events", []),
		"completed_village_event_ids": data.get("completed_village_event_ids", []),
		"building_records": data.get("buildings", {}),
		"construction_records": data.get("construction_records", []),
		"building_interaction_records": data.get("building_interaction_records", []),
		"daily_notice": data.get("daily_notice", {}),
		"notice_history": data.get("notice_history", []),
		"farm": data.get("farm_data", {}),
		"farm_cycle_records": data.get("farm_cycle_records", []),
		"harvest_records": data.get("harvest_records", []),
		"carrot_inventory": data.get("carrot_inventory", {}),
		"building_history": data.get("building_history", [])
	}
	return VillageData.from_dict(legacy).to_dict()
