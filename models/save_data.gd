class_name SaveData
extends Resource

const CURRENT_VERSION := 8
const VALID_ITEM_IDS := ["carrot", "leaf", "twig", "small_stone", "driftwood", "apple", "bread",
	"berry_juice", "small_snack", "carrot_sandwich", "forest_salad", "berry_toast", "picnic_snack"]
const VALID_PRODUCT_IDS := ["carrot", "apple", "bread", "berry_juice", "small_snack"]
const VALID_RECIPE_IDS := ["recipe_carrot_sandwich", "recipe_forest_salad", "recipe_berry_toast", "recipe_picnic_snack"]
const VALID_FOOD_IDS := ["carrot", "apple", "bread", "berry_juice", "small_snack", "carrot_sandwich", "forest_salad", "berry_toast", "picnic_snack"]
const WEEK7_BUILDING_IDS := ["cafe", "library", "flower_shop", "workshop"]
const WEEK7_BUILDABLE_BUILDING_IDS := ["cafe"]
const WEEK7_BUILDING_SLOTS := ["building_slot_01", "building_slot_02", "building_slot_03", "building_slot_04", "building_slot_05"]
const WEEK7_APPEARANCE_STATES := ["normal", "leaf", "sprout", "forest_stage3", "lakeside_stage2"]

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

# Week 6 permanent shop / cooking / life-location data.
var daily_shop_state: Dictionary = {}
var purchase_history: Array[Dictionary] = []
var daily_shop_history: Array[Dictionary] = []
var product_unlock_history: Array[Dictionary] = []
var shop_event_history: Array[Dictionary] = []
var recipe_collection: Array[Dictionary] = []
var cooking_history: Array[Dictionary] = []
var recipe_unlock_history: Array[Dictionary] = []
var food_variety_records: Array[Dictionary] = []
var life_location_history: Array[Dictionary] = []
var last_shopping_journal_date := ""
var last_cooking_journal_date := ""
var last_picnic_journal_date := ""

