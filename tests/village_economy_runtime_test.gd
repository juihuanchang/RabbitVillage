extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_test_shop_reload_and_cross_day()
	_test_cooking_atomic_and_replay()
	_test_generic_food_and_picnic()
	if failures.is_empty(): print("VILLAGE_ECONOMY_RUNTIME_TESTS_OK"); quit(0)
	else:
		for message: String in failures: push_error(message)
		quit(1)

func _expect(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _test_shop_reload_and_cross_day() -> void:
	var inventory := InventoryManager.new(); var currency := CurrencyManager.new(); currency.add_coins(200, "test", "seed")
	var day := ["2026-08-26"]
	var daily := DailyShopManager.new(); daily.set_day_key_provider(func() -> String: return day[0])
	var shop := ShopManager.new(); shop.setup(inventory, currency, daily)
	var offer_ids: Array[String] = []
	for offer: DailyShopOfferData in daily.get_daily_offers(): offer_ids.append(offer.product_id)
	var first := shop.purchase("apple", 1, "purchase_fixed_001")
	var coin_after_first := currency.get_coin_amount(); var apple_after_first := inventory.get_item_amount("apple")
	var duplicate := shop.purchase("apple", 1, "purchase_fixed_001")
	_expect(first.success and not duplicate.success, "Purchase replay must only succeed once")
	_expect(currency.get_coin_amount() == coin_after_first and inventory.get_item_amount("apple") == apple_after_first, "Duplicate purchase must change nothing")
	shop.purchase("apple", 1, "purchase_fixed_002")
	var food := FoodManager.new(); var rabbit := RabbitData.new(); food.setup(inventory, rabbit)
	var cooking := CookingManager.new(); cooking.setup(inventory)
	var locations := LifeLocationManager.new(); locations.setup(rabbit, food)
	var life := LifeEventManager.new(); life.setup(inventory); life.setup_week6(shop, cooking, locations, food)
	var pending := life.check_life_events(); var same_pending := life.check_life_events()
	_expect(pending != null and pending.event_id == "shop_first_purchase_001" and same_pending == pending, "Pending shop event must only be created once")
	life.confirm_life_event("shop_first_purchase_001")
	_expect(shop.is_product_unlocked("small_snack"), "First Purchase Event must unlock Small Snack")
	var snapshot := shop.to_dict(); var daily_reload := DailyShopManager.new()
	daily_reload.set_day_key_provider(func() -> String: return day[0])
	var shop_reload := ShopManager.new(); shop_reload.setup(inventory, currency, daily_reload, snapshot)
	var reloaded_ids: Array[String] = []
	for offer: DailyShopOfferData in daily_reload.get_daily_offers(): reloaded_ids.append(offer.product_id)
	_expect(offer_ids == reloaded_ids, "Reload on same day must keep daily offers")
	_expect(shop_reload.get_daily_remaining("apple") == 1, "Reload must keep independent daily limit")
	day[0] = "2026-08-27"
	_expect(daily_reload.refresh_if_needed(), "Cross-day must refresh daily offers")
	_expect(daily_reload.state.day_key == "2026-08-27", "Cross-day must store new day key")

func _test_cooking_atomic_and_replay() -> void:
	var inventory := InventoryManager.new(); inventory.add_item("carrot", 2, "test", "ingredients")
	inventory.add_item("bread", 1, "test", "ingredients")
	var cooking := CookingManager.new(); cooking.setup(inventory)
	var result := cooking.cook("carrot_sandwich", "cook_fixed_001")
	var carrot_after := inventory.get_item_amount("carrot")
	var replay := cooking.cook("carrot_sandwich", "cook_fixed_001")
	_expect(result.success and result.is_first_discovery, "First cooking must succeed and discover recipe")
	_expect(not replay.success and inventory.get_item_amount("carrot") == carrot_after, "Cooking replay must not consume materials")
	_expect(inventory.get_item_amount("carrot_sandwich") == 1, "Cooking must add result item")
	var failed := cooking.cook("carrot_sandwich", "cook_missing_ingredients")
	_expect(not failed.success and inventory.get_item_amount("carrot") == carrot_after, "Missing ingredients must not partially consume materials")
	var restored := CookingManager.new(); restored.setup(inventory, cooking.to_dict())
	_expect(not restored.cook("carrot_sandwich", "cook_fixed_001").success, "Reload must preserve cooking replay guard")

func _test_generic_food_and_picnic() -> void:
	var inventory := InventoryManager.new(); inventory.add_item("forest_salad", 1, "test", "food")
	var rabbit := RabbitData.new("Amy", 80, 80, 80); var food := FoodManager.new(); food.setup(inventory, rabbit)
	var used := food.use_food("forest_salad")
	_expect(used != null and rabbit.hunger == 95 and rabbit.mood == 88, "Generic food must apply Hunger and Mood")
	rabbit.hunger = 100; rabbit.energy = 100; rabbit.mood = 100; inventory.add_item("picnic_snack", 1, "test", "waste")
	_expect(food.use_food("picnic_snack") == null and inventory.get_item_amount("picnic_snack") == 1, "Food with no effective change must be rejected")
	rabbit.energy = 50; rabbit.mood = 50
	var locations := LifeLocationManager.new(); locations.setup(rabbit, food)
	var first := locations.perform_activity("picnic_area", "picnic_rest", "", "picnic_fixed_001")
	var mood_after := rabbit.mood; var replay := locations.perform_activity("picnic_area", "picnic_rest", "", "picnic_fixed_001")
	var rapid := locations.perform_activity("picnic_area", "picnic_rest", "", "picnic_fixed_002")
	_expect(first.success and not replay.success and not rapid.success, "Picnic replay and rapid click must be blocked")
	_expect(rabbit.mood == mood_after, "Blocked picnic actions must not add Mood")
	var restored := LifeLocationManager.new(); restored.setup(rabbit, food, locations.to_dict())
	_expect(not restored.perform_activity("picnic_area", "picnic_rest", "", "picnic_fixed_001").success, "Reload must preserve picnic replay guard")
