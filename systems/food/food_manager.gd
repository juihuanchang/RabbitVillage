class_name FoodManager
extends Node

signal food_use_completed(result: FoodUseResult)

const CARROT_HUNGER_GAIN := 8
var _inventory: InventoryManager
var _rabbit: RabbitData
var _activities: ActivityManager
var _life_events: LifeEventManager
var _growth: GrowthManager
var _village_events: VillageEventManager
var _last_result: FoodUseResult
var _used_food_ids: Dictionary = {}
var _successful_food_use_count := 0
var _is_rest_pavilion_in_use: Callable

func setup(inventory: InventoryManager, rabbit: RabbitData, activities: ActivityManager = null, life_events: LifeEventManager = null, growth: GrowthManager = null, village_events: VillageEventManager = null) -> void:
	_inventory = inventory; _rabbit = rabbit; _activities = activities; _life_events = life_events
	_growth = growth; _village_events = village_events

## 可由 Runtime 注入休息亭查詢，不讓 FoodManager 依賴特定建築實作。
func set_rest_pavilion_state_provider(provider: Callable) -> void:
	_is_rest_pavilion_in_use = provider

func can_eat_carrot() -> bool:
	return _inventory != null and _rabbit != null and not _rabbit.is_away and _inventory.has_item("carrot") and _rabbit.hunger < 95 \
		and (_activities == null or not _activities.has_active_activity()) \
		and not _is_using_rest_pavilion() \
		and (_life_events == null or not _life_events.has_pending_life_event()) \
		and (_growth == null or not _growth.has_pending_growth_event()) \
		and (_village_events == null or not _village_events.has_pending_event())

func eat_carrot() -> FoodUseResult:
	if not can_eat_carrot(): return null
	var result := FoodUseResult.new(); result.used_at = TimeManager.get_now()
	result.food_use_record_id = "food_%d_%d" % [int(result.used_at * 1000000.0), randi_range(1000, 9999)]
	result.food_id = "carrot"; result.amount_used = 1; result.hunger_before = _rabbit.hunger
	result.is_first_use = not _used_food_ids.has(result.food_id)
	if not _inventory.remove_item("carrot", 1, "food_use", result.food_use_record_id): return null
	_rabbit.hunger += CARROT_HUNGER_GAIN; result.hunger_after = _rabbit.hunger
	result.hunger_change = result.hunger_after - result.hunger_before
	_used_food_ids[result.food_id] = true; _successful_food_use_count += 1
	_last_result = result; food_use_completed.emit(result)
	if _life_events != null: _life_events.check_life_events()
	return result

func get_carrot_amount() -> int: return _inventory.get_item_amount("carrot") if _inventory != null else 0
func get_last_food_use_result() -> FoodUseResult: return _last_result
func get_successful_food_use_count() -> int: return _successful_food_use_count
func restore_successful_food_use_count(value: int) -> void: _successful_food_use_count = maxi(0, value)

func _is_using_rest_pavilion() -> bool:
	if _is_rest_pavilion_in_use.is_valid():
		return bool(_is_rest_pavilion_in_use.call())
	var runtime := get_parent()
	if runtime != null:
		var manager: Variant = runtime.get("building_interaction_manager")
		if manager is BuildingInteractionManager:
			return manager.is_rest_pavilion_in_use()
	return false
