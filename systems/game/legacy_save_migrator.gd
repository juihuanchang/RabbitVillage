class_name LegacySaveMigrator
extends RefCounted

const BUILDING_IDS := ["coffee_shop", "rest_pavilion", "notice_board", "carrot_farm"]
const WEEK4_EVENT_IDS := {
	"rest_pavilion": "village_rest_pavilion_001",
	"notice_board": "village_notice_board_001",
	"carrot_farm": "village_small_farm_001"
}
const LEGACY_FARM_SPROUT := "sprout"


## 將早期存放在 RabbitData 的村莊欄位轉成正式 VillageData。
static func migrate_rabbit_village_data(data: Dictionary) -> Dictionary:
	var source: Dictionary = data.get("village_data", {}) if data.get("village_data", {}) is Dictionary else {}
	var village := VillageData.from_dict(source)
	var old_snapshot: Variant = data.get("village_a_state", {})
	if village.legacy_a_snapshot.is_empty() and old_snapshot is Dictionary:
		village.legacy_a_snapshot = old_snapshot.duplicate(true)
	var old_placements: Variant = data.get("building_placements", {})
	if old_placements is Dictionary and not village.building_records.has("coffee_shop"):
		for raw_index: Variant in old_placements.keys():
			if str(old_placements[raw_index]) != "coffee_shop":
				continue
			var slot_index := clampi(int(raw_index), 0, 8)
			village.building_records["coffee_shop"] = {
				"building_id": "coffee_shop",
				"slot_id": "Slot%02d" % (slot_index + 1),
				"state": BuildingState.COMPLETED,
				"placed_at": 0.0,
				"completed_at": 0.0
			}
			village.building_interactions["completed_once:coffee_shop"] = true
			break
	return village.to_dict()


## 匯入早期第四週 A 版快照，並回傳 UI 顯示仍需要的暫存資料。
static func import_week4_snapshot(player: Variant, saved: Dictionary) -> Dictionary:
	var states: Dictionary = saved.get("states", {}).duplicate(true) if saved.get("states", {}) is Dictionary else {}
	var placements: Dictionary = saved.get("placements", {}).duplicate(true) if saved.get("placements", {}) is Dictionary else {}
	var construction_end: Dictionary = saved.get("construction_end", {}).duplicate(true) if saved.get("construction_end", {}) is Dictionary else {}
	var built_once: Dictionary = saved.get("built_once", {}).duplicate(true) if saved.get("built_once", {}) is Dictionary else {}
	var construction_record_ids: Dictionary = saved.get("c_construction_record_ids", {}).duplicate(true) if saved.get("c_construction_record_ids", {}) is Dictionary else {}
	var construction_started_at: Dictionary = saved.get("c_construction_started_at", {}).duplicate(true) if saved.get("c_construction_started_at", {}) is Dictionary else {}
	var carrots := int(saved.get("carrots", 0))
	var farm_state := str(saved.get("farm_state", FarmState.LOCKED))
	var farm_left := float(saved.get("farm_left", 0.0))
	var rest_left := float(saved.get("rest_left", 0.0))
	var rest_cooldown := float(saved.get("rest_cooldown", 0.0))

	var offline_seconds := maxf(0.0, Time.get_unix_time_from_system() - float(saved.get("saved_at", Time.get_unix_time_from_system())))
	rest_left = maxf(0.0, rest_left - offline_seconds)
	rest_cooldown = maxf(0.0, rest_cooldown - offline_seconds)
	while farm_left > 0.0 and offline_seconds > 0.0:
		if offline_seconds < farm_left:
			farm_left -= offline_seconds
			break
		offline_seconds -= farm_left
		farm_state = FarmState.GROWING if farm_state == LEGACY_FARM_SPROUT else FarmState.READY
		farm_left = 30.0 if farm_state == FarmState.GROWING else 0.0
	for building_id: String in states:
		if states[building_id] == BuildingState.COMPLETED:
			built_once[building_id] = true

	var has_gameplay_data := (
		saved.has("states")
		or saved.has("placements")
		or saved.has("construction_end")
		or saved.has("farm_state")
		or saved.has("rest_left")
	)
	if has_gameplay_data:
		_apply_week4_snapshot(player, states, placements, construction_end, carrots, farm_state, farm_left, rest_left, rest_cooldown)
	_clear_snapshot(player)

	return {
		"states": states,
		"placements": placements,
		"construction_end": construction_end,
		"built_once": built_once,
		"c_construction_record_ids": construction_record_ids,
		"c_construction_started_at": construction_started_at,
		"carrots": carrots,
		"farm_state": farm_state,
		"farm_left": farm_left,
		"rest_left": rest_left,
		"rest_cooldown": rest_cooldown
	}


