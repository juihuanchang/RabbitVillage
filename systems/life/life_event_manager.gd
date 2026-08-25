class_name LifeEventManager
extends Node

signal life_event_triggered(event_data: LifeEventData)
signal life_event_confirmed(event_result: LifeEventResult)

var _inventory: InventoryManager
var _growth: GrowthManager
var _village_events: VillageEventManager
var _events: Dictionary = {}
var _pending_event_id := ""
var _shop: ShopManager
var _cooking: CookingManager
var _life_locations: LifeLocationManager
var _food: FoodManager

func _init() -> void:
	_register_event("life_leaf_collection_001", "leaf", 15)
	_register_event("life_twig_collection_001", "twig", 10)
	_register_event("life_stone_collection_001", "small_stone", 6)
	_register_event("life_driftwood_collection_001", "driftwood", 5)
	_register_event("village_life_expands_001", "", 0)
	for id: String in ["shop_first_purchase_001", "shop_regular_customer_001", "shop_big_spender_001",
		"shop_daily_browser_001", "shop_all_foods_discovered_001", "cooking_first_dish_001",
		"cooking_variety_001", "picnic_first_visit_001", "picnic_slow_day_001", "village_daily_life_001"]:
		_register_event(id, "", 0, "日子好像真的過起來了" if id == "village_daily_life_001" else "")

func setup(inventory: InventoryManager, growth: GrowthManager = null, village_events: VillageEventManager = null) -> void:
	_inventory = inventory; _growth = growth; _village_events = village_events

func setup_week6(shop: ShopManager, cooking: CookingManager, locations: LifeLocationManager, food: FoodManager) -> void:
	_shop = shop; _cooking = cooking; _life_locations = locations; _food = food

func _register_event(event_id: String, item_id: String, required_amount: int, display_name := "") -> void:
	var event := LifeEventData.new(); event.event_id = event_id; event.item_id = item_id
	event.display_name = display_name; event.required_total_obtained = required_amount; _events[event_id] = event

func check_life_events() -> LifeEventData:
	if has_pending_life_event(): return get_pending_life_event()
	for event: LifeEventData in _events.values():
		if can_trigger_life_event(event.event_id): return create_pending_life_event(event.event_id)
	return null

func can_trigger_life_event(event_id: String) -> bool:
	var event := _events.get(event_id) as LifeEventData
	if event_id.begins_with("shop_") or event_id.begins_with("cooking_") or event_id.begins_with("picnic_") or event_id == "village_daily_life_001":
		return event != null and event.state == LifeEventState.LOCKED and not has_pending_life_event() and _week6_condition(event_id)
	if event_id == "village_life_expands_001":
		return event != null and event.state == LifeEventState.LOCKED \
			and not has_pending_life_event() and _can_trigger_finale()
	return event != null and event.state == LifeEventState.LOCKED and not has_pending_life_event() \
		and (_growth == null or not _growth.has_pending_growth_event()) \
		and (_village_events == null or not _village_events.has_pending_event()) \
		and _inventory != null and _inventory.get_total_obtained(event.item_id) >= event.required_total_obtained

func create_pending_life_event(event_id: String) -> LifeEventData:
	if not can_trigger_life_event(event_id): return null
	var event := _events[event_id] as LifeEventData; event.state = LifeEventState.PENDING
	event.triggered_at = TimeManager.get_now(); _pending_event_id = event_id
	life_event_triggered.emit(event); return event

func has_pending_life_event() -> bool: return not _pending_event_id.is_empty()
func get_pending_life_event() -> LifeEventData: return _events.get(_pending_event_id) as LifeEventData

func confirm_life_event(event_id: String) -> LifeEventResult:
	if event_id != _pending_event_id: return null
	var event := _events[event_id] as LifeEventData; event.state = LifeEventState.COMPLETED
	event.confirmed_at = TimeManager.get_now(); _pending_event_id = ""
	var result := LifeEventResult.new(); result.event_id = event_id
	result.confirmed_at = event.confirmed_at; result.is_applied = true
	life_event_confirmed.emit(result)
	if _shop != null: _shop.refresh_product_unlocks(0, get_completed_event_ids())
	# 已達標的其他生活事件會在目前確認流程結束後依序排入，不必等待下一次物品變動。
	call_deferred("check_life_events")
	return result

func has_completed_life_event(event_id: String) -> bool:
	var event := _events.get(event_id) as LifeEventData
	return event != null and event.state == LifeEventState.COMPLETED

func get_completed_event_ids() -> Array[String]:
	var result: Array[String] = []
	for event: LifeEventData in _events.values():
		if event.state == LifeEventState.COMPLETED: result.append(event.event_id)
	return result

func _week6_condition(event_id: String) -> bool:
	if _shop == null or _cooking == null or _life_locations == null or _food == null: return false
	match event_id:
		"shop_first_purchase_001": return _shop.get_total_purchase_count() >= 1
		"shop_regular_customer_001": return _shop.get_total_purchase_count() >= 5
		"shop_big_spender_001": return _shop.get_total_spent() >= 100
		"shop_daily_browser_001": return _shop.get_visited_shop_day_count() >= 3
		"shop_all_foods_discovered_001": return _shop.get_discovered_shop_item_count() >= 4
		"cooking_first_dish_001": return _cooking.get_discovered_recipe_count() >= 1
		"cooking_variety_001": return _cooking.get_discovered_recipe_count() >= 3
		"picnic_first_visit_001": return _life_locations.get_completed_activity_count() >= 1
		"picnic_slow_day_001": return _life_locations.get_completed_activity_count() >= 5
		"village_daily_life_001":
			return _shop.get_total_purchase_count() >= 10 and _shop.get_total_spent() >= 100 \
				and _shop.get_discovered_shop_item_count() >= 4 and _cooking.get_discovered_recipe_count() >= 3 \
				and _food.get_used_food_count() >= 4 and _life_locations.get_completed_activity_count() >= 5 \
				and _shop.get_visited_shop_day_count() >= 3 and _has_completed_event_prefix("shop_") \
				and _has_completed_event_prefix("cooking_") and _has_completed_event_prefix("picnic_")
	return false

func _has_completed_event_prefix(prefix: String) -> bool:
	for event: LifeEventData in _events.values():
		if event.event_id.begins_with(prefix) and event.state == LifeEventState.COMPLETED: return true
	return false

func _can_trigger_finale() -> bool:
	if _inventory == null or _growth == null:
		return false
	var discovered_count := 0
	for entry: InventoryEntry in _inventory.get_all_items():
		if entry.total_obtained > 0:
			discovered_count += 1
	var runtime := get_parent()
	if runtime == null:
		return false
	var currency: Variant = runtime.get("currency_manager")
	if not (currency is CurrencyManager):
		return false
	var has_week5_growth := _growth.has_growth_mark("sprout_mark") or _growth.has_growth_mark("lake_interest")
	return _get_successful_food_use_count(runtime) >= 3 and discovered_count >= 4 \
		and currency.get_coin_amount() >= 30 and has_week5_growth

func _get_successful_food_use_count(runtime: Node) -> int:
	var save: Variant = runtime.get("save_manager")
	if save is SaveManager:
		var history: LifeHistoryManager = save.get_life_history_manager()
		if history != null:
			return history.food_use_history_to_array().size()
	var food: Variant = runtime.get("food_manager")
	return food.get_successful_food_use_count() if food is FoodManager else 0
