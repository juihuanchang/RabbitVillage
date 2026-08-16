class_name ResourceHistoryManager
extends Node

signal history_changed

const VALID_ITEM_IDS := ["carrot", "leaf", "twig", "small_stone", "driftwood"]

var _inventory_history: Array[InventoryHistoryEntry] = []
var _currency_history: Array[CurrencyHistoryEntry] = []
var _reward_history: Array[RewardHistoryEntry] = []
var _item_discovery_history: Array[ItemDiscoveryHistoryEntry] = []

func setup(
	inventory_history: Array = [],
	currency_history: Array = [],
	reward_history: Array = [],
	item_discovery_history: Array = []
) -> void:
	_inventory_history.clear()
	_currency_history.clear()
	_reward_history.clear()
	_item_discovery_history.clear()

	for raw: Variant in inventory_history:
		if raw is Dictionary:
			var entry := InventoryHistoryEntry.from_dict(raw)
			if VALID_ITEM_IDS.has(entry.item_id) and not _has_inventory_history_id(entry.inventory_history_id):
				_inventory_history.append(entry)

	for raw: Variant in currency_history:
		if raw is Dictionary:
			var entry := CurrencyHistoryEntry.from_dict(raw)
			if entry.currency_id == "coin" and not _has_currency_history_id(entry.currency_history_id):
				_currency_history.append(entry)

	for raw: Variant in reward_history:
		if raw is Dictionary:
			var entry := RewardHistoryEntry.from_dict(raw)
			if entry.reward_record_id.is_empty() or entry.activity_record_id.is_empty():
				continue
			if has_reward_history(entry.activity_record_id) or _has_reward_record_id(entry.reward_record_id):
				continue
			_reward_history.append(entry)

	for raw: Variant in item_discovery_history:
		if raw is Dictionary:
			var entry := ItemDiscoveryHistoryEntry.from_dict(raw)
			if not VALID_ITEM_IDS.has(entry.item_id) or has_item_discovery_history(entry.item_id):
				continue
			_item_discovery_history.append(entry)

	history_changed.emit()

func record_inventory_change(
	item_id: String,
	amount_before: int,
	amount_change: int,
	amount_after: int,
	source_type: String,
	source_id: String,
	created_at: float = -1.0
) -> InventoryHistoryEntry:
	if not VALID_ITEM_IDS.has(item_id):
		return null
	if not source_id.is_empty() and has_inventory_history_for_source(item_id, source_type, source_id):
		return get_inventory_history_for_source(item_id, source_type, source_id)
	var entry := InventoryHistoryEntry.new()
	entry.created_at = TimeManager.get_now() if created_at <= 0.0 else created_at
	entry.inventory_history_id = _make_id("inventory", entry.created_at, _inventory_history.size())
	entry.item_id = item_id
	entry.amount_before = maxi(0, amount_before)
	entry.amount_after = maxi(0, amount_after)
	entry.amount_change = amount_change
	entry.source_type = source_type
	entry.source_id = source_id
	_inventory_history.append(entry)
	history_changed.emit()
	return entry

func record_currency_change(
	currency_id: String,
	amount_before: int,
	amount_change: int,
	amount_after: int,
	source_type: String,
	source_id: String,
	created_at: float = -1.0
) -> CurrencyHistoryEntry:
	if currency_id != "coin":
		return null
	if not source_id.is_empty() and has_currency_history_for_source(currency_id, source_type, source_id):
		return get_currency_history_for_source(currency_id, source_type, source_id)
	var entry := CurrencyHistoryEntry.new()
	entry.created_at = TimeManager.get_now() if created_at <= 0.0 else created_at
	entry.currency_history_id = _make_id("currency", entry.created_at, _currency_history.size())
	entry.currency_id = currency_id
	entry.amount_before = maxi(0, amount_before)
	entry.amount_after = maxi(0, amount_after)
	entry.amount_change = amount_change
	entry.source_type = source_type
	entry.source_id = source_id
	_currency_history.append(entry)
	history_changed.emit()
	return entry

func record_reward(result: RewardResult) -> RewardHistoryEntry:
	if result == null or result.reward_record_id.is_empty() or result.activity_record_id.is_empty():
		return null
	var existing := get_reward_history(result.activity_record_id)
	if existing != null:
		return existing
	if _has_reward_record_id(result.reward_record_id):
		return null
	var entry := RewardHistoryEntry.new()
	entry.reward_record_id = result.reward_record_id
	entry.activity_record_id = result.activity_record_id
	entry.activity_id = result.activity_id
	entry.coin_reward = maxi(0, result.coin_reward)
	for raw_id: Variant in result.item_rewards.keys():
		var item_id := str(raw_id)
		var amount := maxi(0, int(result.item_rewards[raw_id]))
		if VALID_ITEM_IDS.has(item_id) and amount > 0:
			entry.item_rewards[item_id] = amount
	entry.generated_at = maxf(0.0, result.generated_at)
	entry.applied_at = maxf(0.0, result.applied_at)
	entry.is_applied = result.is_applied
	_reward_history.append(entry)
	history_changed.emit()
	return entry

