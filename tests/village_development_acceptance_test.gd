extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	_test_lakeside_stage_two()
	_test_village_expansion_finale()
	_test_week_seven_migration_is_safe_and_repeatable()
	if failures.is_empty():
		print("VILLAGE_DEVELOPMENT_ACCEPTANCE_TESTS_OK")
		quit(0)
		return
	for message: String in failures:
		push_error(message)
	quit(1)


func _expect(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _test_lakeside_stage_two() -> void:
	var rabbit := RabbitData.new()
	rabbit.fishing_experience = 65
	rabbit.intimacy = 12
	rabbit.unlocked_growth_marks = [{"id": "lake_interest"}]
	var growth := GrowthManager.new()
	growth.setup(rabbit)
	growth.set_completed_life_event_ids(["lake_event_1", "fishing_event_2"])
	var save := SaveData.new()
	for index: int in 10:
		save.all_activity_records.append({"activity_record_id": "lake_%d" % index, "activity_id": "fishing", "location_id": "lake"})
	growth.load_from_save_data(save)
	var pending := growth.check_growth_path_events()
	_expect(pending != null and pending.event_id == "growth_lakeside_stage2_001", "Lakeside Stage 2 must become pending after its requirements are met")
	_expect(growth.get_lakeside_growth_stage() == 1, "Lakeside growth must not advance before confirmation")
	_expect(growth.confirm_growth_event("growth_lakeside_stage2_001"), "Lakeside Stage 2 confirmation must succeed once")
	var reloaded := GrowthManager.new()
	reloaded.setup(RabbitData.from_dict(rabbit.to_dict()))
	_expect(reloaded.get_lakeside_growth_stage() == 2 and reloaded.get_appearance_state() == "lakeside_stage2", "Lakeside Stage 2 appearance must survive reload")


func _test_village_expansion_finale() -> void:
	var village_data := VillageData.new()
	var buildings := BuildingManager.new()
	buildings.setup(village_data)
	buildings.adopt_completed_building("coffee_shop", "Slot01")
	var rabbit := RabbitData.new()
	rabbit.cafe_activity_count = 3
	rabbit.unlocked_growth_marks = [{"id": "leaf_mark"}, {"id": "sprout_mark"}, {"id": "forest_stage3"}]
	var growth := GrowthManager.new()
	growth.setup(rabbit)
	var activities := ActivityManager.new()
	activities.setup(rabbit)
	var inventory := InventoryManager.new()
	var currency := CurrencyManager.new()
	var village := VillageManager.new()
	village.setup(village_data)
	var events := LifeEventManager.new()
	events.setup(inventory, growth)
	events.setup_week7(buildings, activities, village, currency)
	var registered: Dictionary = events.get("_events")
	(registered["cafe_first_visit_001"] as LifeEventData).state = LifeEventState.COMPLETED
	village.setup_snapshot_sources(buildings, growth, events)
	_expect(events.can_trigger_life_event("village_first_expansion_001"), "Week 7 finale must unlock after Café, activity, growth, event, and village progress requirements")
	var pending := events.create_pending_life_event("village_first_expansion_001")
	_expect(pending != null and events.confirm_life_event("village_first_expansion_001") != null, "Week 7 finale must complete through pending and confirmation")


func _test_week_seven_migration_is_safe_and_repeatable() -> void:
	var save := SaveData.new()
	save.save_version = 7
	save.currency_data = {"currency_id": "coin", "amount": 77, "total_earned": 90, "total_spent": 13}
	save.inventory = {"twig": {"item_id": "twig", "amount": 12}}
	save.completed_life_event_ids = ["cafe_barista_arrives_001"]
	save.growth_path_progress = {"forest_stage": 3, "lakeside_stage": 0}
	var village := VillageData.new()
	village.unlocked_building_ids = ["coffee_shop"]
	village.building_records["coffee_shop"] = {"building_id": "coffee_shop", "slot_id": "Slot03", "state": BuildingState.COMPLETED, "placed_at": 10.0, "completed_at": 20.0}
	save.village_data = village.to_dict()
	LegacySaveMigrator.migrate_week6_to_week7(save)
	LegacySaveMigrator.migrate_week6_to_week7(save)
	_expect(int(save.currency_data.get("amount", 0)) == 77 and save.inventory.has("twig"), "Migration must preserve Currency and Inventory")
	_expect(str(save.building_slots.get("building_slot_03", "")) == "cafe", "Migration must preserve the Café slot using the canonical slot id")
	_expect(save.building_unlock_history.size() == 1 and save.building_placement_history.size() == 1, "Repeated migration must not duplicate permanent building history")
	_expect(save.growth_appearance_state == "forest_stage3", "Migration must restore the advanced growth appearance")
