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


## 匯入早期介面版本的村莊快照，並回傳畫面仍需要的暫存資料。
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


## Week 4 (SaveVersion 5) -> Week 5 permanent resource migration.
## This function only moves/repairs stored data. It never grants a runtime reward.
static func migrate_week4_to_week5(save: SaveData) -> SaveData:
	if save == null:
		return null
	_migrate_carrot_inventory_once(save)
	_migrate_growth_path_progress(save)
	return save


static func _migrate_carrot_inventory_once(save: SaveData) -> void:
	# If Week 5 already has a valid carrot entry, never copy the legacy value again.
	if save.inventory.has("carrot") and save.inventory["carrot"] is Dictionary:
		var current := InventoryEntry.from_dict(save.inventory["carrot"])
		current.item_id = "carrot"
		current.amount = maxi(0, current.amount)
		current.total_obtained = maxi(current.amount, current.total_obtained)
		save.inventory["carrot"] = current.to_dict()
		return

	var village := VillageData.from_dict(save.village_data)
	var legacy := CarrotInventoryEntry.from_dict(village.carrot_inventory)
	if legacy.amount <= 0 and legacy.total_obtained <= 0:
		return
	var migrated := InventoryEntry.new()
	migrated.item_id = "carrot"
	migrated.amount = maxi(0, legacy.amount)
	migrated.total_obtained = maxi(migrated.amount, legacy.total_obtained)
	migrated.first_obtained_at = maxf(0.0, legacy.first_obtained_at)
	migrated.last_obtained_at = maxf(0.0, legacy.last_obtained_at)
	save.inventory["carrot"] = migrated.to_dict()

	# Collection keeps discovery-only information; it intentionally does not copy amount.
	var has_carrot_collection := false
	for raw: Dictionary in save.item_collection:
		if str(raw.get("item_id", "")) == "carrot":
			has_carrot_collection = true
			break
	if not has_carrot_collection and migrated.total_obtained > 0:
		save.item_collection.append({
			"item_id": "carrot",
			"is_discovered": true,
			"first_obtained_at": migrated.first_obtained_at,
			"first_source_type": "week4_migration",
			"first_source_id": "legacy_carrot_inventory"
		})


static func _migrate_growth_path_progress(save: SaveData) -> void:
	var forest_stage := maxi(0, int(save.growth_path_progress.get("forest_stage", 0)))
	var lakeside_stage := maxi(0, int(save.growth_path_progress.get("lakeside_stage", 0)))
	if _save_has_growth_mark(save, "leaf_mark"):
		forest_stage = maxi(forest_stage, 1)
	if _save_has_growth_mark(save, "sprout_mark"):
		forest_stage = maxi(forest_stage, 2)
	if _save_has_growth_mark(save, "lake_interest") or _save_has_growth_event(save, "growth_lake_interest_001"):
		lakeside_stage = maxi(lakeside_stage, 1)
	save.growth_path_progress["forest_stage"] = forest_stage
	save.growth_path_progress["lakeside_stage"] = lakeside_stage
	# FishingExperience / FishingCount are deliberately not touched here.


static func _save_has_growth_mark(save: SaveData, mark_id: String) -> bool:
	for raw: Dictionary in save.unlocked_growth_marks:
		if str(raw.get("id", "")) == mark_id:
			return true
	return false


static func _save_has_growth_event(save: SaveData, event_id: String) -> bool:
	for raw: Dictionary in save.journals:
		if str(raw.get("growth_event_id", "")) == event_id:
			return true
	return false


## Week 5 (SaveVersion 6) -> Week 6 shop / cooking / life-location migration.
## Only stored permanent data is normalized here. Runtime game rules stay owned by B.
static func migrate_week5_to_week6(save: SaveData) -> SaveData:
	if save == null:
		return null
	_migrate_week6_shop_unlock(save)
	_migrate_week6_food_history(save)
	_migrate_week6_recipe_collection(save)
	_repair_week6_transaction_guards(save)
	return save


static func _migrate_week6_shop_unlock(save: SaveData) -> void:
	if save.completed_life_event_ids.has("village_life_expands_001"):
		save.shop_state["village_shop_unlocked"] = true


static func _migrate_week6_food_history(save: SaveData) -> void:
	for index: int in save.food_use_history.size():
		var raw := save.food_use_history[index].duplicate(true)
		if not raw.has("energy_change"):
			raw["energy_change"] = 0
		if not raw.has("mood_change"):
			raw["mood_change"] = 0
		save.food_use_history[index] = raw


static func _migrate_week6_recipe_collection(save: SaveData) -> void:
	# Week 5 legitimately has no recipe collection. SaveData already initializes it as an empty array.
	# This function intentionally does not invent recipe discoveries during migration.
	if save.recipe_collection.is_empty():
		return


