class_name DiaryManager
extends Node

signal journal_added(entry: JournalEntry)
signal journals_changed

var _journals: Array[JournalEntry] = []
var _last_food_journal_date := ""
var _last_needs_journal_date := ""
var _last_shopping_journal_date := ""
var _last_cooking_journal_date := ""
var _last_picnic_journal_date := ""

func create_journal_from_activity(active: ActiveActivityData) -> JournalEntry:
	if active == null or active.activity_record_id.is_empty() or has_activity_record_id(active.activity_record_id):
		return null
	return _append(JournalGenerator.generate(active, _next_id()))

func create_growth_journal(rabbit_name: String, mark: String, at: float = -1.0) -> JournalEntry:
	if mark.is_empty() or has_journal_for_growth_mark(mark):
		return null
	return _append(JournalGenerator.generate_growth_journal(rabbit_name, _next_id(), mark, at))

func generate_village_event_journal(id: String, rabbit_name := "Amy", at: float = -1.0, stage := 0) -> JournalEntry:
	if id.is_empty() or has_journal_for_village_event(id):
		return null
	return _append(JournalGenerator.generate_village_event_journal(rabbit_name, _next_id(), id, at, stage))

func generate_construction_start_journal(record: ConstructionRecord, rabbit_name := "Amy", stage := 0) -> JournalEntry:
	if record == null or record.construction_record_id.is_empty() or _has_construction_phase(record.construction_record_id, "construction"):
		return null
	return _append(JournalGenerator.generate_construction_journal(rabbit_name, _next_id(), record.construction_record_id, record.building_id, "start", record.started_at, stage))

func generate_construction_journal(result: ConstructionResult, rabbit_name := "Amy", stage := 0) -> JournalEntry:
	if result == null or result.construction_record_id.is_empty() or _has_construction_phase(result.construction_record_id, "building_complete"):
		return null
	return _append(JournalGenerator.generate_construction_journal(rabbit_name, _next_id(), result.construction_record_id, result.building_id, "complete", result.completed_at, stage))

func generate_building_use_journal(result: BuildingUseResult, rabbit_name := "Amy", stage := 0) -> JournalEntry:
	if result == null:
		return null
	var record_id := result.building_use_record_id if not result.building_use_record_id.is_empty() else result.interaction_record_id
	if record_id.is_empty() or has_journal_for_building_use(record_id):
		return null
	return _append(JournalGenerator.generate_building_use_journal(rabbit_name, _next_id(), result, result.is_first_use or not _has_any_building_use(result.building_id), stage))

func generate_notice_journal(record: DailyNoticeRecord, rabbit_name := "Amy", stage := 0) -> JournalEntry:
	if record == null or _has_notice_date(record.date_key):
		return null
	return _append(JournalGenerator.generate_notice_journal(rabbit_name, _next_id(), record, stage))

func generate_farm_growth_journal(cycle: FarmCycleData, rabbit_name := "Amy", stage := 0) -> JournalEntry:
	if cycle == null or cycle.farm_cycle_id.is_empty() or has_journal_for_farm_cycle(cycle.farm_cycle_id):
		return null
	return _append(JournalGenerator.generate_farm_growth_journal(rabbit_name, _next_id(), cycle, not _has_type("farm_growth"), stage))

func generate_harvest_journal(result: HarvestResult, rabbit_name := "Amy", stage := 0) -> JournalEntry:
	if result == null or result.harvest_record_id.is_empty() or has_journal_for_harvest(result.harvest_record_id):
		return null
	return _append(JournalGenerator.generate_harvest_journal(rabbit_name, _next_id(), result, result.is_first_harvest or not _has_type("harvest"), stage))

func generate_village_growth_journal(stage: int, rabbit_name := "Amy", at: float = -1.0) -> JournalEntry:
	if stage <= 0 or _has_stage(stage):
		return null
	return _append(JournalGenerator.generate_village_growth_journal(rabbit_name, _next_id(), stage, at))

# ---------------- Week 5 ----------------

func setup_week5_limits(last_food_date: String, last_needs_date: String) -> void:
	_last_food_journal_date = last_food_date
	_last_needs_journal_date = last_needs_date
	_rebuild_week5_dates_from_journals()

