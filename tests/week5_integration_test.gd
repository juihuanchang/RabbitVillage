extends Node

var failures: Array[String] = []

func _ready() -> void:
	await _test_need_boundaries()
	await _test_life_event_chaining()
	await _test_growth_event_chaining()
	_test_carrot_migration()
	if failures.is_empty():
		print("WEEK5_INTEGRATION_TESTS_OK")
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_need_boundaries() -> void:
	var rabbit := RabbitData.new("Amy", 19, 19, 9)
	var manager := RabbitManager.new()
	manager.setup(rabbit)
	_expect(manager.get_hunger_state() == "critical", "Hunger 19 應為很餓")
	_expect(manager.get_energy_state() == "critical", "Energy 9 應為非常累")
	_expect(manager.get_mood_state() == "critical", "Mood 19 應為心情不好")
	rabbit.hunger = 20
	rabbit.energy = 10
	rabbit.mood = 20
	_expect(manager.get_hunger_state() == "low", "Hunger 20 應為有點餓")
	_expect(manager.get_energy_state() == "low", "Energy 10 應為有點累")
	_expect(manager.get_mood_state() == "low", "Mood 20 應為有點低落")
	rabbit.hunger = 80
	rabbit.energy = 70
	rabbit.mood = 70
	_expect(manager.get_hunger_state() == "full", "Hunger 80 應為很飽")
	_expect(manager.get_energy_state() == "high", "Energy 70 應為精神很好")
	_expect(manager.get_mood_state() == "happy", "Mood 70 應為心情很好")
	await get_tree().process_frame

func _test_life_event_chaining() -> void:
	var inventory := InventoryManager.new()
	var life := LifeEventManager.new()
	add_child(life)
	life.setup(inventory)
	inventory.add_item("leaf", 15, "test", "leaf_ready")
	inventory.add_item("twig", 10, "test", "twig_ready")
	var first := life.check_life_events()
	_expect(first != null and first.event_id == "life_leaf_collection_001", "第一個素材事件應為葉子")
	if first != null:
		life.confirm_life_event(first.event_id)
	await get_tree().process_frame
	await get_tree().process_frame
	var second := life.get_pending_life_event()
	_expect(second != null and second.event_id == "life_twig_collection_001", "確認葉子後應自動排入樹枝事件")
	life.queue_free()

func _test_growth_event_chaining() -> void:
	var rabbit := RabbitData.new("Amy", 100, 100, 100)
	rabbit.unlocked_growth_marks.append({"id": "leaf_mark", "is_unlocked": true, "unlocked_at": 1.0})
	rabbit.forest_experience = 60
	rabbit.forest_activity_count = 8
	rabbit.fishing_experience = 40
	rabbit.intimacy = 10
	var growth := GrowthManager.new()
	add_child(growth)
	growth.setup(rabbit)
	for index: int in 8:
		var forest_activity := ActivityData.create_forest_explore() if index < 3 else ActivityData.create_forest_walk()
		var forest_active := ActiveActivityData.new(rabbit, forest_activity, float(index + 1), "forest_chain_%d" % index)
		forest_active.mark_completed(float(index + 2))
		growth.record_completed_activity(forest_active)
	for index: int in 7:
		var lake_activity := ActivityData.create_fishing()
		if index >= 5:
			lake_activity.activity_id = "lake_visit_chain_%d" % index
		var lake_active := ActiveActivityData.new(rabbit, lake_activity, float(index + 20), "lake_chain_%d" % index)
		lake_active.mark_completed(float(index + 21))
		growth.record_completed_activity(lake_active)
	var first := growth.get_pending_growth_event()
	_expect(first != null and first.event_id == "growth_sprout_mark_001", "第一個成長事件應為嫩芽")
	if first != null:
		growth.confirm_growth_event(first.event_id)
	await get_tree().process_frame
	await get_tree().process_frame
	var second := growth.get_pending_growth_event()
	_expect(second != null and second.event_id == "growth_lake_interest_001", "確認嫩芽後應自動排入湖畔事件")
	growth.queue_free()

func _test_carrot_migration() -> void:
	var save := SaveData.new()
	save.save_version = 5
	var village := VillageData.new()
	village.carrot_inventory = {
		"amount": 30,
		"total_obtained": 30,
		"first_obtained_at": 1.0,
		"last_obtained_at": 2.0
	}
	save.village_data = village.to_dict()
	LegacySaveMigrator.migrate_week4_to_week5(save)
	var carrot := InventoryEntry.from_dict(save.inventory.get("carrot", {}))
	_expect(carrot.amount == 30, "第四週 Carrot 30 應遷移為 Inventory 30")
	_expect(carrot.total_obtained >= carrot.amount, "Carrot total_obtained 不得低於目前數量")
