class_name DailyShopManager
extends Node

signal daily_shop_refreshed(day_key: String, offers: Array[DailyShopOfferData])

var state := ShopStateData.new()
var _catalog: ShopCatalogData
var _day_key_provider: Callable

func setup(catalog: ShopCatalogData, saved_state: Dictionary = {}) -> void:
	_catalog = catalog; state = ShopStateData.from_dict(saved_state) if not saved_state.is_empty() else ShopStateData.new()
	refresh_if_needed()

func set_day_key_provider(provider: Callable) -> void: _day_key_provider = provider
func get_current_day_key() -> String:
	return str(_day_key_provider.call()) if _day_key_provider.is_valid() else Time.get_date_string_from_system()

func should_refresh() -> bool: return state.day_key != get_current_day_key() or state.daily_offers.is_empty()

func refresh_if_needed() -> bool:
	if not should_refresh(): return false
	generate_daily_offers(); return true

func generate_daily_offers() -> Array[DailyShopOfferData]:
	var day_key := get_current_day_key(); var candidates: Array[ShopProductData] = []
	if _catalog != null:
		for product: ShopProductData in _catalog.products:
			if product.unlock_state == ShopProductData.UNLOCKED: candidates.append(product)
	var rng := RandomNumberGenerator.new(); rng.seed = hash(day_key)
	for index: int in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index); var value := candidates[index]
		candidates[index] = candidates[swap_index]; candidates[swap_index] = value
	var offer_count := mini(candidates.size(), rng.randi_range(2, 4)) if candidates.size() >= 2 else candidates.size()
	state.day_key = day_key; state.daily_offers.clear(); state.daily_purchase_amounts.clear()
	if not state.visited_day_keys.has(day_key): state.visited_day_keys.append(day_key)
	var result: Array[DailyShopOfferData] = []
	for index: int in offer_count:
		var product := candidates[index]; var offer := DailyShopOfferData.new()
		offer.product_id = product.product_id; offer.day_key = day_key
		offer.final_price = product.get_final_unit_price(); offer.daily_limit = product.daily_purchase_limit
		state.daily_offers.append(offer.to_dict()); result.append(offer)
	daily_shop_refreshed.emit(day_key, result); return result

func get_daily_offers() -> Array[DailyShopOfferData]:
	refresh_if_needed(); var result: Array[DailyShopOfferData] = []
	for raw: Dictionary in state.daily_offers: result.append(DailyShopOfferData.from_dict(raw))
	return result

func has_offer(product_id: String) -> bool:
	for offer: DailyShopOfferData in get_daily_offers():
		if offer.product_id == product_id: return true
	return false

func get_purchased_amount(product_id: String) -> int: return int(state.daily_purchase_amounts.get(product_id, 0))
func commit_purchase(product_id: String, quantity: int) -> void:
	state.daily_purchase_amounts[product_id] = get_purchased_amount(product_id) + quantity
func to_dict() -> Dictionary: return state.to_dict()