# Week 7 permanent building / café / advanced-growth data.
var building_slots: Dictionary = {
	"building_slot_01": "", "building_slot_02": "", "building_slot_03": "",
	"building_slot_04": "", "building_slot_05": ""
}
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
		"shop_state": shop_state.duplicate(true),
		"daily_shop_state": daily_shop_state.duplicate(true),
		"purchase_history": purchase_history.duplicate(true),
		"daily_shop_history": daily_shop_history.duplicate(true),
		"product_unlock_history": product_unlock_history.duplicate(true),
		"shop_event_history": shop_event_history.duplicate(true),
		"recipe_collection": recipe_collection.duplicate(true),
		"cooking_history": cooking_history.duplicate(true),
		"recipe_unlock_history": recipe_unlock_history.duplicate(true),
		"food_variety_records": food_variety_records.duplicate(true),
		"life_location_history": life_location_history.duplicate(true),
		"last_shopping_journal_date": last_shopping_journal_date,
		"last_cooking_journal_date": last_cooking_journal_date,
		"last_picnic_journal_date": last_picnic_journal_date,
		"building_slots": building_slots.duplicate(true),
		"unlocked_building_ids": unlocked_building_ids.duplicate(),
		"buildable_building_ids": buildable_building_ids.duplicate(),
		"active_constructions": active_constructions.duplicate(true),
		"building_unlock_history": building_unlock_history.duplicate(true),
		"building_placement_history": building_placement_history.duplicate(true),
		"construction_history": construction_history.duplicate(true),
		"cafe_experience": cafe_experience,
		"cafe_activity_history": cafe_activity_history.duplicate(true),
		"cafe_experience_history": cafe_experience_history.duplicate(true),
		"village_progress_state": village_progress_state.duplicate(true),
		"village_progress_history": village_progress_history.duplicate(true),
		"growth_appearance_state": growth_appearance_state,
		"growth_appearance_history": growth_appearance_history.duplicate(true),
		"cooking_state": cooking_state.duplicate(true),
		"food_runtime_state": food_runtime_state.duplicate(true),
		"life_location_state": life_location_state.duplicate(true)
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
	result.shop_state = _load_shop_state(data.get("shop_state", {}))
	result.daily_shop_state = _load_daily_shop_state(data.get("daily_shop_state", result.shop_state))
	_load_purchase_history(data.get("purchase_history", []), result.purchase_history)
	_load_daily_shop_history(data.get("daily_shop_history", []), result.daily_shop_history)
	_load_product_unlock_history(data.get("product_unlock_history", []), result.product_unlock_history)
	_load_shop_event_history(data.get("shop_event_history", []), result.shop_event_history)
	result.recipe_collection = _load_recipe_collection(data.get("recipe_collection", []))
	_load_cooking_history(data.get("cooking_history", []), result.cooking_history)
	_load_recipe_unlock_history(data.get("recipe_unlock_history", []), result.recipe_unlock_history)
	result.food_variety_records = _load_food_variety_records(data.get("food_variety_records", []))
	_load_life_location_history(data.get("life_location_history", []), result.life_location_history)
	result.last_shopping_journal_date = str(data.get("last_shopping_journal_date", ""))
	result.last_cooking_journal_date = str(data.get("last_cooking_journal_date", ""))
	result.last_picnic_journal_date = str(data.get("last_picnic_journal_date", ""))
	result.building_slots = _load_week7_building_slots(data.get("building_slots", {}))
	result.unlocked_building_ids = _load_week7_building_ids(data.get("unlocked_building_ids", []), true)
	result.buildable_building_ids = _load_week7_building_ids(data.get("buildable_building_ids", ["cafe"]), false)
	if not result.buildable_building_ids.has("cafe"):
		result.buildable_building_ids.append("cafe")
	_load_week7_active_constructions(data.get("active_constructions", []), result.active_constructions)
	_load_week7_building_unlock_history(data.get("building_unlock_history", []), result.building_unlock_history)
	_load_week7_building_placement_history(data.get("building_placement_history", []), result.building_placement_history)
	_load_week7_construction_history(data.get("construction_history", []), result.construction_history)
	result.cafe_experience = maxi(0, int(data.get("cafe_experience", 0)))
	_load_week7_cafe_activity_history(data.get("cafe_activity_history", []), result.cafe_activity_history)
	_load_week7_cafe_experience_history(data.get("cafe_experience_history", []), result.cafe_experience_history)
	if data.get("village_progress_state", {}) is Dictionary:
		result.village_progress_state = data.get("village_progress_state", {}).duplicate(true)
	_load_week7_village_progress_history(data.get("village_progress_history", []), result.village_progress_history)
	result.growth_appearance_state = _load_week7_appearance_state(str(data.get("growth_appearance_state", "normal")))
	_load_week7_appearance_history(data.get("growth_appearance_history", []), result.growth_appearance_history)
	result.cooking_state = _load_cooking_state(data.get("cooking_state", {}))
	if data.get("food_runtime_state", {}) is Dictionary: result.food_runtime_state = data.get("food_runtime_state", {}).duplicate(true)
	if data.get("life_location_state", {}) is Dictionary: result.life_location_state = data.get("life_location_state", {}).duplicate(true)
	_repair_growth_progress(result)
	_repair_week6_transaction_guards(result)
	_repair_week7_consistency(result)
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

static func _load_shop_state(source: Variant) -> Dictionary:
	var raw: Dictionary = source.duplicate(true) if source is Dictionary else {}
	var offers: Array[Dictionary] = []
	var seen_products := {}
	for value: Variant in raw.get("daily_offers", []):
		if not (value is Dictionary):
			continue
		var product_id := str(value.get("product_id", ""))
		if not VALID_PRODUCT_IDS.has(product_id) or seen_products.has(product_id):
			continue
		seen_products[product_id] = true
		var offer := DailyShopOfferData.from_dict(value)
		offers.append(offer.to_dict())
	raw["daily_offers"] = offers
	var purchase_amounts := {}
	var raw_amounts: Variant = raw.get("daily_purchase_amounts", {})
	if raw_amounts is Dictionary:
		for raw_id: Variant in raw_amounts.keys():
			var product_id := str(raw_id)
			if VALID_PRODUCT_IDS.has(product_id):
				purchase_amounts[product_id] = maxi(0, int(raw_amounts[raw_id]))
	raw["daily_purchase_amounts"] = purchase_amounts
	var unlocked: Array[String] = []
	for raw_id: Variant in raw.get("unlocked_product_ids", []):
		var product_id := str(raw_id)
		if VALID_PRODUCT_IDS.has(product_id) and not unlocked.has(product_id):
			unlocked.append(product_id)
	raw["unlocked_product_ids"] = unlocked
	var applied: Array[String] = []
	for raw_id: Variant in raw.get("applied_purchase_ids", []):
		var record_id := str(raw_id)
		if not record_id.is_empty() and not applied.has(record_id):
			applied.append(record_id)
	raw["applied_purchase_ids"] = applied
	return raw

