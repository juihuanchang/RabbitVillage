class_name LifeEventManager
extends Node

signal life_event_triggered(event_data: LifeEventData)
signal life_event_confirmed(event_result: LifeEventResult)

var _inventory: InventoryManager
var _growth: GrowthManager
var _village_events: VillageEventManager
var _events: Dictionary = {}
var _pending_event_id := ""

func _init() -> void:
	_register_event("life_leaf_collection_001", "leaf", 15)
	_register_event("life_twig_collection_001", "twig", 10)
	_register_event("life_stone_collection_001", "small_stone", 6)
	_register_event("life_driftwood_collection_001", "driftwood", 5)
	_register_event("village_life_expands_001", "", 0)

func setup(inventory: InventoryManager, growth: GrowthManager = null, village_events: VillageEventManager = null) -> void:
	_inventory = inventory; _growth = growth; _village_events = village_events

func _register_event(event_id: String, item_id: String, required_amount: int) -> void:
	var event := LifeEventData.new(); event.event_id = event_id; event.item_id = item_id
	event.required_total_obtained = required_amount; _events[event_id] = event

func check_life_events() -> LifeEventData:
	if has_pending_life_event(): return get_pending_life_event()
	for event: LifeEventData in _events.values():
		if can_trigger_life_event(event.event_id): return create_pending_life_event(event.event_id)
	return null

func can_trigger_life_event(event_id: String) -> bool:
	var event := _events.get(event_id) as LifeEventData
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
	life_event_confirmed.emit(result); return result

func has_completed_life_event(event_id: String) -> bool:
	var event := _events.get(event_id) as LifeEventData
	return event != null and event.state == LifeEventState.COMPLETED

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
