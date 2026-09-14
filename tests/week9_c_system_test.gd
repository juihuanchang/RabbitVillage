extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_test_save_version_and_roundtrip()
	_test_history_dedup_and_first_meeting()
	_test_relationship_repair_and_resume()
	_test_week8_cafe_migration()
	_test_journal_and_branch_regression()
	_test_social_duplicate_guards()
	_test_migration_regression()
	if failures.is_empty():
		print("WEEK9_C_SYSTEM_TESTS_OK")
		quit(0)
	else:
		for message: String in failures:
			push_error(message)
		quit(1)

func _expect(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _runtime(cafe_completed := true) -> Dictionary:
	var rabbit := RabbitData.new()
	var village_data := VillageData.new()
	var buildings := BuildingManager.new()
	buildings.setup(village_data)
	if cafe_completed:
		buildings.adopt_completed_building("coffee_shop", "Slot01")
	var growth := GrowthManager.new()
	growth.setup(rabbit)
	var inventory := InventoryManager.new()
	var residents := ResidentManager.new()
	residents.setup(rabbit, buildings, growth, inventory)
	return {"rabbit": rabbit, "village_data": village_data, "buildings": buildings, "growth": growth, "inventory": inventory, "residents": residents}

func _test_save_version_and_roundtrip() -> void:
	_expect(SaveData.CURRENT_VERSION == 10, "Week 9 SaveVersion must be 10")
	var save := SaveData.new()
	var resident := ResidentData.new()
	resident.resident_id = "cafe_owner"
	resident.relationship.resident_id = "cafe_owner"
	resident.state.state = ResidentStateData.RESIDENT
	resident.state.current_location = "home"
	save.resident_states[resident.resident_id] = resident.to_dict()
	save.resident_arrival_history.append({"history_id": "arrival_1", "resident_id": "cafe_owner", "history_type": "arrival", "source_event_id": "cafe_completed_migration", "created_at": 10.0, "arrived_at": 10.0})
	save.resident_interaction_history.append({"interaction_id": "talk_1", "resident_id": "cafe_owner", "interaction_type": "resident_talk", "interacted_at": 20.0})
	save.resident_interaction_history.append({"interaction_id": "talk_1", "resident_id": "cafe_owner", "interaction_type": "resident_talk", "interacted_at": 21.0})
	var loaded := SaveData.from_dict(save.to_dict())
	_expect(loaded.resident_states.has("cafe_owner"), "Resident State must survive SaveData roundtrip")
	_expect(str((loaded.resident_states["cafe_owner"] as Dictionary).get("state", {}).get("current_location", "")) == "home", "Resident location must survive reload")
	_expect(loaded.resident_interaction_history.size() == 1, "Duplicate Interaction History must be repaired on load")

func _test_history_dedup_and_first_meeting() -> void:
	var runtime := _runtime(true)
	var residents: ResidentManager = runtime.residents
	var manager := ResidentHistoryManager.new()
	manager.setup_from_save(SaveData.new())
	manager.sync_from_runtime(residents, 1.0)
	var result := residents.interact("cafe_owner", "resident_talk", "week9_talk_fixed")
	var first := manager.record_interaction(result, "resident_talk", 2.0)
	var duplicate := manager.record_interaction(result, "resident_talk", 3.0)
	manager.record_social_experience("cafe_owner", "interaction", "week9_talk_fixed", result.social_experience_change, 2.0)
	manager.record_social_experience("cafe_owner", "interaction", "week9_talk_fixed", result.social_experience_change, 3.0)
	_expect(first != null and duplicate != null and manager.resident_interaction_history.size() == 1, "Same InteractionId must create one permanent Interaction History")
	_expect(manager.resident_first_meeting_history.size() == 1, "First interaction must create exactly one First Meeting History")
	_expect(manager.resident_social_experience_history.size() == 1, "Same social EXP source must be recorded once")

func _test_relationship_repair_and_resume() -> void:
	var runtime := _runtime(true)
	var residents: ResidentManager = runtime.residents
	var owner := residents.get_resident("cafe_owner")
	owner.relationship.state = ResidentRelationshipData.FRIEND
	owner.relationship.interaction_count = 5
	owner.relationship.shared_activity_count = 3
	owner.relationship.progress = 40
	residents.commit_runtime_state()
	var history := ResidentHistoryManager.new()
	history.setup_from_save(SaveData.new())
	history.sync_from_runtime(residents, 50.0)
	_expect(not history.resident_relationship_history.is_empty(), "Known Friend without Relationship History must receive legal repair History")
	_expect(history.get_first_friend_id() == "cafe_owner", "First Friend must be computed from Relationship History")
	var save := SaveData.new()
	save.resident_relationship_history = history.resident_relationship_history.duplicate(true)
	var life := RabbitLifeHistoryManager.new()
	life.setup_from_save(save)
	var profile := life.update_profile(save, runtime.rabbit, runtime.growth, null, 60.0)
	_expect(profile != null and profile.first_friend == "cafe_owner", "Resume First Friend must come from History")
	_expect(profile != null and profile.friend_list.has("cafe_owner"), "Resume Friend List must come from History")

func _test_week8_cafe_migration() -> void:
	var save := SaveData.new()
	save.save_version = 9
	var rabbit := RabbitData.new()
	save.rabbits.append(rabbit.to_dict())
	var completed := ConstructionHistoryEntry.new()
	completed.construction_record_id = "old_cafe_construction"
	completed.building_id = "cafe"
	completed.slot_id = "building_slot_01"
	completed.is_completed = true
	completed.completed_at = 100.0
	save.construction_history.append(completed.to_dict())
	save.cafe_experience = 7
	var migrated := LegacySaveMigrator.migrate_week8_to_week9(save)
	_expect(migrated.resident_states.has("cafe_owner"), "Week 8 completed Café must migrate Café Owner into Resident State")
	var owner := ResidentData.from_dict(migrated.resident_states.get("cafe_owner", {}))
	_expect(owner.state.state == ResidentStateData.RESIDENT and owner.state.current_location == "cafe", "Migrated Café Owner must have a legal Resident state")
	_expect(migrated.resident_arrival_history.size() == 1, "Café migration must create exactly one Arrival History")
	LegacySaveMigrator.migrate_week8_to_week9(migrated)
	_expect(migrated.resident_arrival_history.size() == 1, "Week 9 migration must be idempotent")
	_expect(migrated.cafe_experience == 7 and migrated.construction_history.size() == 1, "Resident migration must not damage old Café data")

func _test_journal_and_branch_regression() -> void:
	var diary := DiaryManager.new()
	for branch: String in ["forest", "lakeside", "balanced"]:
		var entry := ResidentInteractionHistoryEntry.new()
		entry.interaction_id = "branch_%s" % branch
		entry.resident_id = "cafe_owner"
		entry.relationship_state = ResidentRelationshipData.ACQUAINTANCE
		entry.reaction_tag = "cafe_owner_%s_resident_talk" % branch
		entry.interacted_at = 200.0
		var journal := diary.generate_week9_interaction_journal(entry, "Amy")
		_expect(journal != null and journal.growth_form == branch, "%s resident reaction journal must preserve branch" % branch)
		var duplicate := diary.generate_week9_interaction_journal(entry, "Amy")
		_expect(duplicate == null, "Same InteractionId must not create duplicate journal for %s" % branch)

func _test_social_duplicate_guards() -> void:
	var runtime := _runtime(true)
	var residents: ResidentManager = runtime.residents
	var rabbit: RabbitData = runtime.rabbit
	var first := residents.interact("cafe_owner", "resident_talk", "guard_talk")
	var social_after := rabbit.social_experience
	var second := residents.interact("cafe_owner", "resident_talk", "guard_talk")
	_expect(first.success and not second.success and rabbit.social_experience == social_after, "Repeated interaction must not add Social EXP twice")
	_expect(residents.give_resident_gift("cafe_owner", "gift_guard", "carrot", 1), "First Resident Gift must apply")
	var amount_after: int = int(runtime.inventory.get_item_amount("carrot"))
	_expect(not residents.give_resident_gift("cafe_owner", "gift_guard", "carrot", 1) and runtime.inventory.get_item_amount("carrot") == amount_after, "Same Gift Event must not give item twice")

func _test_migration_regression() -> void:
	for old_version: int in [6, 7, 8, 9, 10]:
		var save := SaveData.new()
		save.save_version = old_version
		save.rabbits.append(RabbitData.new().to_dict())
		var manager := SaveManager.new()
		var migrated := manager.migrate_save_data(save)
		_expect(migrated != null and migrated.save_version == 10, "SaveVersion %d must migrate to Week 9 / Version 10" % old_version)
		_expect(migrated.resident_states is Dictionary, "SaveVersion %d must receive Resident structure" % old_version)
