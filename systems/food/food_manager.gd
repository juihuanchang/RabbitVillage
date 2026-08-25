class_name FoodManager
extends Node

signal food_use_completed(result: FoodUseResult)
signal food_used(result: FoodUseResult)

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
var _effects: Dictionary = {}

func _init() -> void:
	_register_effect(FoodEffectData.create("carrot", 8))
	_register_effect(FoodEffectData.create("apple", 10, 0, 2))
	_register_effect(FoodEffectData.create("bread", 12, 2, 0))
	_register_effect(FoodEffectData.create("berry_juice", 6, 2, 8))
	_register_effect(FoodEffectData.create("small_snack", 10, 3, 3))
	_register_effect(FoodEffectData.create("carrot_sandwich", 25, 5, 0))
	_register_effect(FoodEffectData.create("forest_salad", 15, 0, 8))
	_register_effect(FoodEffectData.create("berry_toast", 20, 0, 10))
	_register_effect(FoodEffectData.create("picnic_snack", 18, 6, 8))

func _register_effect(effect: FoodEffectData) -> void: _effects[effect.item_id] = effect

func setup(inventory: InventoryManager, rabbit: RabbitData, activities: ActivityManager = null, life_events: LifeEventManager = null, growth: GrowthManager = null, village_events: VillageEventManager = null) -> void:
	_inventory = inventory; _rabbit = rabbit; _activities = activities; _life_events = life_events
	_growth = growth; _village_events = village_events

## 可由 Runtime 注入休息亭查詢，不讓 FoodManager 依賴特定建築實作。
func set_rest_pavilion_state_provider(provider: Callable) -> void:
	_is_rest_pavilion_in_use = provider

func can_eat_carrot() -> bool:
	return _rabbit != null and _rabbit.hunger < 95 and can_use_food("carrot")

func can_use_food(item_id: String) -> bool:
	var effect := _effects.get(item_id) as FoodEffectData
	return effect != null and _inventory != null and _rabbit != null and not _rabbit.is_away and _inventory.has_item(item_id) \
		and (_activities == null or not _activities.has_active_activity()) \
		and not _is_using_rest_pavilion() \
		and (_life_events == null or not _life_events.has_pending_life_event()) \
		and (_growth == null or not _growth.has_pending_growth_event()) \
		and (_village_events == null or not _village_events.has_pending_event()) \
		and _has_effective_change(effect)

func _has_effective_change(effect: FoodEffectData) -> bool:
	return (effect.hunger_change > 0 and _rabbit.hunger < 100) or (effect.energy_change > 0 and _rabbit.energy < 100) \
		or (effect.mood_change > 0 and _rabbit.mood < 100)

func eat_carrot() -> FoodUseResult:
	return use_food("carrot") if can_eat_carrot() else null

func use_food(item_id: String) -> FoodUseResult:
	if not can_use_food(item_id): return null
	var effect := _effects[item_id] as FoodEffectData
	var result := FoodUseResult.new(); result.used_at = TimeManager.get_now()
	result.food_use_record_id = "food_%d_%d" % [int(result.used_at * 1000000.0), randi_range(1000, 9999)]
	result.food_id = item_id; result.amount_used = 1; result.hunger_before = _rabbit.hunger
	result.energy_before = _rabbit.energy; result.mood_before = _rabbit.mood
	result.is_first_use = not _used_food_ids.has(result.food_id)
	if not _inventory.remove_item(item_id, 1, "food_use", result.food_use_record_id): return null
	_rabbit.hunger += effect.hunger_change; _rabbit.energy += effect.energy_change; _rabbit.mood += effect.mood_change
	result.hunger_after = _rabbit.hunger; result.energy_after = _rabbit.energy; result.mood_after = _rabbit.mood
	result.hunger_change = result.hunger_after - result.hunger_before
	result.energy_change = result.energy_after - result.energy_before; result.mood_change = result.mood_after - result.mood_before
	_used_food_ids[result.food_id] = true; _successful_food_use_count += 1
	_last_result = result; food_use_completed.emit(result); food_used.emit(result)
	if _life_events != null: _life_events.check_life_events()
	return result

func get_carrot_amount() -> int: return _inventory.get_item_amount("carrot") if _inventory != null else 0
func get_last_food_use_result() -> FoodUseResult: return _last_result
func get_successful_food_use_count() -> int: return _successful_food_use_count
func restore_successful_food_use_count(value: int) -> void: _successful_food_use_count = maxi(0, value)
func get_used_food_count() -> int: return _used_food_ids.size()
func restore_used_food_ids(ids: Array) -> void:
	_used_food_ids.clear()
	for id: Variant in ids: _used_food_ids[str(id)] = true
func to_dict() -> Dictionary:
	return {"successful_food_use_count": _successful_food_use_count, "used_food_ids": _used_food_ids.keys()}

func _is_using_rest_pavilion() -> bool:
	if _is_rest_pavilion_in_use.is_valid():
		return bool(_is_rest_pavilion_in_use.call())
	var runtime := get_parent()
	if runtime != null:
		var manager: Variant = runtime.get("building_interaction_manager")
		if manager is BuildingInteractionManager:
			return manager.is_rest_pavilion_in_use()
	return false