static func _repair_week6_transaction_guards(save: SaveData) -> void:
	var applied_purchase_ids: Array = []
	var raw_purchase_ids: Variant = save.shop_state.get("applied_purchase_ids", [])
	if raw_purchase_ids is Array:
		applied_purchase_ids = raw_purchase_ids.duplicate()
	for raw: Dictionary in save.purchase_history:
		var record_id := str(raw.get("purchase_record_id", ""))
		if not record_id.is_empty() and not applied_purchase_ids.has(record_id):
			applied_purchase_ids.append(record_id)
	save.shop_state["applied_purchase_ids"] = applied_purchase_ids

	var applied_cooking_ids: Array = []
	var raw_cooking_ids: Variant = save.cooking_state.get("applied_cooking_ids", [])
	if raw_cooking_ids is Array:
		applied_cooking_ids = raw_cooking_ids.duplicate()
	for raw: Dictionary in save.cooking_history:
		var record_id := str(raw.get("cooking_record_id", ""))
		if not record_id.is_empty() and not applied_cooking_ids.has(record_id):
			applied_cooking_ids.append(record_id)
	save.cooking_state["applied_cooking_ids"] = applied_cooking_ids


## Week 6 (SaveVersion 7) -> Week 7 building / Café / advanced-growth migration.
## The migration preserves the old VillageData runtime structure and only adds the
## new canonical C-owned permanent layer. It never spends Currency or Inventory.
static func migrate_week6_to_week7(save: SaveData) -> SaveData:
	if save == null:
		return null
	_migrate_week7_building_layer(save)
	_migrate_week7_cafe_layer(save)
	_migrate_week7_growth_layer(save)
	return save

static func _migrate_week7_building_layer(save: SaveData) -> void:
	var village := VillageData.from_dict(save.village_data)
	var cafe_record: Dictionary = {}
	if village.building_records.has("coffee_shop") and village.building_records["coffee_shop"] is Dictionary:
		cafe_record = village.building_records["coffee_shop"].duplicate(true)
	elif village.building_records.has("cafe") and village.building_records["cafe"] is Dictionary:
		cafe_record = village.building_records["cafe"].duplicate(true)

	if village.unlocked_building_ids.has("coffee_shop") or save.completed_life_event_ids.has("cafe_barista_arrives_001") or not cafe_record.is_empty():
		if not save.unlocked_building_ids.has("cafe"):
			save.unlocked_building_ids.append("cafe")
		if save.building_unlock_history.is_empty():
			var unlock := BuildingUnlockHistoryEntry.new()
			unlock.building_id = "cafe"
			unlock.unlocked_at = _week7_life_event_time(save, "cafe_barista_arrives_001")
			unlock.source_event_id = "cafe_barista_arrives_001" if save.completed_life_event_ids.has("cafe_barista_arrives_001") else "week7_migration"
			save.building_unlock_history.append(unlock.to_dict())

	if not save.buildable_building_ids.has("cafe"):
		save.buildable_building_ids.append("cafe")

	if not cafe_record.is_empty():
		var slot_id := _week7_canonical_slot(str(cafe_record.get("slot_id", "")))
		if not slot_id.is_empty():
			var already_placed := false
			for raw: Dictionary in save.building_placement_history:
				if str(raw.get("building_id", "")) == "cafe":
					already_placed = true
					break
			if not already_placed:
				var placement := BuildingPlacementHistoryEntry.new()
				placement.building_id = "cafe"
				placement.slot_id = slot_id
				placement.placed_at = maxf(0.0, float(cafe_record.get("placed_at", 0.0)))
				save.building_placement_history.append(placement.to_dict())
			var occupied := false
			for canonical_slot: String in SaveData.WEEK7_BUILDING_SLOTS:
				if str(save.building_slots.get(canonical_slot, "")) == "cafe":
					occupied = true
					break
			if not occupied:
				save.building_slots[slot_id] = "cafe"

	# Extend, don't replace, the Fourth-week ConstructionHistory.
	for raw: Dictionary in village.construction_records:
		var legacy := ConstructionHistoryEntry.from_dict(raw)
		if legacy.building_id not in ["coffee_shop", "cafe"]:
			continue
		legacy.building_id = "cafe"
		legacy.slot_id = _week7_canonical_slot(legacy.slot_id)
		if legacy.slot_id.is_empty() or legacy.construction_record_id.is_empty():
			continue
		var exists := false
		for existing_raw: Dictionary in save.construction_history:
			if str(existing_raw.get("construction_record_id", existing_raw.get("construction_id", ""))) == legacy.construction_record_id:
				exists = true
				break
		if not exists:
			save.construction_history.append(legacy.to_dict())

	if not village.active_construction.is_empty():
		var active := ConstructionHistoryEntry.from_dict(village.active_construction)
		if active.building_id in ["coffee_shop", "cafe"]:
			active.building_id = "cafe"
			active.slot_id = _week7_canonical_slot(active.slot_id)
			if not active.slot_id.is_empty() and not active.construction_record_id.is_empty():
				var definition_cost := _week7_cafe_cost()
				active.coin_cost = int(definition_cost.get("coin_cost", 0))
				active.material_costs = definition_cost.get("material_costs", {}).duplicate(true)
				var active_exists := false
				for existing_raw: Dictionary in save.active_constructions:
					if str(existing_raw.get("construction_record_id", existing_raw.get("construction_id", ""))) == active.construction_record_id:
						active_exists = true
						break
				if not active_exists:
					save.active_constructions.append(active.to_dict())
				var history_exists := false
				for existing_raw: Dictionary in save.construction_history:
					if str(existing_raw.get("construction_record_id", existing_raw.get("construction_id", ""))) == active.construction_record_id:
						history_exists = true
						break
				if not history_exists:
					save.construction_history.append(active.to_dict())

	# Old BuildingHistory remains in VillageData. Copy only the café facts into the
	# new canonical Week 7 layer so older saves gain the new permanent history.
	for raw: Dictionary in village.building_history:
		var legacy_building := BuildingHistoryEntry.from_dict(raw)
		if legacy_building.building_id not in ["coffee_shop", "cafe"]:
			continue
		if legacy_building.unlocked_at > 0.0 and save.building_unlock_history.is_empty():
			var unlock := BuildingUnlockHistoryEntry.new()
			unlock.building_id = "cafe"
			unlock.unlocked_at = legacy_building.unlocked_at
			unlock.source_event_id = "week4_building_history"
			save.building_unlock_history.append(unlock.to_dict())
		if not legacy_building.slot_id.is_empty():
			var slot_id := _week7_canonical_slot(legacy_building.slot_id)
			if not slot_id.is_empty() and save.building_placement_history.is_empty():
				var placement := BuildingPlacementHistoryEntry.new()
				placement.building_id = "cafe"
				placement.slot_id = slot_id
				placement.placed_at = legacy_building.placed_at
				save.building_placement_history.append(placement.to_dict())

