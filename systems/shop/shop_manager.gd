class_name ShopManager
extends Node

signal purchase_completed(result: PurchaseResult)
signal product_unlocked(product: ShopProductData)

var catalog := ShopCatalogData.new()
var state := ShopStateData.new()
var _inventory: InventoryManager
var _currency: CurrencyManager
var _daily: DailyShopManager
var _transactions: Dictionary = {}

func _init() -> void:
	_add_product("carrot", "carrot", "Carrot", 4, ProductUnlockConditionData.create("shop_open"))
	_add_product("apple", "apple", "Apple", 6, ProductUnlockConditionData.create("shop_open"))
	_add_product("bread", "bread", "Bread", 8, ProductUnlockConditionData.create("purchase_count", "", 2))
	_add_product("berry_juice", "berry_juice", "Berry Juice", 12, ProductUnlockConditionData.create("mood_progress", "", 60))
	_add_product("small_snack", "small_snack", "Small Snack", 10, ProductUnlockConditionData.create("life_event", "shop_first_purchase_001"))

func _add_product(id: String, item_id: String, name: String, price: int, condition: ProductUnlockConditionData) -> void:
	var product := ShopProductData.new(); product.product_id = id; product.item_id = item_id
	product.display_name = name; product.base_price = price; product.unlock_condition = condition; catalog.products.append(product)

func setup(inventory: InventoryManager, currency: CurrencyManager, daily: DailyShopManager, saved_state: Dictionary = {}) -> void:
	_inventory = inventory; _currency = currency; _daily = daily
	state = ShopStateData.from_dict(saved_state) if not saved_state.is_empty() else ShopStateData.new()
	for product: ShopProductData in catalog.products:
		if state.unlocked_product_ids.has(product.product_id): product.unlock_state = ShopProductData.UNLOCKED
	refresh_product_unlocks()
	_daily.setup(catalog, state.to_dict()); state = _daily.state

func get_catalog() -> ShopCatalogData: return catalog
func get_product(product_id: String) -> ShopProductData: return catalog.get_product(product_id)
func is_product_unlocked(product_id: String) -> bool:
	var product := get_product(product_id); return product != null and product.unlock_state == ShopProductData.UNLOCKED

func refresh_product_unlocks(mood_progress := 0, completed_event_ids: Array[String] = []) -> void:
	for product: ShopProductData in catalog.products:
		if product.unlock_state == ShopProductData.UNLOCKED: continue
		var condition := product.unlock_condition; var unlock := condition.condition_type == "always" or condition.condition_type == "shop_open"
		if condition.condition_type == "purchase_count": unlock = state.total_purchase_count >= condition.required_value
		elif condition.condition_type == "mood_progress": unlock = mood_progress >= condition.required_value
		elif condition.condition_type == "life_event": unlock = completed_event_ids.has(condition.target_id)
		if unlock: _unlock_product(product)

func _unlock_product(product: ShopProductData) -> void:
	product.unlock_state = ShopProductData.UNLOCKED; product.unlocked_at = TimeManager.get_now()
	if not state.unlocked_product_ids.has(product.product_id): state.unlocked_product_ids.append(product.product_id)
	product_unlocked.emit(product)

func can_purchase(product_id: String, quantity: int) -> Dictionary:
	if quantity < 1 or quantity > 3: return {"success": false, "reason": "invalid_quantity"}
	var product := get_product(product_id)
	if product == null or not is_product_unlocked(product_id): return {"success": false, "reason": "product_locked"}
	if _daily == null or not _daily.has_offer(product_id): return {"success": false, "reason": "not_in_daily_offer"}
	if get_daily_remaining(product_id) < quantity: return {"success": false, "reason": "daily_limit"}
	var price := get_purchase_price(product_id, quantity)
	if _currency == null or not _currency.can_spend_coins(price): return {"success": false, "reason": "not_enough_coins"}
	return {"success": true, "reason": "", "price": price}

func purchase(product_id: String, quantity: int, purchase_record_id := "") -> PurchaseResult:
	var result := PurchaseResult.new(); result.product_id = product_id; result.quantity = quantity
	result.purchase_record_id = purchase_record_id if not purchase_record_id.is_empty() else _make_id("purchase")
	if state.applied_purchase_ids.has(result.purchase_record_id) or _transactions.has(result.purchase_record_id):
		result.reason = "duplicate_purchase"; return result
	var check := can_purchase(product_id, quantity)
	if not bool(check.success): result.reason = str(check.reason); return result
	var product := get_product(product_id); result.item_id = product.item_id
	result.unit_price = product.get_final_unit_price(); result.total_price = int(check.price); result.purchased_at = TimeManager.get_now()
	_transactions[result.purchase_record_id] = true
	if not _currency.spend_coins(result.total_price, "shop_purchase", result.purchase_record_id):
		_transactions.erase(result.purchase_record_id); result.reason = "spend_failed"; return result
	if not _inventory.add_item(result.item_id, quantity, "shop_purchase", result.purchase_record_id):
		_currency.rollback_spend(result.total_price, "shop_rollback", result.purchase_record_id)
		_transactions.erase(result.purchase_record_id); result.reason = "inventory_failed"; return result
	_daily.commit_purchase(product_id, quantity); state.applied_purchase_ids.append(result.purchase_record_id)
	state.total_purchase_count += 1; state.total_spent += result.total_price; _transactions.erase(result.purchase_record_id)
	result.success = true; refresh_product_unlocks(); purchase_completed.emit(result); return result

func get_daily_remaining(product_id: String) -> int:
	var product := get_product(product_id); return maxi(0, product.daily_purchase_limit - _daily.get_purchased_amount(product_id)) if product != null and _daily != null else 0
func get_purchase_price(product_id: String, quantity: int) -> int:
	var product := get_product(product_id); return product.get_final_unit_price() * quantity if product != null and quantity > 0 else 0
func _make_id(prefix: String) -> String: return "%s_%d_%d" % [prefix, int(TimeManager.get_now() * 1000000.0), randi_range(1000, 9999)]
func to_dict() -> Dictionary: return state.to_dict()
func get_total_purchase_count() -> int: return state.total_purchase_count
func get_total_spent() -> int: return state.total_spent
func get_visited_shop_day_count() -> int: return state.visited_day_keys.size()
func get_discovered_shop_item_count() -> int:
	var count := 0
	for product: ShopProductData in catalog.products:
		if _inventory != null and _inventory.is_item_discovered(product.item_id): count += 1
	return count
