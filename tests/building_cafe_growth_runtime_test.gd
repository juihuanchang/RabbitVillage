extends SceneTree

var failures: Array[String] = []

class FailingInventory extends InventoryManager:
	func remove_item(item_id: String, amount: int, source_type: String, source_id: String) -> bool:
		if item_id == "small_stone": return false
		return super.remove_item(item_id, amount, source_type, source_id)

func _init() -> void:
	_test_building_and_cafe()
	_test_growth_pending_confirm_reload()
	if failures.is_empty(): print("BUILDING_CAFE_GROWTH_RUNTIME_TESTS_OK"); quit(0)
	else:
		for message: String in failures: push_error(message)
		quit(1)
func _expect(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _test_building_and_cafe() -> void:
	var rollback_data := VillageData.new(); var rollback_buildings := BuildingManager.new(); rollback_buildings.setup(rollback_data); rollback_buildings.unlock_building("coffee_shop")
	var rollback_currency := CurrencyManager.new(); rollback_currency.add_coins(100, "test", "seed"); var failing := FailingInventory.new(); failing.add_item("twig", 5, "test", "seed"); failing.add_item("small_stone", 3, "test", "seed")
	rollback_buildings.setup_economy(rollback_currency, failing)
	_expect(not rollback_buildings.place_building("coffee_shop", "Slot01").ok and rollback_currency.get_coin_amount() == 100 and failing.get_item_amount("twig") == 5 and rollback_data.building_records.is_empty(), "Material failure after coin spend must rollback the whole placement")
	var village_data := VillageData.new(); var buildings := BuildingManager.new(); buildings.setup(village_data); buildings.unlock_building("coffee_shop")
	var currency := CurrencyManager.new(); currency.add_coins(100, "test", "seed")
	var inventory := InventoryManager.new(); inventory.add_item("twig", 5, "test", "seed"); inventory.add_item("small_stone", 3, "test", "seed")
	var village := VillageManager.new(); village.setup(village_data); var construction := ConstructionManager.new(); construction.setup(village_data, buildings, village); buildings.setup_economy(currency, inventory, construction)
	var rabbit := RabbitData.new(); var activities := ActivityManager.new(); activities.setup(rabbit); activities.setup_cafe(buildings, currency)
	_expect(not activities.can_start_activity("cafe_hot_drink").ok, "Café activity must be locked before construction completion")
	var placed := buildings.place_building("coffee_shop", "Slot01")
	_expect(placed.ok and currency.get_coin_amount() == 50 and inventory.get_item_amount("twig") == 0, "Placement must atomically consume full cost")
	_expect(not buildings.place_building("coffee_shop", "Slot02").ok, "Duplicate building placement must fail")
	var other := BuildingManager.new(); other.setup(village_data); other.unlock_building("rest_pavilion")
	_expect(not other.can_place_building("rest_pavilion", "Slot01").ok, "Occupied slot must reject rapid placement")
	village_data.active_construction["ends_at"] = TimeManager.get_now() - 1.0
	var completed := construction.check_construction_completion()
	_expect(completed != null and buildings.is_building_completed("coffee_shop"), "Expired offline construction must complete")
	_expect(construction.check_construction_completion() == null and village_data.completed_construction_ids.size() == 1, "Construction completion must be idempotent")
	var started := activities.start_activity("cafe_help_serve"); _expect(started.ok, "Completed Café must unlock Café activities")
	activities.active_activity.ends_at = TimeManager.get_now() - 1.0; var coins_before := currency.get_coin_amount(); activities.check_for_completion()
	_expect(rabbit.cafe_experience == 12 and rabbit.social_experience == 3 and currency.get_coin_amount() == coins_before + 10, "Offline Café work must apply experience and CurrencyManager reward")
	_expect(not activities.check_for_completion() and currency.get_coin_amount() == coins_before + 10, "Activity reward must not replay")

func _test_growth_pending_confirm_reload() -> void:
	var rabbit := RabbitData.new(); rabbit.forest_experience = 85; rabbit.forest_activity_count = 12; rabbit.intimacy = 15
	rabbit.unlocked_growth_marks = [{"id": "leaf_mark"}, {"id": "sprout_mark"}]
	var growth := GrowthManager.new(); growth.setup(rabbit); growth.set_completed_life_event_ids(["forest_event_1", "forest_event_2"])
	var save := SaveData.new()
	for i in 12: save.all_activity_records.append({"activity_record_id": "forest_%d" % i, "activity_id": "forest_explore", "location_id": "forest"})
	growth.load_from_save_data(save); var pending := growth.check_growth_path_events()
	_expect(pending != null and pending.event_id == "growth_forest_stage3_001" and growth.get_forest_growth_stage() == 2, "Forest Stage 3 must remain pending before confirm")
	_expect(growth.confirm_growth_event("growth_forest_stage3_001") and growth.get_forest_growth_stage() == 3, "Forest Stage 3 confirm must advance once")
	var reload := GrowthManager.new(); reload.setup(RabbitData.from_dict(rabbit.to_dict()))
	_expect(reload.get_forest_growth_stage() == 3 and reload.get_appearance_state() == "forest_stage3", "Confirmed growth must survive reload")