func generate_food_use_journal(result: FoodUseResult, rabbit_name := "Amy", first_use := false) -> JournalEntry:
	if result == null or result.food_use_record_id.is_empty() or has_journal_for_food_use(result.food_use_record_id):
		return null
	var date_key := _date_key(result.used_at)
	if not first_use and not date_key.is_empty() and _last_food_journal_date == date_key:
		return null
	var entry := _append(JournalGenerator.generate_food_use_journal(rabbit_name, _next_id(), result, first_use))
	if entry != null and not first_use:
		_last_food_journal_date = date_key
	return entry

func generate_needs_journal_from_states(
	rabbit: RabbitData,
	hunger_state: String,
	energy_state: String,
	mood_state: String,
	rabbit_name := "Amy",
	at: float = -1.0
) -> JournalEntry:
	if rabbit == null:
		return null
	var timestamp := TimeManager.get_now() if at <= 0.0 else at
	var date_key := _date_key(timestamp)
	if date_key.is_empty() or _last_needs_journal_date == date_key:
		return null
	var need_key := _get_need_key_from_states(hunger_state, energy_state, mood_state)
	if need_key.is_empty():
		return null
	var stats := {"hunger": rabbit.hunger, "energy": rabbit.energy, "mood": rabbit.mood}
	var entry := _append(JournalGenerator.generate_needs_journal(rabbit_name, _next_id(), need_key, timestamp, stats))
	if entry != null:
		_last_needs_journal_date = date_key
	return entry

