class_name RewardManager
extends Node

signal activity_reward_applied(result: RewardResult)

var _inventory: InventoryManager
var _currency: CurrencyManager
var _definitions: Dictionary = {}
var _results: Dictionary = {}

func _init() -> void:
	_add_definition("forest_walk", 3, [RewardItemData.create("leaf", 0.60), RewardItemData.create("twig", 0.35)])
	_add_definition("forest_explore", 8, [RewardItemData.create("leaf", 0.70, 1, 2), RewardItemData.create("twig", 0.60, 1, 2), RewardItemData.create("small_stone", 0.30)])
	_add_definition("fishing", 5, [RewardItemData.create("driftwood", 0.40)])
	_add_definition("home_rest", 0, [])

func setup(inventory: InventoryManager, currency: CurrencyManager) -> void:
	_inventory = inventory; _currency = currency

func _add_definition(activity_id: String, coins: int, random_items: Array) -> void:
	var definition := ActivityRewardData.new(); definition.activity_id = activity_id
	definition.coin_reward = coins; definition.random_items.assign(random_items); _definitions[activity_id] = definition

func generate_activity_reward(activity_id: String, activity_record_id: String) -> RewardResult:
	if activity_record_id.is_empty() or not _definitions.has(activity_id): return null
	if _results.has(activity_record_id): return _results[activity_record_id] as RewardResult
	var definition := _definitions[activity_id] as ActivityRewardData; var result := RewardResult.new()
	result.activity_id = activity_id; result.activity_record_id = activity_record_id
	result.reward_record_id = "reward_%s" % activity_record_id; result.coin_reward = definition.coin_reward
	result.generated_at = TimeManager.get_now()
	for item: RewardItemData in definition.guaranteed_items: _add_rolled_item(result, item)
	for item: RewardItemData in definition.random_items: _add_rolled_item(result, item)
	_results[activity_record_id] = result; return result

func _add_rolled_item(result: RewardResult, item: RewardItemData) -> void:
	var amount := item.roll_amount()
	if amount > 0: result.item_rewards[item.item_id] = int(result.item_rewards.get(item.item_id, 0)) + amount

func apply_activity_reward(result: RewardResult) -> bool:
	if result == null or result.is_applied or _inventory == null or _currency == null: return false
	var stored := _results.get(result.activity_record_id) as RewardResult
	if stored == null or stored != result or stored.is_applied: return false
	if result.coin_reward > 0: _currency.add_coins(result.coin_reward, "activity_reward", result.reward_record_id)
	for item_id: String in result.item_rewards:
		_inventory.add_item(item_id, int(result.item_rewards[item_id]), "activity_reward", result.reward_record_id)
	result.is_applied = true; result.applied_at = TimeManager.get_now()
	activity_reward_applied.emit(result); return true

func has_reward_been_applied(activity_record_id: String) -> bool:
	var result := _results.get(activity_record_id) as RewardResult
	return result != null and result.is_applied

func get_reward_result(activity_record_id: String) -> RewardResult:
	return _results.get(activity_record_id) as RewardResult