static func _load_daily_shop_state(source: Variant) -> Dictionary:
	var shop := _load_shop_state(source)
	return {
		"day_key": str(shop.get("day_key", "")),
		"daily_offers": shop.get("daily_offers", []).duplicate(true),
		"daily_purchase_amounts": shop.get("daily_purchase_amounts", {}).duplicate(true)
	}

static func _load_purchase_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := PurchaseHistoryEntry.from_dict(raw)
		if entry.purchase_record_id.is_empty() or not VALID_PRODUCT_IDS.has(entry.product_id) or seen.has(entry.purchase_record_id):
			continue
		seen[entry.purchase_record_id] = true
		target.append(entry.to_dict())

static func _load_daily_shop_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var merged := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := DailyShopHistoryEntry.from_dict(raw)
		if entry.day_key.is_empty():
			continue
		var clean_offers: Array[Dictionary] = []
		var seen_products := {}
		for offer_raw: Dictionary in entry.offers:
			var product_id := str(offer_raw.get("product_id", ""))
			if not VALID_PRODUCT_IDS.has(product_id) or seen_products.has(product_id):
				continue
			seen_products[product_id] = true
			clean_offers.append(DailyShopOfferData.from_dict(offer_raw).to_dict())
		entry.offers = clean_offers
		var clean_counts := {}
		for raw_id: Variant in entry.purchase_counts.keys():
			var product_id := str(raw_id)
			if VALID_PRODUCT_IDS.has(product_id):
				clean_counts[product_id] = maxi(0, int(entry.purchase_counts[raw_id]))
		entry.purchase_counts = clean_counts
		if not merged.has(entry.day_key):
			merged[entry.day_key] = entry
		else:
			var current := merged[entry.day_key] as DailyShopHistoryEntry
			if entry.offers.size() > current.offers.size():
				current.offers = entry.offers.duplicate(true)
			current.refreshed_at = maxf(current.refreshed_at, entry.refreshed_at)
			current.refresh_count = maxi(current.refresh_count, entry.refresh_count)
			for product_id: String in entry.purchase_counts:
				current.purchase_counts[product_id] = maxi(int(current.purchase_counts.get(product_id, 0)), int(entry.purchase_counts[product_id]))
	for entry: DailyShopHistoryEntry in merged.values():
		target.append(entry.to_dict())

static func _load_product_unlock_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var merged := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := ProductUnlockHistoryEntry.from_dict(raw)
		if not VALID_PRODUCT_IDS.has(entry.product_id):
			continue
		var current := merged.get(entry.product_id) as ProductUnlockHistoryEntry
		if current == null or _time_is_earlier(entry.unlocked_at, current.unlocked_at):
			merged[entry.product_id] = entry
	for entry: ProductUnlockHistoryEntry in merged.values():
		target.append(entry.to_dict())

static func _load_shop_event_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := ShopEventHistoryEntry.from_dict(raw)
		if entry.shop_event_id.is_empty() or not entry.shop_event_id.begins_with("shop_") or seen.has(entry.shop_event_id):
			continue
		seen[entry.shop_event_id] = true
		target.append(entry.to_dict())

static func _canonical_recipe_id(recipe_id: String) -> String:
	match recipe_id:
		"carrot_sandwich": return "recipe_carrot_sandwich"
		"forest_salad": return "recipe_forest_salad"
		"berry_toast": return "recipe_berry_toast"
		"picnic_snack": return "recipe_picnic_snack"
	return recipe_id

static func _load_recipe_collection(source: Variant) -> Array[Dictionary]:
	var merged := {}
	if not (source is Array):
		var empty: Array[Dictionary] = []
		return empty
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := RecipeCollectionEntry.from_dict(raw)
		entry.recipe_id = _canonical_recipe_id(entry.recipe_id)
		if not VALID_RECIPE_IDS.has(entry.recipe_id) or not entry.is_discovered:
			continue
		var current := merged.get(entry.recipe_id) as RecipeCollectionEntry
		if current == null:
			merged[entry.recipe_id] = entry
		else:
			if _time_is_earlier(entry.first_cooked_at, current.first_cooked_at):
				current.first_cooked_at = entry.first_cooked_at
				current.first_source_type = entry.first_source_type
				current.first_source_id = entry.first_source_id
			current.total_cook_count = maxi(current.total_cook_count, entry.total_cook_count)
	var result: Array[Dictionary] = []
	for entry: RecipeCollectionEntry in merged.values():
		result.append(entry.to_dict())
	return result

