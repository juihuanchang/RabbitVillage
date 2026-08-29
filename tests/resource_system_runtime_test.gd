extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_test_food()
	_test_activity_rules()
	_test_reward_and_discovery()
	_test_farm_inventory()
	_test_life_event()
	_test_growth_paths()
	if failures.is_empty():
		print("RESOURCE_SYSTEM_RUNTIME_TESTS_OK")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _expect(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _test_food() -> void:
	var inventory := InventoryManager.new()
	var rabbit := RabbitData.new("Amy", 50, 50, 100)
	var food := FoodManager.new()
	inventory.add_item("carrot", 10, "test", "food_stock")
	food.setup(inventory, rabbit)
	var result := food.eat_carrot()
	_expect(result != null, "Test 1: carrot should be edible")
	_expect(inventory.get_item_amount("carrot") == 9, "Test 1: carrot should become 9")
	_expect(rabbit.hunger == 58, "Test 1: hunger should become 58")
	rabbit.hunger = 98
	_expect(food.eat_carrot() == null, "Test 2: hunger 98 must reject food")
	_expect(inventory.get_item_amount("carrot") == 9, "Test 2: rejected food must not consume carrot")

func _test_activity_rules() -> void:
	var rabbit := RabbitData.new("Amy", 10, 50, 100)
	var activities := ActivityManager.new()
	activities.setup(rabbit)
	var forest := activities.can_start_activity("forest_walk")
	var home := activities.can_start_activity("home_rest")
	_expect(not bool(forest.success) and str(forest.reason) == "too_hungry", "Test 3: forest_walk should be too_hungry")
	_expect(bool(home.success), "Test 3: home_rest should be allowed")

func _test_reward_and_discovery() -> void:
	var inventory := InventoryManager.new()
	var currency := CurrencyManager.new()
	var rewards := RewardManager.new()
	var discoveries := [0]
	inventory.item_discovered.connect(func(_item: String, _source: String, _id: String, _at: float) -> void: discoveries[0] += 1)
	rewards.setup(inventory, currency)
	var result := rewards.generate_activity_reward("forest_walk", "activity_test_reward")
	_expect(rewards.apply_activity_reward(result), "Test 4: first reward apply should succeed")
	_expect(currency.get_coin_amount() == 3, "Test 4: forest walk should add 3 coins")
	_expect(not rewards.apply_activity_reward(result), "Test 4: duplicate reward apply should fail")
	_expect(currency.get_coin_amount() == 3, "Test 4: duplicate reward must add 0 coins")
	inventory.add_item("twig", 1, "test", "twig_first")
	_expect(discoveries[0] >= 1, "Test 6: first twig must emit discovery")
	var discoveries_after_first: int = discoveries[0]
	inventory.remove_item("twig", inventory.get_item_amount("twig"), "test", "twig_use")
	inventory.add_item("twig", 1, "test", "twig_second")
	_expect(discoveries[0] == discoveries_after_first, "Test 6: reacquired twig must not emit discovery")

func _test_life_event() -> void:
	var inventory := InventoryManager.new()
	var life := LifeEventManager.new()
	life.setup(inventory)
	inventory.add_item("twig", 10, "test", "twig_threshold")
	var first := life.check_life_events()
	var second := life.check_life_events()
	_expect(first != null and first.event_id == "life_twig_collection_001", "Test 7: twig threshold should create pending event")
	_expect(second == first, "Test 7: pending event must not be duplicated")

func _test_farm_inventory() -> void:
	var data := VillageData.new()
	var buildings := BuildingManager.new(); buildings.setup(data)
	buildings.adopt_completed_building("carrot_farm", "Slot01")
	var village := VillageManager.new(); village.setup(data)
	var inventory := InventoryManager.new()
	var farm := FarmManager.new(); farm.setup(data, buildings, village, inventory)
	var cycle := FarmCycleData.new()
	cycle.farm_cycle_id = "farm_test_cycle"; cycle.started_at = 1.0; cycle.ready_at = 1.0
	farm.farm.state = FarmState.READY; farm.farm.current_cycle = cycle.to_dict()
	var result := farm.harvest_carrots()
	_expect(result != null and result.amount == 10, "Test 5: farm should harvest 10 carrots")
	_expect(inventory.get_item_amount("carrot") == 10, "Test 5: harvest must enter InventoryManager")

func _test_growth_paths() -> void:
	var rabbit := RabbitData.new()
	rabbit.unlocked_growth_marks.append({"id": "leaf_mark", "is_unlocked": true, "unlocked_at": 1.0})
	rabbit.forest_experience = 60; rabbit.forest_activity_count = 8; rabbit.intimacy = 10
	var growth := GrowthManager.new(); growth.setup(rabbit)
	for index: int in 8:
		var activity := ActivityData.create_forest_explore() if index < 3 else ActivityData.create_forest_walk()
		var active := ActiveActivityData.new(rabbit, activity, float(index + 1), "forest_%d" % index)
		active.mark_completed(float(index + 2)); growth.record_completed_activity(active)
	var sprout := growth.check_growth_path_events()
	_expect(sprout != null and sprout.event_id == "growth_sprout_mark_001", "Test 8: sprout should become pending")
	_expect(not growth.has_growth_mark("sprout_mark"), "Test 8: pending must not unlock sprout immediately")
	_expect(growth.confirm_growth_event("growth_sprout_mark_001"), "Test 8: sprout confirm should succeed")
	_expect(growth.has_growth_mark("sprout_mark") and growth.get_forest_growth_stage() == 2, "Test 8: confirm should unlock sprout and forest stage 2")

	var lake_rabbit := RabbitData.new(); lake_rabbit.fishing_experience = 40; lake_rabbit.intimacy = 8
	var lake_growth := GrowthManager.new(); lake_growth.setup(lake_rabbit)
	for index: int in 7:
		var activity := ActivityData.create_fishing()
		if index >= 5:
			activity.activity_id = "lake_visit_%d" % index
		var active := ActiveActivityData.new(lake_rabbit, activity, float(index + 1), "lake_%d" % index)
		active.mark_completed(float(index + 2)); lake_growth.record_completed_activity(active)
	var lake := lake_growth.check_growth_path_events()
	_expect(lake != null and lake.event_id == "growth_lake_interest_001", "Test 9: lake interest should become pending")
	_expect(lake_growth.confirm_growth_event("growth_lake_interest_001"), "Test 9: lake confirm should succeed")
	_expect(lake_growth.get_lakeside_growth_stage() == 1, "Test 9: confirm should set lakeside stage 1")
