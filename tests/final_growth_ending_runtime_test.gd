extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_test_forest_final_and_reload()
	_test_lakeside_and_cross_branch()
	_test_balanced_and_maintain()
	_test_stage1_ending_replay()
	if failures.is_empty(): print("FINAL_GROWTH_ENDING_RUNTIME_TESTS_OK"); quit(0)
	else:
		for message: String in failures: push_error(message)
		quit(1)
func _expect(value: bool, message: String) -> void:
	if not value: failures.append(message)
func _prepared_growth(branch: String) -> Dictionary:
	var rabbit := RabbitData.new(); rabbit.intimacy = 20
	var save := SaveData.new(); var events: Array[String] = []
	if branch == "forest":
		rabbit.forest_experience = 120; rabbit.fishing_experience = 77; rabbit.unlocked_growth_marks = [{"id": "leaf_mark"}, {"id": "sprout_mark"}, {"id": "forest_stage3"}]
		for i in 16: save.all_activity_records.append({"activity_record_id": "f_%d" % i, "activity_id": "forest_explore", "location_id": "forest"})
		events.assign(["forest_special_1", "forest_special_2", "forest_special_3"])
	else:
		rabbit.fishing_experience = 100; rabbit.forest_experience = 66; rabbit.unlocked_growth_marks = [{"id": "lake_interest"}, {"id": "lakeside_stage2"}]
		for i in 14: save.all_activity_records.append({"activity_record_id": "l_%d" % i, "activity_id": "fishing", "location_id": "lake"})
		events.assign(["lake_special_1", "lake_special_2", "lake_special_3"])
	var growth := GrowthManager.new(); growth.setup(rabbit); growth.load_from_save_data(save); growth.set_completed_life_event_ids(events)
	return {"rabbit": rabbit, "growth": growth, "save": save}
func _test_forest_final_and_reload() -> void:
	var prepared := _prepared_growth("forest"); var growth: GrowthManager = prepared.growth; var rabbit: RabbitData = prepared.rabbit
	_expect(growth.submit_growth_direction_choice("encourage_forest").success, "Forest direction must be accepted")
	var pending := growth.get_final_growth_state(); _expect(pending.state == "final_pending", "Eligible Forest Final must become pending")
	var restored_rabbit := RabbitData.from_dict(rabbit.to_dict()); var restored := GrowthManager.new(); restored.setup(restored_rabbit); restored.load_from_save_data(prepared.save); restored.set_completed_life_event_ids(["forest_special_1", "forest_special_2", "forest_special_3"])
	var applied := restored.check_final_growth_completion(pending.complete_at + 1.0)
	_expect(applied.success and restored.get_forest_growth_stage() == 4 and restored.get_current_final_form() == "forest_rabbit", "Offline Forest Final must apply after reload")
	_expect(restored_rabbit.fishing_experience == 77 and not restored.check_final_growth_completion(pending.complete_at + 2.0).success, "Final apply must preserve cross experience and be idempotent")
func _test_lakeside_and_cross_branch() -> void:
	var prepared := _prepared_growth("lakeside"); var growth: GrowthManager = prepared.growth; var rabbit: RabbitData = prepared.rabbit
	_expect(growth.submit_growth_direction_choice("encourage_lakeside").success, "Lakeside direction must be accepted")
	var pending := growth.get_final_growth_state(); var applied := growth.check_final_growth_completion(pending.complete_at + 1.0)
	_expect(applied.success and growth.get_lakeside_growth_stage() == 3 and rabbit.forest_experience == 66, "Lakeside Final must apply without clearing Forest experience")
	var activities := ActivityManager.new(); activities.setup(rabbit, null, null, growth)
	_expect(activities.can_start_activity("forest_walk").ok, "Lakeside Rabbit must still be able to visit Forest")
func _test_balanced_and_maintain() -> void:
	var rabbit := RabbitData.new(); rabbit.unlocked_growth_marks = [{"id": "leaf_mark"}, {"id": "sprout_mark"}, {"id": "forest_stage3"}, {"id": "lake_interest"}, {"id": "lakeside_stage2"}]; rabbit.forest_experience = 120; rabbit.fishing_experience = 120
	var save := SaveData.new()
	for i in 16:
		save.all_activity_records.append({"activity_record_id": "bf_%d" % i, "location_id": "forest"})
		save.all_activity_records.append({"activity_record_id": "bl_%d" % i, "location_id": "lake"})
	var growth := GrowthManager.new(); growth.setup(rabbit); growth.load_from_save_data(save); growth.set_completed_life_event_ids(["forest_1", "forest_2", "forest_3", "lake_1", "lake_2", "lake_3"])
	var choice := growth.submit_growth_direction_choice("let_rabbit_decide"); _expect(choice.success and choice.resolved_branch == "balanced" and growth.get_final_growth_state().state != "final_pending", "Balanced rabbit must not be forced into Final")
	var maintain_rabbit := RabbitData.from_dict(rabbit.to_dict()); maintain_rabbit.growth_direction_choice = {}; var maintain := GrowthManager.new(); maintain.setup(maintain_rabbit); maintain.load_from_save_data(save)
	_expect(maintain.submit_growth_direction_choice("maintain_current").success and maintain.get_final_growth_state().state != "final_pending", "Maintain Current must not enter Final")
	_expect(not maintain.submit_growth_direction_choice("encourage_forest").success, "Direction confirmation must not replay or redirect")
func _test_stage1_ending_replay() -> void:
	var prepared := _prepared_growth("forest"); var rabbit: RabbitData = prepared.rabbit; var growth: GrowthManager = prepared.growth; growth.submit_growth_direction_choice("encourage_forest"); var pending := growth.get_final_growth_state(); growth.check_final_growth_completion(pending.complete_at + 1.0); rabbit.total_activity_count = 20
	var village_data := VillageData.new(); var buildings := BuildingManager.new(); buildings.setup(village_data); buildings.adopt_completed_building("coffee_shop", "Slot01")
	var life := LifeEventManager.new(); life.setup(InventoryManager.new(), growth)
	var events: Dictionary = life.get("_events"); var completed := 0
	for event: LifeEventData in events.values():
		if completed >= 6: break
		event.state = LifeEventState.COMPLETED; completed += 1
	var diary := DiaryManager.new(); var raw_journals: Array[Dictionary] = []
	for i in 8: raw_journals.append({"journal_id": "j_%d" % i, "journal_type": "activity", "activity_record_id": "a_%d" % i, "activity_id": "forest_walk", "created_at": float(i + 1)})
	diary.load_from_array(raw_journals)
	var village := VillageManager.new(); village.setup(village_data); village.setup_snapshot_sources(buildings, growth, life); village.setup_late_game(rabbit, ActivityManager.new(), diary)
	_expect(village.can_trigger_stage1_ending(), "Stage1 ending must become eligible")
	_expect(village.create_stage1_ending().state == "pending", "Ending must enter pending")
	var first := village.complete_stage1_ending(); var replay := village.complete_stage1_ending()
	_expect(first != null and first.first_completion and replay != null and not replay.first_completion and village.has_completed_stage1_ending(), "Ending completion and replay must be idempotent")
	var activities := ActivityManager.new(); activities.setup(rabbit); _expect(activities.can_start_activity("forest_walk").ok, "Continue Play must remain available after ending")
