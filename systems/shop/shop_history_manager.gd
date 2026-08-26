class_name ShopHistoryManager
extends Node

signal history_changed

const VALID_PRODUCT_IDS := ["carrot", "apple", "bread", "berry_juice", "small_snack"]

var _purchase_history: Array[PurchaseHistoryEntry] = []
var _daily_shop_history: Dictionary = {}
var _product_unlock_history: Dictionary = {}
var _shop_event_history: Dictionary = {}

func setup(
	purchase_history: Array = [],
	daily_shop_history: Array = [],
	product_unlock_history: Array = [],
	shop_event_history: Array = []
) -> void:
	_purchase_history.clear()
	_daily_shop_history.clear()
	_product_unlock_history.clear()
	_shop_event_history.clear()

	var seen_purchase := {}
	for raw: Variant in purchase_history:
		if not (raw is Dictionary):
			continue
		var entry := PurchaseHistoryEntry.from_dict(raw)
		if entry.purchase_record_id.is_empty() or not VALID_PRODUCT_IDS.has(entry.product_id) or seen_purchase.has(entry.purchase_record_id):
			continue
		seen_purchase[entry.purchase_record_id] = true
		_purchase_history.append(entry)

	for raw: Variant in daily_shop_history:
		if not (raw is Dictionary):
			continue
		var entry := DailyShopHistoryEntry.from_dict(raw)
		if entry.day_key.is_empty():
			continue
		entry.offers = _sanitize_offers(entry.offers)
		entry.purchase_counts = _sanitize_purchase_counts(entry.purchase_counts)
		if not _daily_shop_history.has(entry.day_key):
			_daily_shop_history[entry.day_key] = entry
		else:
			_merge_daily_entry(_daily_shop_history[entry.day_key] as DailyShopHistoryEntry, entry)

	for raw: Variant in product_unlock_history:
		if not (raw is Dictionary):
			continue
		var entry := ProductUnlockHistoryEntry.from_dict(raw)
		if not VALID_PRODUCT_IDS.has(entry.product_id):
			continue
		var current := _product_unlock_history.get(entry.product_id) as ProductUnlockHistoryEntry
		if current == null or _is_earlier(entry.unlocked_at, current.unlocked_at):
			_product_unlock_history[entry.product_id] = entry

	for raw: Variant in shop_event_history:
		if not (raw is Dictionary):
			continue
		var entry := ShopEventHistoryEntry.from_dict(raw)
		if entry.shop_event_id.is_empty() or not entry.shop_event_id.begins_with("shop_"):
			continue
		if not _shop_event_history.has(entry.shop_event_id):
			_shop_event_history[entry.shop_event_id] = entry
	history_changed.emit()

func record_purchase(result: PurchaseResult) -> PurchaseHistoryEntry:
	if result == null or not result.success or result.purchase_record_id.is_empty() or not VALID_PRODUCT_IDS.has(result.product_id):
		return null
	var existing := get_purchase(result.purchase_record_id)
	if existing != null:
		return existing
	var entry := PurchaseHistoryEntry.new()
	entry.purchase_record_id = result.purchase_record_id
	entry.product_id = result.product_id
	entry.item_id = result.item_id
	entry.quantity = maxi(0, result.quantity)
	entry.unit_price = maxi(0, result.unit_price)
	entry.total_price = maxi(0, result.total_price)
	entry.purchased_at = maxf(0.0, result.purchased_at)
	entry.date_key = _date_key(entry.purchased_at)
	_purchase_history.append(entry)
	record_daily_purchase(entry.date_key, entry.product_id, entry.quantity)
	history_changed.emit()
	return entry

func record_daily_refresh(day_key: String, offers: Array[DailyShopOfferData], refreshed_at: float = -1.0) -> DailyShopHistoryEntry:
	if day_key.is_empty():
		return null
	var entry := get_daily_history(day_key)
	if entry == null:
		entry = DailyShopHistoryEntry.new()
		entry.day_key = day_key
		_daily_shop_history[day_key] = entry
	entry.offers.clear()
	var seen := {}
	for offer: DailyShopOfferData in offers:
		if offer == null or not VALID_PRODUCT_IDS.has(offer.product_id) or seen.has(offer.product_id):
			continue
		seen[offer.product_id] = true
		entry.offers.append(offer.to_dict())
	entry.refreshed_at = TimeManager.get_now() if refreshed_at <= 0.0 else refreshed_at
	entry.refresh_count = maxi(1, entry.refresh_count + 1)
	history_changed.emit()
	return entry

func record_daily_state(day_key: String, raw_offers: Array, purchase_counts: Dictionary, refreshed_at: float = -1.0) -> DailyShopHistoryEntry:
	if day_key.is_empty():
		return null
	var entry := get_daily_history(day_key)
	if entry == null:
		entry = DailyShopHistoryEntry.new()
		entry.day_key = day_key
		_daily_shop_history[day_key] = entry
	entry.offers = _sanitize_offers(raw_offers)
	entry.purchase_counts = _sanitize_purchase_counts(purchase_counts)
	if entry.refreshed_at <= 0.0:
		entry.refreshed_at = TimeManager.get_now() if refreshed_at <= 0.0 else refreshed_at
	entry.refresh_count = maxi(1, entry.refresh_count)
	history_changed.emit()
	return entry

