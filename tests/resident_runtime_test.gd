extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_test_locked_and_old_save_migration()
	_test_interactions_and_reload_guards()
	_test_shared_activity_and_social_progress()
	_test_social_features_and_stage2()
	if failures.is_empty(): print("RESIDENT_RUNTIME_TESTS_OK"); quit(0)
	else:
		for message: String in failures: push_error(message)
		quit(1)
func _expect(value: bool, message: String) -> void:
	if not value: failures.append(message)
func _runtime(cafe_completed := false) -> Dictionary:
	var rabbit := RabbitData.new(); var village_data := VillageData.new(); var buildings := BuildingManager.new(); buildings.setup(village_data)
	if cafe_completed: buildings.adopt_completed_building("coffee_shop", "Slot01")
	var growth := GrowthManager.new(); growth.setup(rabbit); var inventory := InventoryManager.new(); var residents := ResidentManager.new(); residents.setup(rabbit, buildings, growth, inventory)
	return {"rabbit": rabbit, "village_data": village_data, "buildings": buildings, "growth": growth, "inventory": inventory, "residents": residents}
func _test_locked_and_old_save_migration() -> void:
	var locked := _runtime(false); var manager: ResidentManager = locked.residents
	_expect(manager.get_resident("cafe_owner").resident_state == "locked" and manager.get_resident_count() == 0, "Café owner must not exist at a new game start")
	_expect(manager.get_resident("unknown") == null, "Unknown resident id must be ignored safely")
	var migrated := _runtime(true); var owner: ResidentData = migrated.residents.get_resident("cafe_owner")
	_expect(owner.resident_state == "resident" and owner.arrived_at > 0.0 and owner.current_location == "cafe", "Completed Café old save must restore Café owner")
func _test_interactions_and_reload_guards() -> void:
	var runtime := _runtime(true); var manager: ResidentManager = runtime.residents; var rabbit: RabbitData = runtime.rabbit
	var first := manager.interact("cafe_owner", "resident_talk", "talk_fixed_001"); var social_after := rabbit.social_experience
	_expect(first.success and not manager.interact("cafe_owner", "resident_talk", "talk_fixed_001").success and rabbit.social_experience == social_after, "Interaction source id must apply once")
	manager.interact("cafe_owner", "resident_talk", "talk_fixed_002"); manager.interact("cafe_owner", "resident_talk", "talk_fixed_003")
	_expect(not manager.interact("cafe_owner", "resident_talk", "talk_fixed_004").success, "Daily conversation limit must prevent relationship farming")
	var restored_rabbit := RabbitData.from_dict(rabbit.to_dict()); var restored := ResidentManager.new(); restored.setup(restored_rabbit, runtime.buildings, runtime.growth, runtime.inventory)
	_expect(not restored.interact("cafe_owner", "resident_talk", "talk_fixed_001").success and restored_rabbit.social_experience == social_after + 4, "Reload must preserve relationship and social EXP guards")
func _test_shared_activity_and_social_progress() -> void:
	var runtime := _runtime(true); var rabbit: RabbitData = runtime.rabbit; var residents: ResidentManager = runtime.residents
	var activities := ActivityManager.new(); activities.setup(rabbit, null, null, runtime.growth); activities.setup_cafe(runtime.buildings, CurrencyManager.new()); activities.setup_residents(residents)
	var started := activities.start_activity("shared_forest_walk"); _expect(started.ok, "Shared Forest Activity must use ActivityManager")
	activities.active_activity.ends_at = TimeManager.get_now() - 1.0; activities.check_for_completion(); var owner := residents.get_resident("cafe_owner"); var social_after := rabbit.social_experience
	_expect(owner.relationship.shared_activity_count == 1 and social_after == 3, "Offline shared activity must add relationship and Social EXP")
	var completed := started.active_activity as ActiveActivityData; _expect(not residents.apply_shared_activity(completed).success and rabbit.social_experience == social_after, "Shared activity record id must not replay")
	_expect(activities.can_start_activity("fishing").ok, "Resident integration must not block ordinary Lakeside activity")
func _test_social_features_and_stage2() -> void:
	var runtime := _runtime(true); var residents: ResidentManager = runtime.residents; var rabbit: RabbitData = runtime.rabbit
	residents.interact("cafe_owner", "resident_talk", "meet_1"); residents.interact("cafe_owner", "resident_talk", "meet_2")
	_expect(residents.create_invitation("cafe_owner", "shared_picnic", "invite_1").state == "pending", "Resident invitation must be created")
	_expect(residents.respond_to_invitation("cafe_owner", "invite_1", false).ok, "Rejecting an invitation must be legal")
	var before := residents.get_resident("cafe_owner").relationship.progress; _expect(residents.get_resident("cafe_owner").relationship.progress == before, "Invitation rejection must not punish relationship")
	_expect(residents.give_resident_gift("cafe_owner", "resident_first_gift_001") and not residents.give_resident_gift("cafe_owner", "resident_first_gift_001"), "Resident gift event must apply once")
	var life := LifeEventManager.new(); life.setup(runtime.inventory, runtime.growth); life.setup_week9(residents)
	var village := VillageManager.new(); village.setup(runtime.village_data); village.setup_snapshot_sources(runtime.buildings, runtime.growth, life); village.setup_late_game(rabbit, ActivityManager.new(), DiaryManager.new()); village.setup_residents(residents)
	var progress := village.get_village_progress_snapshot(); _expect(progress.resident_count == 1 and progress.stage2_progress > 0 and progress.stage2_progress < 100, "Village Stage2 must accumulate without completing")