static func _migrate_week7_cafe_layer(save: SaveData) -> void:
	var migrated_exp := maxi(0, save.cafe_experience)
	for raw: Dictionary in save.rabbits:
		migrated_exp = maxi(migrated_exp, int(raw.get("cafe_experience", 0)))
	save.cafe_experience = migrated_exp

static func _migrate_week7_growth_layer(save: SaveData) -> void:
	var forest_stage := maxi(0, int(save.growth_path_progress.get("forest_stage", 0)))
	var lakeside_stage := maxi(0, int(save.growth_path_progress.get("lakeside_stage", 0)))
	if _save_has_growth_mark(save, "forest_stage3") or _save_has_growth_event(save, "growth_forest_stage3_001"):
		forest_stage = maxi(forest_stage, 3)
	if _save_has_growth_mark(save, "lakeside_stage2") or _save_has_growth_event(save, "growth_lakeside_stage2_001"):
		lakeside_stage = maxi(lakeside_stage, 2)
	save.growth_path_progress["forest_stage"] = forest_stage
	save.growth_path_progress["lakeside_stage"] = lakeside_stage
	if forest_stage >= 3:
		save.growth_appearance_state = "forest_stage3"
	elif lakeside_stage >= 2:
		save.growth_appearance_state = "lakeside_stage2"
	elif forest_stage >= 2:
		save.growth_appearance_state = "sprout"
	elif forest_stage >= 1:
		save.growth_appearance_state = "leaf"
	else:
		save.growth_appearance_state = "normal"

static func _week7_canonical_slot(slot_id: String) -> String:
	if SaveData.WEEK7_BUILDING_SLOTS.has(slot_id):
		return slot_id
	if slot_id.begins_with("Slot"):
		var suffix := slot_id.trim_prefix("Slot")
		if suffix.is_valid_int():
			var index := int(suffix)
			if index >= 1 and index <= 5:
				return "building_slot_%02d" % index
	return ""

static func _week7_life_event_time(save: SaveData, event_id: String) -> float:
	for raw: Dictionary in save.life_event_history:
		if str(raw.get("life_event_id", "")) == event_id:
			return maxf(0.0, float(raw.get("confirmed_at", 0.0)))
	return 0.0

static func _week7_cafe_cost() -> Dictionary:
	# Mirrors B's current café definition only as permanent transaction metadata.
	# C never spends these resources itself.
	return {"coin_cost": 80, "material_costs": {"twig": 10, "driftwood": 5, "small_stone": 4}}