func record_daily_purchase(day_key: String, product_id: String, quantity: int) -> void:
	if day_key.is_empty() or not VALID_PRODUCT_IDS.has(product_id) or quantity <= 0:
		return
	var entry := get_daily_history(day_key)
	if entry == null:
		entry = DailyShopHistoryEntry.new()
		entry.day_key = day_key
		entry.refreshed_at = TimeManager.get_now()
		entry.refresh_count = 1
		_daily_shop_history[day_key] = entry
	entry.purchase_counts[product_id] = int(entry.purchase_counts.get(product_id, 0)) + quantity
	history_changed.emit()

func record_product_unlock(product: ShopProductData, source_type := "", source_id := "") -> ProductUnlockHistoryEntry:
	if product == null or not VALID_PRODUCT_IDS.has(product.product_id):
		return null
	var existing := get_product_unlock(product.product_id)
	if existing != null:
		return existing
	var entry := ProductUnlockHistoryEntry.new()
	entry.product_id = product.product_id
	entry.unlocked_at = TimeManager.get_now() if product.unlocked_at <= 0.0 else product.unlocked_at
	entry.source_type = source_type
	entry.source_id = source_id
	_product_unlock_history[entry.product_id] = entry
	history_changed.emit()
	return entry

func record_product_unlock_values(product_id: String, unlocked_at: float, source_type: String, source_id: String) -> ProductUnlockHistoryEntry:
	if not VALID_PRODUCT_IDS.has(product_id):
		return null
	var existing := get_product_unlock(product_id)
	if existing != null:
		return existing
	var entry := ProductUnlockHistoryEntry.new()
	entry.product_id = product_id
	entry.unlocked_at = TimeManager.get_now() if unlocked_at <= 0.0 else unlocked_at
	entry.source_type = source_type
	entry.source_id = source_id
	_product_unlock_history[product_id] = entry
	history_changed.emit()
	return entry

func record_shop_event(event_id: String, confirmed_at: float) -> ShopEventHistoryEntry:
	if event_id.is_empty() or not event_id.begins_with("shop_"):
		return null
	var existing := _shop_event_history.get(event_id) as ShopEventHistoryEntry
	if existing != null:
		return existing
	var entry := ShopEventHistoryEntry.new()
	entry.shop_event_id = event_id
	entry.history_id = "shop_event_%s" % event_id
	entry.confirmed_at = TimeManager.get_now() if confirmed_at <= 0.0 else confirmed_at
	_shop_event_history[event_id] = entry
	history_changed.emit()
	return entry

func has_purchase(record_id: String) -> bool:
	return get_purchase(record_id) != null

func get_purchase(record_id: String) -> PurchaseHistoryEntry:
	for entry: PurchaseHistoryEntry in _purchase_history:
		if entry.purchase_record_id == record_id:
			return entry
	return null

func get_purchase_count() -> int:
	return _purchase_history.size()

func get_daily_history(day_key: String) -> DailyShopHistoryEntry:
	return _daily_shop_history.get(day_key) as DailyShopHistoryEntry

func get_product_unlock(product_id: String) -> ProductUnlockHistoryEntry:
	return _product_unlock_history.get(product_id) as ProductUnlockHistoryEntry

func has_shop_event(event_id: String) -> bool:
	return _shop_event_history.has(event_id)

func purchase_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: PurchaseHistoryEntry in _purchase_history:
		result.append(entry.to_dict())
	return result

func daily_shop_history_to_array() -> Array[Dictionary]:
	var keys := _daily_shop_history.keys()
	keys.sort()
	var result: Array[Dictionary] = []
	for key: Variant in keys:
		var entry := _daily_shop_history[key] as DailyShopHistoryEntry
		if entry != null:
			result.append(entry.to_dict())
	return result

func product_unlock_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: ProductUnlockHistoryEntry in _product_unlock_history.values():
		result.append(entry.to_dict())
	return result

func shop_event_history_to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: ShopEventHistoryEntry in _shop_event_history.values():
		result.append(entry.to_dict())
	return result

func _sanitize_offers(source: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	for raw: Variant in source:
		if not (raw is Dictionary):
			continue
		var product_id := str(raw.get("product_id", ""))
		if not VALID_PRODUCT_IDS.has(product_id) or seen.has(product_id):
			continue
		seen[product_id] = true
		var offer := DailyShopOfferData.from_dict(raw)
		result.append(offer.to_dict())
	return result

func _sanitize_purchase_counts(source: Dictionary) -> Dictionary:
	var result := {}
	for raw_id: Variant in source.keys():
		var product_id := str(raw_id)
		if VALID_PRODUCT_IDS.has(product_id):
			result[product_id] = maxi(0, int(source[raw_id]))
	return result

func _merge_daily_entry(current: DailyShopHistoryEntry, incoming: DailyShopHistoryEntry) -> void:
	if current == null or incoming == null:
		return
	if incoming.offers.size() > current.offers.size():
		current.offers = incoming.offers.duplicate(true)
	current.refreshed_at = maxf(current.refreshed_at, incoming.refreshed_at)
	current.refresh_count = maxi(current.refresh_count, incoming.refresh_count)
	for product_id: String in incoming.purchase_counts:
		current.purchase_counts[product_id] = maxi(int(current.purchase_counts.get(product_id, 0)), int(incoming.purchase_counts[product_id]))

func _is_earlier(candidate: float, current: float) -> bool:
	if current <= 0.0:
		return candidate > 0.0
	if candidate <= 0.0:
		return false
	return candidate < current

func _date_key(timestamp: float) -> String:
	if timestamp <= 0.0:
		return ""
	var date := TimeManager.get_local_datetime(timestamp)
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]