func record_item_discovery(
	item_id: String,
	discovered_at: float,
	source_type: String,
	source_id: String
) -> ItemDiscoveryHistoryEntry:
	if not VALID_ITEM_IDS.has(item_id):
		return null
	var existing := get_item_discovery_history(item_id)
	if existing != null:
		return existing
	var entry := ItemDiscoveryHistoryEntry.new()
	entry.item_id = item_id
	entry.discovered_at = TimeManager.get_now() if discovered_at <= 0.0 else discovered_at
	entry.discovery_id = _make_id("discovery_%s" % item_id, entry.discovered_at, _item_discovery_history.size())
	entry.source_type = source_type
	entry.source_id = source_id
	_item_discovery_history.append(entry)
	history_changed.emit()
	return entry

func has_reward_history(activity_record_id: String) -> bool:
	return get_reward_history(activity_record_id) != null

func get_reward_history(activity_record_id: String) -> RewardHistoryEntry:
	for entry: RewardHistoryEntry in _reward_history:
		if not activity_record_id.is_empty() and entry.activity_record_id == activity_record_id:
			return entry
	return null

func has_item_discovery_history(item_id: String) -> bool:
	return get_item_discovery_history(item_id) != null

func get_item_discovery_history(item_id: String) -> ItemDiscoveryHistoryEntry:
	for entry: ItemDiscoveryHistoryEntry in _item_discovery_history:
		if entry.item_id == item_id:
			return entry
	return null

func has_inventory_history_for_source(item_id: String, source_type: String, source_id: String) -> bool:
	return get_inventory_history_for_source(item_id, source_type, source_id) != null

func get_inventory_history_for_source(item_id: String, source_type: String, source_id: String) -> InventoryHistoryEntry:
	for entry: InventoryHistoryEntry in _inventory_history:
		if entry.item_id == item_id and entry.source_type == source_type and entry.source_id == source_id:
			return entry
	return null

func has_currency_history_for_source(currency_id: String, source_type: String, source_id: String) -> bool:
	return get_currency_history_for_source(currency_id, source_type, source_id) != null

func get_currency_history_for_source(currency_id: String, source_type: String, source_id: String) -> CurrencyHistoryEntry:
	for entry: CurrencyHistoryEntry in _currency_history:
		if entry.currency_id == currency_id and entry.source_type == source_type and entry.source_id == source_id:
			return entry
	return null

func get_inventory_history() -> Array[InventoryHistoryEntry]:
	var result: Array[InventoryHistoryEntry] = []
	result.assign(_inventory_history)
	return result

func get_currency_history() -> Array[CurrencyHistoryEntry]:
	var result: Array[CurrencyHistoryEntry] = []
	result.assign(_currency_history)
	return result

func get_reward_history_entries() -> Array[RewardHistoryEntry]:
	var result: Array[RewardHistoryEntry] = []
	result.assign(_reward_history)
	return result

func get_item_discovery_history_entries() -> Array[ItemDiscoveryHistoryEntry]:
	var result: Array[ItemDiscoveryHistoryEntry] = []
	result.assign(_item_discovery_history)
	return result

func inventory_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: InventoryHistoryEntry in _inventory_history:
		result.append(entry.to_dict())
	return result

func currency_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: CurrencyHistoryEntry in _currency_history:
		result.append(entry.to_dict())
	return result

func reward_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: RewardHistoryEntry in _reward_history:
		result.append(entry.to_dict())
	return result

func item_discovery_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: ItemDiscoveryHistoryEntry in _item_discovery_history:
		result.append(entry.to_dict())
	return result

func _has_inventory_history_id(history_id: String) -> bool:
	if history_id.is_empty():
		return false
	for entry: InventoryHistoryEntry in _inventory_history:
		if entry.inventory_history_id == history_id:
			return true
	return false

func _has_currency_history_id(history_id: String) -> bool:
	if history_id.is_empty():
		return false
	for entry: CurrencyHistoryEntry in _currency_history:
		if entry.currency_history_id == history_id:
			return true
	return false

func _has_reward_record_id(reward_record_id: String) -> bool:
	if reward_record_id.is_empty():
		return false
	for entry: RewardHistoryEntry in _reward_history:
		if entry.reward_record_id == reward_record_id:
			return true
	return false

func _make_id(prefix: String, at: float, serial: int) -> String:
	return "%s_%d_%03d" % [prefix, int(at * 1000.0), serial + 1]