static func _apply_week4_snapshot(
	player: Variant,
	states: Dictionary,
	placements: Dictionary,
	construction_end: Dictionary,
	carrots: int,
	farm_state: String,
	farm_left: float,
	rest_left: float,
	rest_cooldown: float
) -> void:
	for building_id in ["rest_pavilion", "notice_board", "carrot_farm"]:
		var state := str(states.get(building_id, BuildingState.LOCKED))
		if state != BuildingState.LOCKED:
			player.building_manager.unlock_building(building_id)
		if state == BuildingState.COMPLETED:
			player.building_manager.adopt_completed_building(building_id, _slot_id_from_index(int(placements.get(building_id, 0))))
		var event_id := str(WEEK4_EVENT_IDS.get(building_id, ""))
		if state != BuildingState.LOCKED and not event_id.is_empty() and not player.village_data.completed_village_event_ids.has(event_id):
			player.village_data.completed_village_event_ids.append(event_id)
			player.village_data.progress.completed_village_event_count += 1
	if carrots > player.farm_manager.get_carrot_amount():
		player.village_history_manager.add_carrots(carrots - player.farm_manager.get_carrot_amount(), TimeManager.get_now())
	if states.get("carrot_farm", BuildingState.LOCKED) == BuildingState.COMPLETED:
		player.farm_manager.migrate_legacy_state(farm_state, farm_left)
	var now := TimeManager.get_now()
	if rest_left > 0.0 and player.village_data.active_building_interaction.is_empty():
		player.village_data.active_building_interaction = {
			"interaction_record_id": "migrated_a_rest",
			"building_id": "rest_pavilion",
			"started_at": now,
			"ends_at": now + rest_left
		}
	if rest_cooldown > 0.0 and not player.village_data.building_interactions.has("rest_pavilion_cooldown_ends_at"):
		player.village_data.building_interactions["rest_pavilion_cooldown_ends_at"] = now + rest_cooldown
	if player.village_data.active_construction.is_empty():
		for building_id: String in construction_end:
			if str(states.get(building_id, "")) != BuildingState.CONSTRUCTING:
				continue
			var slot_id := _slot_id_from_index(int(placements.get(building_id, 0)))
			var ends_at := maxf(now, float(construction_end[building_id]))
			player.building_manager.unlock_building(building_id)
			player.village_data.building_records[building_id] = {
				"building_id": building_id,
				"slot_id": slot_id,
				"state": BuildingState.CONSTRUCTING,
				"placed_at": now
			}
			player.village_data.active_construction = {
				"construction_record_id": "migrated_a_construction_" + building_id,
				"building_id": building_id,
				"slot_id": slot_id,
				"started_at": now,
				"ends_at": ends_at
			}
			break


static func _clear_snapshot(player: Variant) -> void:
	player.village_data.legacy_a_snapshot = {}
	player.rabbit_data.village_data = player.village_data.to_dict()
	player.save_now()


static func _slot_id_from_index(index: int) -> String:
	return "Slot%02d" % (clampi(index, 0, 8) + 1)