func generate_item_discovery_journal(discovery: ItemDiscoveryHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if discovery == null or discovery.discovery_id.is_empty() or discovery.item_id.is_empty():
		return null
	if has_journal_for_item_discovery(discovery.item_id, discovery.discovery_id):
		return null
	return _append(JournalGenerator.generate_item_discovery_journal(rabbit_name, _next_id(), discovery))

func generate_life_event_journal(event_id: String, rabbit_name := "Amy", at: float = -1.0) -> JournalEntry:
	if event_id.is_empty() or has_journal_for_life_event(event_id):
		return null
	return _append(JournalGenerator.generate_life_event_journal(rabbit_name, _next_id(), event_id, at))

func generate_growth_event_journal(
	event_id: String,
	growth_path: String,
	growth_stage: int,
	growth_mark_id: String,
	rabbit_name := "Amy",
	at: float = -1.0
) -> JournalEntry:
	if event_id.is_empty() or has_journal_for_growth_event(event_id):
		return null
	if not growth_mark_id.is_empty() and has_journal_for_growth_mark(growth_mark_id):
		# leaf_mark is an older special journal; do not create a duplicate week-five memory for it.
		if growth_mark_id == "leaf_mark":
			return null
	var entry := JournalGenerator.generate_growth_event_journal(rabbit_name, _next_id(), event_id, growth_path, growth_stage, growth_mark_id, at)
	return _append(entry)

func generate_growth_lifestyle_journal(
	growth_path: String,
	growth_stage: int,
	source_record_id: String,
	rabbit_name := "Amy",
	at: float = -1.0
) -> JournalEntry:
	if source_record_id.is_empty() or has_growth_lifestyle_for_source(source_record_id):
		return null
	if growth_path == "forest" and growth_stage < 2:
		return null
	if growth_path == "lakeside" and growth_stage < 1:
		return null
	return _append(JournalGenerator.generate_growth_lifestyle_journal(rabbit_name, _next_id(), growth_path, growth_stage, source_record_id, at))


# ---------------- Week 6 ----------------

func setup_week6_limits(last_shopping_date: String, last_cooking_date: String, last_picnic_date: String) -> void:
	_last_shopping_journal_date = last_shopping_date
	_last_cooking_journal_date = last_cooking_date
	_last_picnic_journal_date = last_picnic_date
	_rebuild_week6_dates_from_journals()

func generate_first_purchase_journal(result: PurchaseResult, rabbit_name := "Amy") -> JournalEntry:
	if result == null or result.purchase_record_id.is_empty() or _has_type("first_purchase"):
		return null
	return _append(JournalGenerator.generate_first_purchase_journal(rabbit_name, _next_id(), result))

func generate_shopping_journal(result: PurchaseResult, rabbit_name := "Amy") -> JournalEntry:
	if result == null or result.purchase_record_id.is_empty() or has_journal_for_purchase(result.purchase_record_id):
		return null
	var day_key := _date_key(result.purchased_at)
	if day_key.is_empty() or _last_shopping_journal_date == day_key:
		return null
	var entry := _append(JournalGenerator.generate_shopping_journal(rabbit_name, _next_id(), result))
	if entry != null:
		_last_shopping_journal_date = day_key
	return entry

func generate_product_unlock_journal(product: ShopProductData, rabbit_name := "Amy") -> JournalEntry:
	if product == null or product.product_id.is_empty() or has_journal_for_product_unlock(product.product_id):
		return null
	return _append(JournalGenerator.generate_product_unlock_journal(rabbit_name, _next_id(), product))

func generate_week6_food_journal(result: FoodUseResult, rabbit_name := "Amy", first_use := false) -> JournalEntry:
	if result == null or result.food_use_record_id.is_empty() or result.food_id == "carrot":
		return null
	if has_journal_for_food_use(result.food_use_record_id):
		return null
	return _append(JournalGenerator.generate_week6_food_journal(rabbit_name, _next_id(), result, first_use))

func generate_first_cooking_journal(result: CookingResult, recipe_id: String, rabbit_name := "Amy") -> JournalEntry:
	if result == null or result.cooking_record_id.is_empty() or _has_type("first_cooking"):
		return null
	return _append(JournalGenerator.generate_first_cooking_journal(rabbit_name, _next_id(), result, recipe_id))

func generate_cooking_journal(result: CookingResult, recipe_id: String, rabbit_name := "Amy") -> JournalEntry:
	if result == null or result.cooking_record_id.is_empty() or has_journal_for_cooking(result.cooking_record_id):
		return null
	var day_key := _date_key(result.cooked_at)
	if day_key.is_empty() or _last_cooking_journal_date == day_key:
		return null
	var entry := _append(JournalGenerator.generate_cooking_journal(rabbit_name, _next_id(), result, recipe_id))
	if entry != null:
		_last_cooking_journal_date = day_key
	return entry

func generate_recipe_discovery_journal(result: CookingResult, recipe_id: String, rabbit_name := "Amy") -> JournalEntry:
	if result == null or result.cooking_record_id.is_empty() or recipe_id.is_empty() or has_journal_for_recipe(recipe_id):
		return null
	return _append(JournalGenerator.generate_recipe_discovery_journal(rabbit_name, _next_id(), result, recipe_id))

func generate_picnic_journal(result: LifeLocationResult, rabbit_name := "Amy") -> JournalEntry:
	if result == null or result.location_record_id.is_empty() or has_journal_for_life_location(result.location_record_id):
		return null
	var day_key := _date_key(result.completed_at)
	if day_key.is_empty() or _last_picnic_journal_date == day_key:
		return null
	var entry := _append(JournalGenerator.generate_picnic_journal(rabbit_name, _next_id(), result))
	if entry != null:
		_last_picnic_journal_date = day_key
	return entry

func generate_picnic_food_journal(result: LifeLocationResult, food_id: String, rabbit_name := "Amy") -> JournalEntry:
	if result == null or result.location_record_id.is_empty() or food_id.is_empty() or has_picnic_food_journal_for_location(result.location_record_id):
		return null
	return _append(JournalGenerator.generate_picnic_food_journal(rabbit_name, _next_id(), result, food_id))

func generate_week6_event_journal(event_id: String, rabbit_name := "Amy", at: float = -1.0) -> JournalEntry:
	if event_id.is_empty() or has_journal_for_week6_event(event_id):
		return null
	return _append(JournalGenerator.generate_week6_event_journal(rabbit_name, _next_id(), event_id, at))

func get_last_shopping_journal_date() -> String:
	return _last_shopping_journal_date

func get_last_cooking_journal_date() -> String:
	return _last_cooking_journal_date

func get_last_picnic_journal_date() -> String:
	return _last_picnic_journal_date

func has_journal_for_purchase(record_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.purchase_record_id == record_id and entry.journal_type in ["first_purchase", "shopping"]:
			return true
	return false

func has_journal_for_product_unlock(product_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "product_unlock" and entry.product_id == product_id:
			return true
	return false

func has_journal_for_cooking(record_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.cooking_record_id == record_id and entry.journal_type in ["first_cooking", "cooking", "recipe_discovery"]:
			return true
	return false

func has_journal_for_recipe(recipe_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "recipe_discovery" and entry.recipe_id == recipe_id:
			return true
	return false

func has_journal_for_life_location(record_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.life_location_id == record_id and entry.journal_type == "picnic":
			return true
	return false

func has_picnic_food_journal_for_location(record_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.life_location_id == record_id and entry.journal_type == "picnic_food":
			return true
	return false

func has_journal_for_week6_event(event_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.shop_event_id == event_id or entry.cooking_event_id == event_id or entry.picnic_event_id == event_id:
			return true
		if entry.journal_type == "week6_finale" and entry.life_event_id == event_id:
			return true
	return false

# ---------------- Week 7 ----------------

func generate_week7_building_unlock_journal(entry: BuildingUnlockHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if entry == null or entry.building_id.is_empty() or has_week7_building_unlock_journal(entry.building_id):
		return null
	return _append(JournalGenerator.generate_week7_building_unlock_journal(rabbit_name, _next_id(), entry))

func generate_week7_building_placement_journal(entry: BuildingPlacementHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if entry == null or entry.building_id.is_empty() or entry.slot_id.is_empty() or has_week7_building_placement_journal(entry.building_id):
		return null
	return _append(JournalGenerator.generate_week7_building_placement_journal(rabbit_name, _next_id(), entry))

func generate_week7_construction_journal(entry: ConstructionHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if entry == null or entry.construction_record_id.is_empty() or has_week7_construction_journal(entry.construction_record_id, false):
		return null
	return _append(JournalGenerator.generate_week7_construction_journal(rabbit_name, _next_id(), entry))

func generate_week7_cafe_complete_journal(entry: ConstructionHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if entry == null or entry.construction_record_id.is_empty() or has_week7_construction_journal(entry.construction_record_id, true):
		return null
	return _append(JournalGenerator.generate_week7_cafe_complete_journal(rabbit_name, _next_id(), entry))

func generate_week7_cafe_activity_journal(entry: CafeActivityHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if entry == null or entry.activity_record_id.is_empty() or has_week7_cafe_activity_journal(entry.activity_record_id):
		return null
	return _append(JournalGenerator.generate_week7_cafe_activity_journal(rabbit_name, _next_id(), entry))

func generate_week7_cafe_event_journal(event_id: String, rabbit_name := "Amy", at: float = -1.0) -> JournalEntry:
	if event_id.is_empty() or has_week7_cafe_event_journal(event_id):
		return null
	return _append(JournalGenerator.generate_week7_cafe_event_journal(rabbit_name, _next_id(), event_id, at))

func generate_week7_growth_journal(event_id: String, growth_path: String, growth_stage: int, growth_mark_id: String, rabbit_name := "Amy", at: float = -1.0) -> JournalEntry:
	if event_id.is_empty() or has_journal_for_growth_event(event_id):
		return null
	return _append(JournalGenerator.generate_week7_growth_journal(rabbit_name, _next_id(), event_id, growth_path, growth_stage, growth_mark_id, at))

func generate_week7_growth_reaction_journal(source_record_id: String, growth_path: String, growth_stage: int, rabbit_name := "Amy", at: float = -1.0) -> JournalEntry:
	if source_record_id.is_empty() or has_week7_growth_reaction_for_source(source_record_id):
		return null
	if growth_path == "forest" and growth_stage < 3:
		return null
	if growth_path == "lakeside" and growth_stage < 2:
		return null
	return _append(JournalGenerator.generate_week7_growth_reaction_journal(rabbit_name, _next_id(), source_record_id, growth_path, growth_stage, at))

func generate_week7_village_progress_journal(entry: VillageProgressHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if entry == null or entry.village_progress_event_id.is_empty() or has_week7_village_progress_journal(entry.village_progress_event_id):
		return null
	return _append(JournalGenerator.generate_week7_village_progress_journal(rabbit_name, _next_id(), entry))

func generate_week7_finale_journal(event_id: String, rabbit_name := "Amy", at: float = -1.0) -> JournalEntry:
	if event_id.is_empty() or has_journal_for_life_event(event_id):
		return null
	return _append(JournalGenerator.generate_week7_finale_journal(rabbit_name, _next_id(), event_id, at))

func has_week7_building_unlock_journal(building_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "building_unlock" and entry.building_id == building_id:
			return true
	return false

func has_week7_building_placement_journal(building_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "building_placement" and entry.building_id == building_id:
			return true
	return false

func has_week7_construction_journal(record_id: String, completed: bool) -> bool:
	var expected := "cafe_complete" if completed else "week7_construction"
	for entry: JournalEntry in _journals:
		if entry.journal_type == expected and (entry.construction_id == record_id or entry.construction_record_id == record_id):
			return true
	return false

func has_week7_cafe_activity_journal(record_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "cafe_activity" and entry.activity_record_id == record_id:
			return true
	return false

func has_week7_cafe_event_journal(event_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "cafe_event" and entry.life_event_id == event_id:
			return true
	return false

func has_week7_growth_reaction_for_source(record_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "growth_reaction" and entry.activity_record_id == record_id:
			return true
	return false

func has_week7_village_progress_journal(event_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "village_progress" and entry.village_progress_event_id == event_id:
			return true
	return false

# ---------------- Week 8 ----------------

func generate_week8_growth_direction_journal(choice: GrowthDirectionChoiceHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if choice == null or choice.choice_id.is_empty() or has_week8_growth_direction_journal(choice.choice_id):
		return null
	return _append(JournalGenerator.generate_week8_growth_direction_journal(rabbit_name, _next_id(), choice))

func generate_week8_balanced_journal(choice: GrowthDirectionChoiceHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if choice == null or choice.choice_id.is_empty() or has_week8_balanced_journal(choice.choice_id):
		return null
	return _append(JournalGenerator.generate_week8_balanced_journal(rabbit_name, _next_id(), choice))

func generate_week8_final_growth_journal(history: FinalGrowthHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if history == null or history.final_growth_record_id.is_empty() or has_week8_final_growth_journal(history.final_growth_record_id):
		return null
	return _append(JournalGenerator.generate_week8_final_growth_journal(rabbit_name, _next_id(), history))

func generate_week8_final_reaction_journal(source_record_id: String, context: String, final_form: String, rabbit_name := "Amy", at: float = -1.0) -> JournalEntry:
	if source_record_id.is_empty() or final_form.is_empty() or has_week8_final_reaction(source_record_id):
		return null
	return _append(JournalGenerator.generate_week8_final_reaction_journal(rabbit_name, _next_id(), source_record_id, context, final_form, at, false))

func generate_week8_stage1_journal(history: StageCompletionHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if history == null or history.stage_id.is_empty() or has_week8_stage1_journal(history.source_event_id):
		return null
	return _append(JournalGenerator.generate_week8_stage1_journal(rabbit_name, _next_id(), history))

func generate_week8_life_resume_journal(profile_snapshot_id: String, rabbit_name := "Amy", at: float = -1.0) -> JournalEntry:
	if profile_snapshot_id.is_empty() or has_week8_life_resume_journal(profile_snapshot_id):
		return null
	return _append(JournalGenerator.generate_week8_life_resume_journal(rabbit_name, _next_id(), profile_snapshot_id, at))

func generate_week8_ending_journal(history: EndingHistoryEntry, rabbit_name := "Amy") -> JournalEntry:
	if history == null or history.ending_id.is_empty() or has_week8_ending_journal(history.ending_id):
		return null
	return _append(JournalGenerator.generate_week8_ending_journal(rabbit_name, _next_id(), history))

func generate_week8_post_ending_journal(source_record_id: String, final_form: String, rabbit_name := "Amy", at: float = -1.0, context: String = "") -> JournalEntry:
	if source_record_id.is_empty() or has_week8_post_ending_journal(source_record_id):
		return null
	return _append(JournalGenerator.generate_week8_post_ending_journal(rabbit_name, _next_id(), source_record_id, final_form, at, context))

func has_week8_growth_direction_journal(choice_id: String) -> bool:
	if choice_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.journal_type == "growth_direction" and entry.growth_direction_choice_id == choice_id:
			return true
	return false

func has_week8_balanced_journal(choice_id: String) -> bool:
	if choice_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.journal_type == "balanced" and entry.growth_direction_choice_id == choice_id:
			return true
	return false

func has_week8_final_growth_journal(record_id: String) -> bool:
	if record_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.journal_type == "final_growth" and entry.final_growth_record_id == record_id:
			return true
	return false

func has_week8_final_reaction(source_record_id: String) -> bool:
	if source_record_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.journal_type == "final_reaction" and (entry.activity_record_id == source_record_id or entry.life_location_id == source_record_id):
			return true
	return false

func has_week8_stage1_journal(stage_id: String = "village_stage1_complete_001") -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "village_stage1" and entry.village_progress_event_id == stage_id:
			return true
	return false

func has_week8_life_resume_journal(snapshot_id: String) -> bool:
	if snapshot_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.journal_type == "life_resume" and entry.life_profile_snapshot_id == snapshot_id:
			return true
	return false

func has_week8_ending_journal(ending_id: String) -> bool:
	if ending_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.journal_type == "ending" and entry.ending_id == ending_id:
			return true
	return false

func has_week8_post_ending_journal(source_record_id: String) -> bool:
	if source_record_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.journal_type == "post_ending" and entry.activity_record_id == source_record_id:
			return true
	return false

func get_last_food_journal_date() -> String:
	return _last_food_journal_date

func get_last_needs_journal_date() -> String:
	return _last_needs_journal_date

func has_activity_record_id(id: String) -> bool:
	for entry: JournalEntry in _journals:
		if not id.is_empty() and entry.activity_record_id == id and entry.journal_type in ["activity", "home"]:
			return true
	return false

func has_journal_for_growth_mark(id: String) -> bool:
	if id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.growth_mark_id == id and entry.journal_type in ["growth", "growth_event"]:
			return true
	return false

func has_journal_for_growth_event(event_id: String) -> bool:
	if event_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.growth_event_id == event_id:
			return true
	return false

func get_journal_for_growth_event(event_id: String) -> JournalEntry:
	if event_id.is_empty():
		return null
	for entry: JournalEntry in _journals:
		if entry.growth_event_id == event_id:
			return entry
	return null

func has_journal_for_village_event(id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.village_event_id == id:
			return true
	return false

func has_journal_for_construction(id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.construction_record_id == id:
			return true
	return false

func has_journal_for_building_use(id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.building_use_record_id == id:
			return true
	return false

func has_journal_for_farm_cycle(id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "farm_growth" and entry.farm_cycle_id == id:
			return true
	return false

func has_journal_for_harvest(id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.harvest_record_id == id:
			return true
	return false

func has_journal_for_food_use(record_id: String) -> bool:
	if record_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.food_use_record_id == record_id:
			return true
	return false

func has_journal_for_item_discovery(item_id: String, discovery_id: String = "") -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type != "item_discovery":
			continue
		if entry.item_id == item_id:
			return true
		if not discovery_id.is_empty() and entry.item_discovery_id == discovery_id:
			return true
	return false

func has_journal_for_life_event(event_id: String) -> bool:
	if event_id.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.life_event_id == event_id:
			return true
	return false

func has_growth_lifestyle_for_source(source_record_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "growth_lifestyle" and entry.activity_record_id == source_record_id:
			return true
	return false

func _has_construction_phase(id: String, journal_type: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.construction_record_id == id and entry.journal_type == journal_type:
			return true
	return false

func _has_any_building_use(id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "building_use" and entry.building_id == id:
			return true
	return false

func _has_notice_date(date_key: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "notice" and entry.notice_date == date_key:
			return true
	return false

func _has_type(journal_type: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == journal_type:
			return true
	return false

func _has_stage(stage: int) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_type == "village_growth" and entry.village_stage == stage:
			return true
	return false

func get_all_journals() -> Array[JournalEntry]:
	var result: Array[JournalEntry] = []
	result.assign(_journals)
	result.sort_custom(func(a: JournalEntry, b: JournalEntry) -> bool:
		return a.created_at > b.created_at
	)
	return result

func get_latest_journal() -> JournalEntry:
	var all := get_all_journals()
	return all[0] if not all.is_empty() else null

func get_journal_count() -> int:
	return _journals.size()

func clear_journals() -> void:
	_journals.clear()
	_last_food_journal_date = ""
	_last_needs_journal_date = ""
	_last_shopping_journal_date = ""
	_last_cooking_journal_date = ""
	_last_picnic_journal_date = ""
	journals_changed.emit()

func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: JournalEntry in _journals:
		result.append(entry.to_dict())
	return result

func load_from_array(data: Array) -> void:
	_journals.clear()
	for raw: Variant in data:
		if raw is Dictionary:
			var entry := JournalEntry.from_dict(raw)
			if entry.is_valid() and not _duplicate(entry):
				_journals.append(entry)
	_rebuild_week5_dates_from_journals()
	_rebuild_week6_dates_from_journals()
	journals_changed.emit()

func _duplicate(entry: JournalEntry) -> bool:
	match entry.journal_type:
		"growth":
			return has_journal_for_growth_mark(entry.growth_mark_id)
		"activity", "home":
			return has_activity_record_id(entry.activity_record_id)
		"village_event":
			return has_journal_for_village_event(entry.village_event_id)
		"construction", "building_complete":
			return _has_construction_phase(entry.construction_record_id, entry.journal_type)
		"building_use":
			return has_journal_for_building_use(entry.building_use_record_id)
		"notice":
			return _has_notice_date(entry.notice_date)
		"farm_growth":
			return has_journal_for_farm_cycle(entry.farm_cycle_id)
		"harvest":
			return has_journal_for_harvest(entry.harvest_record_id)
		"village_growth":
			return _has_stage(entry.village_stage)
		"food_use":
			return has_journal_for_food_use(entry.food_use_record_id)
		"needs":
			return _has_needs_date(_date_key(entry.created_at))
		"item_discovery":
			return has_journal_for_item_discovery(entry.item_id, entry.item_discovery_id)
		"life_event", "week5_finale":
			return has_journal_for_life_event(entry.life_event_id)
		"growth_event":
			return has_journal_for_growth_event(entry.growth_event_id)
		"growth_lifestyle":
			return has_growth_lifestyle_for_source(entry.activity_record_id)
		"first_purchase", "shopping":
			return has_journal_for_purchase(entry.purchase_record_id)
		"product_unlock":
			return has_journal_for_product_unlock(entry.product_id)
		"new_food", "food_reaction":
			return has_journal_for_food_use(entry.food_use_record_id)
		"first_cooking", "cooking":
			return has_journal_for_cooking(entry.cooking_record_id)
		"recipe_discovery":
			return has_journal_for_recipe(entry.recipe_id)
		"picnic":
			return has_journal_for_life_location(entry.life_location_id)
		"picnic_food":
			return has_picnic_food_journal_for_location(entry.life_location_id)
		"shop_event":
			return has_journal_for_week6_event(entry.shop_event_id)
		"cooking_event":
			return has_journal_for_week6_event(entry.cooking_event_id)
		"picnic_event":
			return has_journal_for_week6_event(entry.picnic_event_id)
		"week6_finale":
			return has_journal_for_week6_event(entry.life_event_id)
		"building_unlock":
			return has_week7_building_unlock_journal(entry.building_id)
		"building_placement":
			return has_week7_building_placement_journal(entry.building_id)
		"week7_construction":
			return has_week7_construction_journal(entry.construction_id if not entry.construction_id.is_empty() else entry.construction_record_id, false)
		"cafe_complete":
			return has_week7_construction_journal(entry.construction_id if not entry.construction_id.is_empty() else entry.construction_record_id, true)
		"cafe_activity":
			return has_week7_cafe_activity_journal(entry.activity_record_id)
		"cafe_event":
			return has_week7_cafe_event_journal(entry.life_event_id)
		"week7_growth":
			return has_journal_for_growth_event(entry.growth_event_id)
		"growth_reaction":
			return has_week7_growth_reaction_for_source(entry.activity_record_id)
		"village_progress":
			return has_week7_village_progress_journal(entry.village_progress_event_id)
		"week7_finale":
			return has_journal_for_life_event(entry.life_event_id)
		"growth_direction":
			return has_week8_growth_direction_journal(entry.growth_direction_choice_id)
		"balanced":
			return has_week8_balanced_journal(entry.growth_direction_choice_id)
		"final_growth":
			return has_week8_final_growth_journal(entry.final_growth_record_id)
		"final_reaction":
			return has_week8_final_reaction(entry.activity_record_id)
		"village_stage1":
			return has_week8_stage1_journal(entry.village_progress_event_id)
		"life_resume":
			return has_week8_life_resume_journal(entry.life_profile_snapshot_id)
		"ending":
			return has_week8_ending_journal(entry.ending_id)
		"post_ending":
			return has_week8_post_ending_journal(entry.activity_record_id)
	return false

func _append(entry: JournalEntry) -> JournalEntry:
	if entry == null or not entry.is_valid():
		return null
	_journals.append(entry)
	journal_added.emit(entry)
	journals_changed.emit()
	return entry

func _next_id() -> String:
	var serial := _journals.size() + 1
	var candidate := "journal_%03d" % serial
	while _has_journal_id(candidate):
		serial += 1
		candidate = "journal_%03d" % serial
	return candidate

func _has_journal_id(journal_id: String) -> bool:
	for entry: JournalEntry in _journals:
		if entry.journal_id == journal_id:
			return true
	return false

func _has_needs_date(date_key: String) -> bool:
	if date_key.is_empty():
		return false
	for entry: JournalEntry in _journals:
		if entry.journal_type == "needs" and _date_key(entry.created_at) == date_key:
			return true
	return false

func _get_need_key_from_states(hunger_state: String, energy_state: String, mood_state: String) -> String:
	if hunger_state in ["critical", "low"]:
		return "very_hungry"
	if energy_state in ["critical", "low"]:
		return "very_tired"
	if mood_state == "happy":
		return "very_happy"
	if mood_state in ["critical", "low"]:
		return "low_mood"
	return ""

func _rebuild_week5_dates_from_journals() -> void:
	var newest_food_at := -1.0
	var newest_needs_at := -1.0
	for entry: JournalEntry in _journals:
		if entry.journal_type == "food_use" and not entry.is_special_memory and entry.created_at > newest_food_at:
			newest_food_at = entry.created_at
		if entry.journal_type == "needs" and entry.created_at > newest_needs_at:
			newest_needs_at = entry.created_at
	if newest_food_at > 0.0:
		_last_food_journal_date = _date_key(newest_food_at)
	if newest_needs_at > 0.0:
		_last_needs_journal_date = _date_key(newest_needs_at)

func _date_key(timestamp: float) -> String:
	if timestamp <= 0.0:
		return ""
	var date := TimeManager.get_local_datetime(timestamp)
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]


func _rebuild_week6_dates_from_journals() -> void:
	var newest_shopping_at := -1.0
	var newest_cooking_at := -1.0
	var newest_picnic_at := -1.0
	for entry: JournalEntry in _journals:
		if entry.journal_type == "shopping" and entry.created_at > newest_shopping_at:
			newest_shopping_at = entry.created_at
		if entry.journal_type == "cooking" and entry.created_at > newest_cooking_at:
			newest_cooking_at = entry.created_at
		if entry.journal_type == "picnic" and entry.created_at > newest_picnic_at:
			newest_picnic_at = entry.created_at
	if newest_shopping_at > 0.0:
		_last_shopping_journal_date = _date_key(newest_shopping_at)
	if newest_cooking_at > 0.0:
		_last_cooking_journal_date = _date_key(newest_cooking_at)
	if newest_picnic_at > 0.0:
		_last_picnic_journal_date = _date_key(newest_picnic_at)