static func _load_cooking_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := CookingHistoryEntry.from_dict(raw)
		entry.recipe_id = _canonical_recipe_id(entry.recipe_id)
		if entry.cooking_record_id.is_empty() or not VALID_RECIPE_IDS.has(entry.recipe_id) or seen.has(entry.cooking_record_id):
			continue
		seen[entry.cooking_record_id] = true
		target.append(entry.to_dict())

static func _load_recipe_unlock_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var merged := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := RecipeUnlockHistoryEntry.from_dict(raw)
		entry.recipe_id = _canonical_recipe_id(entry.recipe_id)
		if not VALID_RECIPE_IDS.has(entry.recipe_id):
			continue
		var current := merged.get(entry.recipe_id) as RecipeUnlockHistoryEntry
		if current == null or _time_is_earlier(entry.unlocked_at, current.unlocked_at):
			merged[entry.recipe_id] = entry
	for entry: RecipeUnlockHistoryEntry in merged.values():
		target.append(entry.to_dict())

static func _load_food_variety_records(source: Variant) -> Array[Dictionary]:
	var merged := {}
	if not (source is Array):
		var empty: Array[Dictionary] = []
		return empty
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := FoodVarietyRecord.from_dict(raw)
		if not VALID_FOOD_IDS.has(entry.food_id):
			continue
		var current := merged.get(entry.food_id) as FoodVarietyRecord
		if current == null:
			merged[entry.food_id] = entry
		else:
			if _time_is_earlier(entry.first_used_at, current.first_used_at):
				current.first_used_at = entry.first_used_at
			current.last_used_at = maxf(current.last_used_at, entry.last_used_at)
			current.use_count = maxi(current.use_count, entry.use_count)
	var result: Array[Dictionary] = []
	for entry: FoodVarietyRecord in merged.values():
		result.append(entry.to_dict())
	return result

static func _load_life_location_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := LifeLocationHistoryEntry.from_dict(raw)
		if entry.location_record_id.is_empty() or entry.location_id != "picnic_area" or not ["picnic_rest", "picnic_eat", "picnic_relax"].has(entry.activity_id) or seen.has(entry.location_record_id):
			continue
		seen[entry.location_record_id] = true
		target.append(entry.to_dict())

static func _load_cooking_state(source: Variant) -> Dictionary:
	var raw: Dictionary = source.duplicate(true) if source is Dictionary else {}
	var discovered: Array[String] = []
	for raw_id: Variant in raw.get("discovered_recipe_ids", []):
		var id := str(raw_id)
		if id in ["carrot_sandwich", "forest_salad", "berry_toast", "picnic_snack"] and not discovered.has(id):
			discovered.append(id)
	raw["discovered_recipe_ids"] = discovered
	var unlocked: Array[String] = []
	for raw_id: Variant in raw.get("unlocked_recipe_ids", []):
		var id := str(raw_id)
		if id in ["carrot_sandwich", "forest_salad", "berry_toast", "picnic_snack"] and not unlocked.has(id):
			unlocked.append(id)
	raw["unlocked_recipe_ids"] = unlocked
	var applied: Array[String] = []
	for raw_id: Variant in raw.get("applied_cooking_ids", []):
		var id := str(raw_id)
		if not id.is_empty() and not applied.has(id):
			applied.append(id)
	raw["applied_cooking_ids"] = applied
	return raw

static func _repair_week6_transaction_guards(data: SaveData) -> void:
	var purchase_ids: Array[String] = []
	for raw: Dictionary in data.purchase_history:
		var id := str(raw.get("purchase_record_id", ""))
		if not id.is_empty() and not purchase_ids.has(id):
			purchase_ids.append(id)
	var applied_purchase: Array = []
	var raw_applied_purchase: Variant = data.shop_state.get("applied_purchase_ids", [])
	if raw_applied_purchase is Array:
		applied_purchase = raw_applied_purchase.duplicate()
	for id: String in purchase_ids:
		if not applied_purchase.has(id):
			applied_purchase.append(id)
	data.shop_state["applied_purchase_ids"] = applied_purchase

	var cooking_ids: Array[String] = []
	for raw: Dictionary in data.cooking_history:
		var id := str(raw.get("cooking_record_id", ""))
		if not id.is_empty() and not cooking_ids.has(id):
			cooking_ids.append(id)
	var applied_cooking: Array = []
	var raw_applied_cooking: Variant = data.cooking_state.get("applied_cooking_ids", [])
	if raw_applied_cooking is Array:
		applied_cooking = raw_applied_cooking.duplicate()
	for id: String in cooking_ids:
		if not applied_cooking.has(id):
			applied_cooking.append(id)
	data.cooking_state["applied_cooking_ids"] = applied_cooking

static func _repair_growth_progress(data: SaveData) -> void:
	var forest_stage := maxi(0, int(data.growth_path_progress.get("forest_stage", 0)))
	var lakeside_stage := maxi(0, int(data.growth_path_progress.get("lakeside_stage", 0)))
	if _has_growth_mark(data.unlocked_growth_marks, "leaf_mark"):
		forest_stage = maxi(forest_stage, 1)
	if _has_growth_mark(data.unlocked_growth_marks, "sprout_mark"):
		forest_stage = maxi(forest_stage, 2)
	if _has_growth_mark(data.unlocked_growth_marks, "forest_stage3") or _has_growth_event_journal(data.journals, "growth_forest_stage3_001"):
		forest_stage = maxi(forest_stage, 3)
	if _has_growth_mark(data.unlocked_growth_marks, "lake_interest") or _has_growth_event_journal(data.journals, "growth_lake_interest_001"):
		lakeside_stage = maxi(lakeside_stage, 1)
	if _has_growth_mark(data.unlocked_growth_marks, "lakeside_stage2") or _has_growth_event_journal(data.journals, "growth_lakeside_stage2_001"):
		lakeside_stage = maxi(lakeside_stage, 2)
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

static func _canonical_week7_building_id(value: String) -> String:
	match value:
		"cafe", "coffee_shop":
			return "cafe"
		"library", "flower_shop", "workshop":
			return value
	return ""

static func _canonical_week7_slot_id(value: String) -> String:
	if WEEK7_BUILDING_SLOTS.has(value):
		return value
	if value.begins_with("Slot"):
		var suffix := value.trim_prefix("Slot")
		if suffix.is_valid_int():
			var index := int(suffix)
			if index >= 1 and index <= 5:
				return "building_slot_%02d" % index
	return ""

static func _load_week7_building_slots(source: Variant) -> Dictionary:
	var result := {}
	for slot_id: String in WEEK7_BUILDING_SLOTS:
		result[slot_id] = ""
	if not (source is Dictionary):
		return result
	var cafe_seen := false
	for raw_slot: Variant in source.keys():
		var slot_id := _canonical_week7_slot_id(str(raw_slot))
		var building_id := _canonical_week7_building_id(str(source[raw_slot]))
		if slot_id.is_empty() or building_id != "cafe" or cafe_seen:
			continue
		result[slot_id] = "cafe"
		cafe_seen = true
	return result

static func _load_week7_building_ids(source: Variant, allow_reserved: bool) -> Array[String]:
	var result: Array[String] = []
	if source is Array:
		for raw: Variant in source:
			var id := _canonical_week7_building_id(str(raw))
			if id.is_empty():
				continue
			if not allow_reserved and id != "cafe":
				continue
			if not result.has(id):
				result.append(id)
	return result

static func _load_week7_active_constructions(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := ConstructionHistoryEntry.from_dict(raw)
		entry.building_id = _canonical_week7_building_id(entry.building_id)
		entry.slot_id = _canonical_week7_slot_id(entry.slot_id)
		if entry.construction_record_id.is_empty() or entry.building_id != "cafe" or entry.slot_id.is_empty() or entry.is_completed or seen.has(entry.construction_record_id):
			continue
		seen[entry.construction_record_id] = true
		target.append(entry.to_dict())

static func _load_week7_building_unlock_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var best: BuildingUnlockHistoryEntry = null
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := BuildingUnlockHistoryEntry.from_dict(raw)
		entry.building_id = _canonical_week7_building_id(entry.building_id)
		if entry.building_id != "cafe":
			continue
		if best == null or _time_is_earlier(entry.unlocked_at, best.unlocked_at):
			best = entry
	if best != null:
		target.append(best.to_dict())

static func _load_week7_building_placement_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var best: BuildingPlacementHistoryEntry = null
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := BuildingPlacementHistoryEntry.from_dict(raw)
		entry.building_id = _canonical_week7_building_id(entry.building_id)
		entry.slot_id = _canonical_week7_slot_id(entry.slot_id)
		if entry.building_id != "cafe" or entry.slot_id.is_empty():
			continue
		if best == null or _time_is_earlier(entry.placed_at, best.placed_at):
			best = entry
	if best != null:
		target.append(best.to_dict())

static func _load_week7_construction_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := ConstructionHistoryEntry.from_dict(raw)
		entry.building_id = _canonical_week7_building_id(entry.building_id)
		entry.slot_id = _canonical_week7_slot_id(entry.slot_id)
		if entry.construction_record_id.is_empty() or entry.building_id != "cafe" or entry.slot_id.is_empty() or seen.has(entry.construction_record_id):
			continue
		seen[entry.construction_record_id] = true
		target.append(entry.to_dict())

static func _load_week7_cafe_activity_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := CafeActivityHistoryEntry.from_dict(raw)
		if entry.activity_record_id.is_empty() or not entry.cafe_activity_id.begins_with("cafe_") or seen.has(entry.activity_record_id):
			continue
		seen[entry.activity_record_id] = true
		target.append(entry.to_dict())

static func _load_week7_cafe_experience_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := CafeExperienceHistoryEntry.from_dict(raw)
		var key := "%s|%s" % [entry.source_type, entry.source_id]
		if entry.source_id.is_empty() or seen.has(key):
			continue
		seen[key] = true
		target.append(entry.to_dict())

static func _load_week7_village_progress_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := VillageProgressHistoryEntry.from_dict(raw)
		if entry.village_progress_event_id.is_empty() or seen.has(entry.village_progress_event_id):
			continue
		seen[entry.village_progress_event_id] = true
		target.append(entry.to_dict())

static func _load_week7_appearance_state(value: String) -> String:
	return value if WEEK7_APPEARANCE_STATES.has(value) else "normal"

static func _load_week7_appearance_history(source: Variant, target: Array[Dictionary]) -> void:
	if not (source is Array):
		return
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var entry := GrowthAppearanceHistoryEntry.from_dict(raw)
		entry.appearance_state_id = _load_week7_appearance_state(entry.appearance_state_id)
		if entry.source_event_id.is_empty() or seen.has(entry.source_event_id):
			continue
		seen[entry.source_event_id] = true
		target.append(entry.to_dict())

static func _repair_week7_consistency(data: SaveData) -> void:
	# Fixed Week 7 slot layout. Unknown/duplicate slot data is discarded, while
	# Fourth-week runtime building data stays preserved inside village_data.
	data.building_slots = _load_week7_building_slots(data.building_slots)
	data.unlocked_building_ids = _load_week7_building_ids(data.unlocked_building_ids, true)
	data.buildable_building_ids = ["cafe"]

	var now := TimeManager.get_now()
	for i in data.construction_history.size():
		var entry := ConstructionHistoryEntry.from_dict(data.construction_history[i])
		if not entry.is_completed and entry.complete_at > 0.0 and entry.complete_at <= now:
			entry.is_completed = true
			entry.completed_at = entry.complete_at
			data.construction_history[i] = entry.to_dict()
	for raw: Dictionary in data.construction_history:
		var entry := ConstructionHistoryEntry.from_dict(raw)
		if entry.is_completed and entry.building_id == "cafe" and not entry.slot_id.is_empty():
			var occupied := false
			for slot_id: String in WEEK7_BUILDING_SLOTS:
				if str(data.building_slots.get(slot_id, "")) == "cafe":
					occupied = true
					break
			if not occupied:
				data.building_slots[entry.slot_id] = "cafe"
			if data.building_placement_history.is_empty():
				var placement := BuildingPlacementHistoryEntry.new()
				placement.building_id = "cafe"
				placement.slot_id = entry.slot_id
				placement.placed_at = entry.started_at
				data.building_placement_history.append(placement.to_dict())
			break

	# Completed stage and mark/appearance repair.
	var forest_stage := maxi(0, int(data.growth_path_progress.get("forest_stage", 0)))
	var lakeside_stage := maxi(0, int(data.growth_path_progress.get("lakeside_stage", 0)))
	if forest_stage >= 3:
		data.growth_appearance_state = "forest_stage3"
	elif lakeside_stage >= 2:
		data.growth_appearance_state = "lakeside_stage2"
	elif forest_stage >= 2:
		data.growth_appearance_state = "sprout"
	elif forest_stage >= 1:
		data.growth_appearance_state = "leaf"
	else:
		data.growth_appearance_state = _load_week7_appearance_state(data.growth_appearance_state)

	# Café total may never be lower than the permanent source history.
	for raw: Dictionary in data.cafe_experience_history:
		data.cafe_experience = maxi(data.cafe_experience, CafeExperienceHistoryEntry.from_dict(raw).amount_after)

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
