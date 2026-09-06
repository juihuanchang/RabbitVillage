class_name SaveManager
extends Node

signal save_failed(message: String)

const SAVE_PATH := "user://save.json"
const SAVE_BACKUP_PATH := "user://save_backup.json"
const SAVE_TEMP_PATH := "user://save_temp.json"

var _rabbit_manager: RabbitManager
var _diary_manager: DiaryManager
var _activity_manager: ActivityManager
var _growth_manager: GrowthManager
var _growth_album_manager: GrowthAlbumManager

var _inventory_manager: InventoryManager
var _currency_manager: CurrencyManager
var _reward_manager: RewardManager
var _life_event_manager: LifeEventManager
var _food_manager: FoodManager
var _shop_manager: ShopManager
var _daily_shop_manager: DailyShopManager
var _cooking_manager: CookingManager
var _life_location_manager: LifeLocationManager
var _building_manager: BuildingManager
var _construction_manager: ConstructionManager
var _village_manager: VillageManager

var resource_history_manager := ResourceHistoryManager.new()
var life_history_manager := LifeHistoryManager.new()
var item_collection_manager := ItemCollectionManager.new()
var shop_history_manager := ShopHistoryManager.new()
var cooking_history_manager := CookingHistoryManager.new()
var life_location_history_manager := LifeLocationHistoryManager.new()
var recipe_collection_manager := RecipeCollectionManager.new()
var village_development_history_manager := VillageDevelopmentHistoryManager.new()

var _loaded_save: SaveData
var _week5_runtime_ready := false
var _week5_signals_connected := false

func setup(
	rabbit_manager: RabbitManager,
	diary_manager: DiaryManager,
	activity_manager: ActivityManager,
	growth_manager: GrowthManager = null,
	growth_album_manager: GrowthAlbumManager = null
) -> void:
	_rabbit_manager = rabbit_manager
	_diary_manager = diary_manager
	_activity_manager = activity_manager
	_growth_manager = growth_manager
	_growth_album_manager = growth_album_manager
	_ensure_week5_managers()
	_discover_week5_runtime_managers()
	_connect_week5_signals()

func save_game() -> bool:
	if not _has_dependencies():
		return false
	var save := SaveData.new()
	save.save_version = SaveData.CURRENT_VERSION
	save.last_saved_at = TimeManager.get_now()
	for rabbit: RabbitData in _rabbit_manager.get_all_rabbits():
		# Saving must never assign village_data back to RabbitData. Its setter emits
		# data_changed and would create a save loop.
		save.rabbits.append(rabbit.to_dict())
		save.forest_experience = rabbit.forest_experience
		save.fishing_experience = rabbit.fishing_experience
		save.intimacy = rabbit.intimacy
		save.forest_activity_count = rabbit.forest_activity_count
		save.fishing_activity_count = rabbit.fishing_activity_count
		save.home_activity_count = rabbit.home_activity_count
		save.total_activity_count = rabbit.total_activity_count
		save.unlocked_growth_marks = rabbit.unlocked_growth_marks.duplicate(true)
		save.pending_growth_event = rabbit.pending_growth_event.duplicate(true)
		_capture_week4(save, rabbit)
	if _activity_manager.active_activity != null:
		save.current_activity = _activity_manager.active_activity.to_dict()
	save.completed_activity_ids = _activity_manager.get_completed_record_ids()
	save.journals = _diary_manager.to_array()
	if _growth_manager != null:
		save.all_activity_records = _growth_manager.get_all_activity_records()
		save.growth_tendencies = _growth_manager.get_growth_tendencies()
	if _growth_album_manager != null:
		save.growth_album_entries = _growth_album_manager.to_array()
	if _week5_runtime_ready:
		_capture_week5_runtime(save)
	else:
		_capture_week5_from_loaded(save)
	_capture_week6_persistent(save)
	_capture_week7_persistent(save)
	_backup_valid_primary()
	var ok := _write(save)
	if ok:
		_loaded_save = save
	else:
		save_failed.emit("存檔失敗，請確認儲存空間或檔案權限。")
	return ok

func load_or_create(default_rabbit: RabbitData) -> RabbitData:
	_week5_runtime_ready = false
	var save := _load()
	if save == null:
		save = SaveData.new()
		_loaded_save = save
		_prepare_week5_persistent_managers(save)
		var created := _create_default(default_rabbit)
		call_deferred("_apply_loaded_week5_runtime")
		save_game()
		return created

	save = migrate_save_data(save)
	_loaded_save = save
	_prepare_week5_persistent_managers(save)
	# Install duplicate guards before Player restores an overdue activity. RewardManager.setup()
	# does not clear _results, so this safely blocks an already-recorded reward immediately.
	_restore_reward_guard(save.reward_history)
	_restore_life_event_state(save)
	_rabbit_manager.clear_rabbits()
	_activity_manager.set_completed_record_ids(save.completed_activity_ids)
	_diary_manager.load_from_array(save.journals)
	_diary_manager.setup_week5_limits(save.last_food_journal_date, save.last_needs_journal_date)
	_diary_manager.setup_week6_limits(save.last_shopping_journal_date, save.last_cooking_journal_date, save.last_picnic_journal_date)
	for raw: Dictionary in save.rabbits:
		var rabbit := RabbitData.from_dict(raw)
		rabbit.village_data = VillageData.from_dict(rabbit.village_data).to_dict() if not rabbit.village_data.is_empty() else save.village_data.duplicate(true)
		_rabbit_manager.add_rabbit(rabbit)
	var loaded_rabbit := _rabbit_manager.get_rabbit(default_rabbit.rabbit_name)
	if loaded_rabbit == null:
		loaded_rabbit = default_rabbit
		_apply_week3(loaded_rabbit, save)
		loaded_rabbit.village_data = save.village_data.duplicate(true)
		_rabbit_manager.add_rabbit(loaded_rabbit)
	if _growth_manager != null:
		_growth_manager.setup(loaded_rabbit)
		_growth_manager.load_from_save_data(save)
	if _growth_album_manager != null:
		_growth_album_manager.load_from_array(save.growth_album_entries)
	_restore_activity(save, loaded_rabbit)
	call_deferred("_apply_loaded_week5_runtime")
	# The immediate rewrite is safe: before the deferred runtime restore, Week 5
	# fields are copied from _loaded_save instead of zero-valued runtime managers.
	save_game()
	return loaded_rabbit

func migrate_save_data(save: SaveData) -> SaveData:
	if save == null:
		return null
	var original_version := save.save_version
	var village := VillageData.from_dict(save.village_data) if not save.village_data.is_empty() else VillageData.create_migrated_week3_default()
	save.village_data = village.to_dict()
	# The migration is idempotent. Running it for an already-v6 save also repairs
	# a missing carrot entry without ever double-copying a valid one.
	if original_version <= SaveData.CURRENT_VERSION:
		save = LegacySaveMigrator.migrate_week4_to_week5(save)
		save = LegacySaveMigrator.migrate_week5_to_week6(save)
		save = LegacySaveMigrator.migrate_week6_to_week7(save)
	save.save_version = SaveData.CURRENT_VERSION
	return save

func MigrateSaveData(save: SaveData) -> SaveData:
	return migrate_save_data(save)

func get_resource_history_manager() -> ResourceHistoryManager:
	return resource_history_manager

func get_life_history_manager() -> LifeHistoryManager:
	return life_history_manager

func get_item_collection_manager() -> ItemCollectionManager:
	return item_collection_manager

func get_shop_history_manager() -> ShopHistoryManager:
	return shop_history_manager

func get_cooking_history_manager() -> CookingHistoryManager:
	return cooking_history_manager

func get_life_location_history_manager() -> LifeLocationHistoryManager:
	return life_location_history_manager

func get_recipe_collection_manager() -> RecipeCollectionManager:
	return recipe_collection_manager

func get_village_development_history_manager() -> VillageDevelopmentHistoryManager:
	return village_development_history_manager

func _prepare_week5_persistent_managers(save: SaveData) -> void:
	resource_history_manager.setup(save.inventory_history, save.currency_history, save.reward_history, save.item_discovery_history)
	life_history_manager.setup(save.food_use_history, save.growth_path_history, save.life_event_history, save.food_variety_records)
	item_collection_manager.setup(save.item_collection)
	shop_history_manager.setup(save.purchase_history, save.daily_shop_history, save.product_unlock_history, save.shop_event_history)
	cooking_history_manager.setup(save.cooking_history, save.recipe_unlock_history)
	life_location_history_manager.setup(save.life_location_history)
	recipe_collection_manager.setup(save.recipe_collection)
	village_development_history_manager.setup_from_save(save)
	if _diary_manager != null:
		_diary_manager.setup_week5_limits(save.last_food_journal_date, save.last_needs_journal_date)
		_diary_manager.setup_week6_limits(save.last_shopping_journal_date, save.last_cooking_journal_date, save.last_picnic_journal_date)

func _ensure_week5_managers() -> void:
	for manager: Node in [resource_history_manager, life_history_manager, item_collection_manager, shop_history_manager, cooking_history_manager, life_location_history_manager, recipe_collection_manager, village_development_history_manager]:
		if manager.get_parent() == null:
			add_child(manager)

func _discover_week5_runtime_managers() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var inventory_variant: Variant = parent_node.get("inventory_manager")
	var currency_variant: Variant = parent_node.get("currency_manager")
	var reward_variant: Variant = parent_node.get("reward_manager")
	var life_variant: Variant = parent_node.get("life_event_manager")
	var food_variant: Variant = parent_node.get("food_manager")
	var shop_variant: Variant = parent_node.get("shop_manager")
	var daily_shop_variant: Variant = parent_node.get("daily_shop_manager")
	var cooking_variant: Variant = parent_node.get("cooking_manager")
	var location_variant: Variant = parent_node.get("life_location_manager")
	var building_variant: Variant = parent_node.get("building_manager")
	var construction_variant: Variant = parent_node.get("construction_manager")
	var village_variant: Variant = parent_node.get("village_manager")
	if inventory_variant is InventoryManager:
		_inventory_manager = inventory_variant
	if currency_variant is CurrencyManager:
		_currency_manager = currency_variant
	if reward_variant is RewardManager:
		_reward_manager = reward_variant
	if life_variant is LifeEventManager:
		_life_event_manager = life_variant
	if food_variant is FoodManager:
		_food_manager = food_variant
	if shop_variant is ShopManager: _shop_manager = shop_variant
	if daily_shop_variant is DailyShopManager: _daily_shop_manager = daily_shop_variant
	if cooking_variant is CookingManager: _cooking_manager = cooking_variant
	if location_variant is LifeLocationManager: _life_location_manager = location_variant
	if building_variant is BuildingManager: _building_manager = building_variant
	if construction_variant is ConstructionManager: _construction_manager = construction_variant
	if village_variant is VillageManager: _village_manager = village_variant

func _connect_week5_signals() -> void:
	if _week5_signals_connected:
		return
	_discover_week5_runtime_managers()
	if _inventory_manager != null:
		_inventory_manager.inventory_changed.connect(_on_inventory_changed)
		_inventory_manager.item_discovered.connect(_on_item_discovered)
	if _currency_manager != null:
		_currency_manager.currency_changed.connect(_on_currency_changed)
	if _reward_manager != null:
		_reward_manager.activity_reward_applied.connect(_on_activity_reward_applied)
	if _food_manager != null:
		_food_manager.food_use_completed.connect(_on_food_use_completed)
	if _life_event_manager != null:
		_life_event_manager.life_event_triggered.connect(_on_life_event_triggered)
		_life_event_manager.life_event_confirmed.connect(_on_life_event_confirmed)
	if _growth_manager != null:
		_growth_manager.growth_event_triggered.connect(_on_growth_event_pending)
		_growth_manager.growth_event_confirmed.connect(_on_growth_event_confirmed)
		_growth_manager.growth_path_updated.connect(_on_growth_path_updated)
	if _activity_manager != null:
		_activity_manager.activity_completed.connect(_on_activity_completed_for_life_journal)
	if _rabbit_manager != null:
		_rabbit_manager.rabbit_need_state_changed.connect(_on_rabbit_need_state_changed)
	if _growth_album_manager != null:
		_growth_album_manager.album_entry_added.connect(_on_growth_album_updated)
	if _diary_manager != null:
		_diary_manager.journal_added.connect(_on_journal_created)
	if _shop_manager != null:
		_shop_manager.purchase_completed.connect(_on_purchase_completed)
		_shop_manager.product_unlocked.connect(_on_product_unlocked)
	if _daily_shop_manager != null:
		_daily_shop_manager.daily_shop_refreshed.connect(_on_daily_shop_refreshed)
	if _cooking_manager != null:
		_cooking_manager.cooking_completed.connect(_on_cooking_completed)
		_cooking_manager.recipe_discovered.connect(_on_recipe_discovered)
		_cooking_manager.recipe_unlocked.connect(_on_recipe_unlocked)
	if _life_location_manager != null:
		_life_location_manager.life_location_activity_completed.connect(_on_life_location_completed)
	if _construction_manager != null:
		_construction_manager.construction_started.connect(_on_week7_construction_started)
		_construction_manager.construction_completed.connect(_on_week7_construction_completed)
	if _village_manager != null:
		_village_manager.village_progress_changed.connect(_on_week7_village_progress_changed)
	_week5_signals_connected = true

func _apply_loaded_week5_runtime() -> void:
	if _loaded_save == null:
		return
	_discover_week5_runtime_managers()
	if _inventory_manager != null:
		_inventory_manager.setup(_loaded_save.inventory)
	if _currency_manager != null:
		_currency_manager.setup(_loaded_save.currency_data)
	if _food_manager != null:
		_food_manager.restore_successful_food_use_count(int(_loaded_save.food_runtime_state.get("successful_food_use_count", 0)))
		_food_manager.restore_used_food_ids(_loaded_save.food_runtime_state.get("used_food_ids", []))
	if _shop_manager != null and _daily_shop_manager != null:
		_shop_manager.setup(_inventory_manager, _currency_manager, _daily_shop_manager, _loaded_save.shop_state)
	if _cooking_manager != null: _cooking_manager.setup(_inventory_manager, _loaded_save.cooking_state)
	if _life_location_manager != null:
		var rabbits := _rabbit_manager.get_all_rabbits()
		if not rabbits.is_empty(): _life_location_manager.setup(rabbits[0], _food_manager, _loaded_save.life_location_state)
	_apply_growth_progress(_loaded_save.growth_path_progress)
	_restore_reward_guard(_loaded_save.reward_history)
	_restore_life_event_state(_loaded_save)
	_repair_collection_from_inventory()
	_repair_discovery_dependencies()
	_repair_reward_history_dependencies()
	_repair_week6_dependencies()
	_repair_week7_dependencies()
	_week5_runtime_ready = true
	_on_rabbit_need_state_changed(_rabbit_manager.get_hunger_state(), _rabbit_manager.get_energy_state(), _rabbit_manager.get_mood_state())
	save_game()

func _apply_growth_progress(raw: Dictionary) -> void:
	if _growth_manager == null:
		return
	var progress_variant: Variant = _growth_manager.get("_progress")
	if not (progress_variant is GrowthPathProgressData):
		return
	var progress: GrowthPathProgressData = progress_variant
	var forest_stage := maxi(0, int(raw.get("forest_stage", 0)))
	var lakeside_stage := maxi(0, int(raw.get("lakeside_stage", 0)))
	if _growth_manager.has_growth_mark("leaf_mark"):
		forest_stage = maxi(forest_stage, 1)
	if _growth_manager.has_growth_mark("sprout_mark"):
		forest_stage = maxi(forest_stage, 2)
	if _growth_manager.has_growth_mark("forest_stage3"):
		forest_stage = maxi(forest_stage, 3)
	if _growth_manager.has_growth_mark("lake_interest"):
		lakeside_stage = maxi(lakeside_stage, 1)
	if _growth_manager.has_growth_mark("lakeside_stage2"):
		lakeside_stage = maxi(lakeside_stage, 2)
	progress.forest_stage = forest_stage
	progress.lakeside_stage = lakeside_stage
	progress.forest_tendency_level = clampi(int(raw.get("forest_tendency_level", progress.forest_tendency_level)), 0, 3)
	progress.lakeside_tendency_level = clampi(int(raw.get("lakeside_tendency_level", progress.lakeside_tendency_level)), 0, 3)
	progress.last_updated_at = maxf(0.0, float(raw.get("last_updated_at", progress.last_updated_at)))

func _restore_reward_guard(saved_history: Array[Dictionary]) -> void:
	if _reward_manager == null:
		return
	var results_variant: Variant = _reward_manager.get("_results")
	if not (results_variant is Dictionary):
		return
	var results: Dictionary = results_variant
	for raw: Dictionary in saved_history:
		var history := RewardHistoryEntry.from_dict(raw)
		if history.activity_record_id.is_empty() or history.reward_record_id.is_empty():
			continue
		var result := RewardResult.new()
		result.reward_record_id = history.reward_record_id
		result.activity_record_id = history.activity_record_id
		result.activity_id = history.activity_id
		result.coin_reward = history.coin_reward
		result.item_rewards = history.item_rewards.duplicate(true)
		result.generated_at = history.generated_at
		result.applied_at = history.applied_at
		result.is_applied = true
		results[history.activity_record_id] = result

func _restore_life_event_state(save: SaveData) -> void:
	if _life_event_manager == null:
		return
	var events_variant: Variant = _life_event_manager.get("_events")
	if not (events_variant is Dictionary):
		return
	var events: Dictionary = events_variant
	for event_id: String in events.keys():
		var event := events[event_id] as LifeEventData
		if event == null:
			continue
		if save.completed_life_event_ids.has(event_id) or life_history_manager.has_life_event_history(event_id):
			event.state = LifeEventState.COMPLETED
			var history := life_history_manager.get_life_event_history(event_id)
			if history != null:
				event.confirmed_at = history.confirmed_at
	var pending_id := ""
	for raw: Dictionary in save.pending_life_events:
		var event_id := str(raw.get("event_id", ""))
		if not events.has(event_id):
			continue
		var event := events[event_id] as LifeEventData
		if event == null or event.state == LifeEventState.COMPLETED:
			continue
		event.state = LifeEventState.PENDING
		event.triggered_at = maxf(0.0, float(raw.get("triggered_at", 0.0)))
		pending_id = event_id
		break
	_life_event_manager.set("_pending_event_id", pending_id)

func _capture_week5_runtime(save: SaveData) -> void:
	if _inventory_manager != null:
		save.inventory = _inventory_manager.to_dict()
	if _currency_manager != null:
		save.currency_data = _currency_manager.data.to_dict()
	save.inventory_history = resource_history_manager.inventory_history_to_array()
	save.currency_history = resource_history_manager.currency_history_to_array()
	save.reward_history = resource_history_manager.reward_history_to_array()
	save.item_discovery_history = resource_history_manager.item_discovery_history_to_array()
	save.item_collection = item_collection_manager.to_array()
	save.food_use_history = life_history_manager.food_use_history_to_array()
	save.growth_path_history = life_history_manager.growth_path_history_to_array()
	save.life_event_history = life_history_manager.life_event_history_to_array()
	save.growth_path_progress = _capture_growth_progress()
	save.pending_life_events = _capture_pending_life_events()
	save.completed_life_event_ids = _capture_completed_life_event_ids()
	save.last_food_journal_date = _diary_manager.get_last_food_journal_date()
	save.last_needs_journal_date = _diary_manager.get_last_needs_journal_date()
	if _shop_manager != null:
		save.shop_state = _shop_manager.to_dict()
		save.daily_shop_state = _extract_daily_shop_state(save.shop_state)
	if _cooking_manager != null: save.cooking_state = _cooking_manager.to_dict()
	if _food_manager != null: save.food_runtime_state = _food_manager.to_dict()
	if _life_location_manager != null: save.life_location_state = _life_location_manager.to_dict()

func _capture_week5_from_loaded(save: SaveData) -> void:
	if _loaded_save == null:
		return
	save.inventory = _loaded_save.inventory.duplicate(true)
	save.currency_data = _loaded_save.currency_data.duplicate(true)
	save.reward_history = _loaded_save.reward_history.duplicate(true)
	save.inventory_history = _loaded_save.inventory_history.duplicate(true)
	save.currency_history = _loaded_save.currency_history.duplicate(true)
	save.item_collection = _loaded_save.item_collection.duplicate(true)
	save.item_discovery_history = _loaded_save.item_discovery_history.duplicate(true)
	save.food_use_history = _loaded_save.food_use_history.duplicate(true)
	save.shop_state = _loaded_save.shop_state.duplicate(true)
	save.daily_shop_state = _loaded_save.daily_shop_state.duplicate(true)
	save.cooking_state = _loaded_save.cooking_state.duplicate(true)
	save.food_runtime_state = _loaded_save.food_runtime_state.duplicate(true)
	save.life_location_state = _loaded_save.life_location_state.duplicate(true)
	save.growth_path_progress = _loaded_save.growth_path_progress.duplicate(true)
	save.growth_path_history = _loaded_save.growth_path_history.duplicate(true)
	save.life_event_history = _loaded_save.life_event_history.duplicate(true)
	save.pending_life_events = _loaded_save.pending_life_events.duplicate(true)
	save.completed_life_event_ids = _loaded_save.completed_life_event_ids.duplicate()
	save.last_food_journal_date = _diary_manager.get_last_food_journal_date() if _diary_manager != null else _loaded_save.last_food_journal_date
	save.last_needs_journal_date = _diary_manager.get_last_needs_journal_date() if _diary_manager != null else _loaded_save.last_needs_journal_date
	save.last_shopping_journal_date = _diary_manager.get_last_shopping_journal_date() if _diary_manager != null else _loaded_save.last_shopping_journal_date
	save.last_cooking_journal_date = _diary_manager.get_last_cooking_journal_date() if _diary_manager != null else _loaded_save.last_cooking_journal_date
	save.last_picnic_journal_date = _diary_manager.get_last_picnic_journal_date() if _diary_manager != null else _loaded_save.last_picnic_journal_date

func _capture_growth_progress() -> Dictionary:
	if _growth_manager == null:
		return _loaded_save.growth_path_progress.duplicate(true) if _loaded_save != null else {}
	var progress_variant: Variant = _growth_manager.get("_progress")
	var last_updated := 0.0
	if progress_variant is GrowthPathProgressData:
		last_updated = progress_variant.last_updated_at
	return {
		"forest_stage": _growth_manager.get_forest_growth_stage(),
		"lakeside_stage": _growth_manager.get_lakeside_growth_stage(),
		"forest_tendency_level": _growth_manager.get_forest_tendency_level(),
		"lakeside_tendency_level": _growth_manager.get_lakeside_tendency_level(),
		"last_updated_at": last_updated
	}

func _capture_pending_life_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _life_event_manager != null and _life_event_manager.has_pending_life_event():
		var event := _life_event_manager.get_pending_life_event()
		if event != null:
			result.append(event.to_dict())
	return result

func _capture_completed_life_event_ids() -> Array[String]:
	var result: Array[String] = []
	for raw: Dictionary in life_history_manager.life_event_history_to_array():
		var event_id := str(raw.get("life_event_id", ""))
		if not event_id.is_empty() and not result.has(event_id):
			result.append(event_id)
	if _life_event_manager != null:
		var events_variant: Variant = _life_event_manager.get("_events")
		if events_variant is Dictionary:
			for raw_id: Variant in events_variant.keys():
				var event_id := str(raw_id)
				var event := events_variant[raw_id] as LifeEventData
				if event != null and event.state == LifeEventState.COMPLETED and not result.has(event_id):
					result.append(event_id)
	return result

func _repair_collection_from_inventory() -> void:
	if _inventory_manager == null:
		return
	for entry: InventoryEntry in _inventory_manager.get_all_items():
		if entry.total_obtained <= 0 or item_collection_manager.has_discovered_item(entry.item_id):
			continue
		item_collection_manager.register_discovery(entry.item_id, entry.first_obtained_at, "repair", "inventory_total_obtained")

func _repair_discovery_dependencies() -> void:
	for discovery: ItemDiscoveryHistoryEntry in resource_history_manager.get_item_discovery_history_entries():
		item_collection_manager.register_discovery(discovery.item_id, discovery.discovered_at, discovery.source_type, discovery.source_id)
		if _diary_manager != null and not _diary_manager.has_journal_for_item_discovery(discovery.item_id, discovery.discovery_id):
			_diary_manager.generate_item_discovery_journal(discovery, _current_rabbit_name())

func _repair_reward_history_dependencies() -> void:
	if _inventory_manager == null or _currency_manager == null:
		return
	for history: RewardHistoryEntry in resource_history_manager.get_reward_history_entries():
		if history.coin_reward > 0 and not resource_history_manager.has_currency_history_for_source("coin", "activity_reward", history.reward_record_id):
			var coin_after := _currency_manager.get_coin_amount()
			resource_history_manager.record_currency_change("coin", maxi(0, coin_after - history.coin_reward), history.coin_reward, coin_after, "activity_reward", history.reward_record_id, history.applied_at)
		for item_id: String in history.item_rewards:
			if resource_history_manager.has_inventory_history_for_source(item_id, "activity_reward", history.reward_record_id):
				continue
			var reward_amount := maxi(0, int(history.item_rewards[item_id]))
			var item_after := _inventory_manager.get_item_amount(item_id)
			resource_history_manager.record_inventory_change(item_id, maxi(0, item_after - reward_amount), reward_amount, item_after, "activity_reward", history.reward_record_id, history.applied_at)

func _on_food_use_completed(result: FoodUseResult) -> void:
	if result == null:
		return
	var is_first_recorded_use := not life_history_manager.has_food_use_for_food(result.food_id)
	life_history_manager.record_food_use(result)
	if _diary_manager != null:
		_diary_manager.generate_food_use_journal(result, _current_rabbit_name(), is_first_recorded_use)
		_diary_manager.generate_week6_food_journal(result, _current_rabbit_name(), is_first_recorded_use)
	save_game()

func _on_inventory_changed(item_id: String, old_amount: int, new_amount: int, source_type: String, source_id: String) -> void:
	resource_history_manager.record_inventory_change(item_id, old_amount, new_amount - old_amount, new_amount, source_type, source_id)
	save_game()

func _on_currency_changed(old_amount: int, new_amount: int, source_type: String, source_id: String) -> void:
	resource_history_manager.record_currency_change("coin", old_amount, new_amount - old_amount, new_amount, source_type, source_id)
	save_game()

func _on_activity_reward_applied(result: RewardResult) -> void:
	if result == null:
		return
	resource_history_manager.record_reward(result)
	_repair_reward_dependencies_for_result(result)
	save_game()

func _repair_reward_dependencies_for_result(result: RewardResult) -> void:
	if _inventory_manager == null or _currency_manager == null:
		return
	if result.coin_reward > 0 and not resource_history_manager.has_currency_history_for_source("coin", "activity_reward", result.reward_record_id):
		var coin_after := _currency_manager.get_coin_amount()
		resource_history_manager.record_currency_change("coin", maxi(0, coin_after - result.coin_reward), result.coin_reward, coin_after, "activity_reward", result.reward_record_id, result.applied_at)
	for item_id: String in result.item_rewards:
		if resource_history_manager.has_inventory_history_for_source(item_id, "activity_reward", result.reward_record_id):
			continue
		var reward_amount := maxi(0, int(result.item_rewards[item_id]))
		var item_after := _inventory_manager.get_item_amount(item_id)
		resource_history_manager.record_inventory_change(item_id, maxi(0, item_after - reward_amount), reward_amount, item_after, "activity_reward", result.reward_record_id, result.applied_at)

func _on_item_discovered(item_id: String, source_type: String, source_id: String, discovered_at: float) -> void:
	var discovery := resource_history_manager.record_item_discovery(item_id, discovered_at, source_type, source_id)
	if discovery == null:
		return
	item_collection_manager.register_discovery(item_id, discovery.discovered_at, source_type, source_id)
	if _diary_manager != null:
		_diary_manager.generate_item_discovery_journal(discovery, _current_rabbit_name())
	save_game()

func _on_life_event_triggered(_event: LifeEventData) -> void:
	# Pending state is captured directly from B's LifeEventManager.
	save_game()

func _on_life_event_confirmed(result: LifeEventResult) -> void:
	if result == null:
		return
	life_history_manager.record_life_event(result)
	if result.event_id.begins_with("shop_"):
		shop_history_manager.record_shop_event(result.event_id, result.confirmed_at)
	if result.event_id == "cafe_barista_arrives_001":
		var unlock := village_development_history_manager.record_building_unlock("cafe", result.confirmed_at, result.event_id)
		if unlock != null and _diary_manager != null:
			_diary_manager.generate_week7_building_unlock_journal(unlock, _current_rabbit_name())
		_add_week7_album_moment("cafe_unlock", result.event_id, "咖啡館解鎖", "村莊正式有了建造咖啡館的計畫。", "village", 0, result.confirmed_at, _find_journal_id_for_life_event(result.event_id))
	if _diary_manager != null:
		if result.event_id.begins_with("shop_") or result.event_id.begins_with("cooking_") or result.event_id.begins_with("picnic_") or result.event_id == "village_daily_life_001":
			_diary_manager.generate_week6_event_journal(result.event_id, _current_rabbit_name(), result.confirmed_at)
		elif result.event_id in ["cafe_barista_arrives_001", "cafe_first_visit_001", "cafe_first_work_001", "cafe_regular_visitor_001"]:
			_diary_manager.generate_week7_cafe_event_journal(result.event_id, _current_rabbit_name(), result.confirmed_at)
		elif result.event_id == "village_first_expansion_001":
			_diary_manager.generate_week7_finale_journal(result.event_id, _current_rabbit_name(), result.confirmed_at)
		else:
			_diary_manager.generate_life_event_journal(result.event_id, _current_rabbit_name(), result.confirmed_at)
	save_game()

func _on_growth_event_pending(_event: GrowthEventData) -> void:
	# pending_growth_event stays owned by GrowthManager/RabbitData; C only persists it.
	save_game()

func _on_growth_event_confirmed(_event: GrowthEventData) -> void:
	save_game()

func _on_growth_path_updated(growth_path: String, old_stage: int, new_stage: int, source_event_id: String) -> void:
	life_history_manager.record_growth_path_change(growth_path, old_stage, new_stage, source_event_id)
	var mark_id := _growth_mark_for_event(source_event_id)
	var journal: JournalEntry = null
	if _diary_manager != null:
		if source_event_id in ["growth_forest_stage3_001", "growth_lakeside_stage2_001"]:
			journal = _diary_manager.generate_week7_growth_journal(source_event_id, growth_path, new_stage, mark_id, _current_rabbit_name())
		else:
			journal = _diary_manager.generate_growth_event_journal(source_event_id, growth_path, new_stage, mark_id, _current_rabbit_name())
		if journal == null:
			journal = _diary_manager.get_journal_for_growth_event(source_event_id)
	if _growth_album_manager != null and source_event_id in ["growth_sprout_mark_001", "growth_lake_interest_001"]:
		var title := journal.title if journal != null else ("嫩芽" if growth_path == "forest" else "湖畔興趣")
		var description := journal.content if journal != null else "Amy 的成長留下了新的記錄。"
		var illustration_id := journal.illustration_id if journal != null else ""
		var journal_id := journal.journal_id if journal != null else ""
		_growth_album_manager.add_week5_growth_entry(mark_id, source_event_id, title, description, growth_path, new_stage, TimeManager.get_now(), journal_id, illustration_id)
	if source_event_id in ["growth_forest_stage3_001", "growth_lakeside_stage2_001"]:
		var appearance := "forest_stage3" if source_event_id == "growth_forest_stage3_001" else "lakeside_stage2"
		village_development_history_manager.record_appearance(appearance, source_event_id, TimeManager.get_now())
		_add_week7_album_moment(mark_id, source_event_id, journal.title if journal != null else appearance, journal.content if journal != null else "Amy 的成長進入了新的階段。", growth_path, new_stage, TimeManager.get_now(), journal.journal_id if journal != null else "", journal.illustration_id if journal != null else mark_id)
	save_game()

func _on_growth_album_updated(_entry: GrowthAlbumEntry) -> void:
	save_game()

func _on_journal_created(_entry: JournalEntry) -> void:
	save_game()

func _on_activity_completed_for_life_journal(active: ActiveActivityData) -> void:
	if active == null or active.activity == null:
		return
	if active.activity.location_id == "cafe":
		var cafe_history := village_development_history_manager.record_cafe_activity(active)
		if cafe_history != null and _diary_manager != null:
			_tag_journal_growth_form(_diary_manager.generate_week7_cafe_activity_journal(cafe_history, _current_rabbit_name()))
		# Café Activity Complete is an explicit Week 7 immediate-save point.
		save_game()
	if _growth_manager == null or _diary_manager == null:
		return
	if active.activity.location_id == "forest" and _growth_manager.get_forest_growth_stage() >= 2:
		_tag_journal_growth_form(_diary_manager.generate_growth_lifestyle_journal("forest", _growth_manager.get_forest_growth_stage(), active.activity_record_id, _current_rabbit_name(), active.completed_at))
		if _growth_manager.get_forest_growth_stage() >= 3:
			_tag_journal_growth_form(_diary_manager.generate_week7_growth_reaction_journal(active.activity_record_id, "forest", _growth_manager.get_forest_growth_stage(), _current_rabbit_name(), active.completed_at))
	elif active.activity.location_id == "lake" and _growth_manager.get_lakeside_growth_stage() >= 1:
		_tag_journal_growth_form(_diary_manager.generate_growth_lifestyle_journal("lakeside", _growth_manager.get_lakeside_growth_stage(), active.activity_record_id, _current_rabbit_name(), active.completed_at))
		if _growth_manager.get_lakeside_growth_stage() >= 2:
			_tag_journal_growth_form(_diary_manager.generate_week7_growth_reaction_journal(active.activity_record_id, "lakeside", _growth_manager.get_lakeside_growth_stage(), _current_rabbit_name(), active.completed_at))

func _tag_journal_growth_form(entry: JournalEntry) -> void:
	if entry != null and _growth_manager != null: entry.growth_form = _growth_manager.get_current_final_form()

func _on_rabbit_need_state_changed(hunger_state: String, energy_state: String, mood_state: String) -> void:
	if not _week5_runtime_ready or _diary_manager == null:
		return
	var rabbit := _current_rabbit()
	if rabbit != null:
		_diary_manager.generate_needs_journal_from_states(rabbit, hunger_state, energy_state, mood_state, rabbit.rabbit_name)

func _capture_week6_persistent(save: SaveData) -> void:
	save.purchase_history = shop_history_manager.purchase_history_to_array()
	save.daily_shop_history = shop_history_manager.daily_shop_history_to_array()
	save.product_unlock_history = shop_history_manager.product_unlock_history_to_array()
	save.shop_event_history = shop_history_manager.shop_event_history_to_array()
	save.cooking_history = cooking_history_manager.cooking_history_to_array()
	save.recipe_unlock_history = cooking_history_manager.recipe_unlock_history_to_array()
	save.recipe_collection = recipe_collection_manager.to_array()
	save.food_variety_records = life_history_manager.food_variety_records_to_array()
	save.life_location_history = life_location_history_manager.to_array()
	if _week5_runtime_ready and _daily_shop_manager != null:
		save.daily_shop_state = _extract_daily_shop_state(_daily_shop_manager.to_dict())
	elif _loaded_save != null:
		save.daily_shop_state = _loaded_save.daily_shop_state.duplicate(true)
	if _diary_manager != null:
		save.last_shopping_journal_date = _diary_manager.get_last_shopping_journal_date()
		save.last_cooking_journal_date = _diary_manager.get_last_cooking_journal_date()
		save.last_picnic_journal_date = _diary_manager.get_last_picnic_journal_date()

func _extract_daily_shop_state(raw: Dictionary) -> Dictionary:
	return {
		"day_key": str(raw.get("day_key", "")),
		"daily_offers": raw.get("daily_offers", []).duplicate(true) if raw.get("daily_offers", []) is Array else [],
		"daily_purchase_amounts": raw.get("daily_purchase_amounts", {}).duplicate(true) if raw.get("daily_purchase_amounts", {}) is Dictionary else {}
	}

func _on_daily_shop_refreshed(day_key: String, offers: Array[DailyShopOfferData]) -> void:
	shop_history_manager.record_daily_refresh(day_key, offers)
	save_game()

func _on_purchase_completed(result: PurchaseResult) -> void:
	if result == null or not result.success:
		return
	var is_first_purchase := shop_history_manager.get_purchase_count() == 0
	var history := shop_history_manager.record_purchase(result)
	if history == null:
		return
	if _diary_manager != null:
		if is_first_purchase:
			_diary_manager.generate_first_purchase_journal(result, _current_rabbit_name())
		_diary_manager.generate_shopping_journal(result, _current_rabbit_name())
	save_game()

func _on_product_unlocked(product: ShopProductData) -> void:
	if product == null:
		return
	var source_type := "shop_unlock"
	var source_id := ""
	if product.unlock_condition != null:
		source_type = product.unlock_condition.condition_type
		source_id = product.unlock_condition.target_id
	var history := shop_history_manager.record_product_unlock(product, source_type, source_id)
	if history != null and _diary_manager != null:
		_diary_manager.generate_product_unlock_journal(product, _current_rabbit_name())
	save_game()

func _on_recipe_unlocked(recipe: RecipeData) -> void:
	if recipe == null:
		return
	var source_id := ""
	for ingredient: RecipeIngredientData in recipe.ingredients:
		if not source_id.is_empty():
			source_id += ","
		source_id += ingredient.item_id
	cooking_history_manager.record_recipe_unlock(recipe.recipe_id, recipe.unlocked_at, "ingredient_discovery", source_id)
	save_game()

func _on_recipe_discovered(_recipe: RecipeData) -> void:
	# CookingResult owns the stable transaction id, so the permanent collection is
	# committed when cooking_completed arrives a moment later.
	save_game()

func _on_cooking_completed(result: CookingResult) -> void:
	if result == null or not result.success:
		return
	if cooking_history_manager.has_cooking(result.cooking_record_id):
		# A repeated signal for the same transaction must never increase permanent cook counters a second time.
		save_game()
		return
	var canonical_recipe_id := CookingHistoryManager.canonical_recipe_id(result.recipe_id)
	var ingredients := _ingredients_for_runtime_recipe(result.recipe_id)
	var is_first_cooking := cooking_history_manager.cooking_history_to_array().is_empty()
	var is_first_recipe := not recipe_collection_manager.has_discovered_recipe(canonical_recipe_id)
	var history := cooking_history_manager.record_cooking(result, ingredients)
	if history == null:
		return
	recipe_collection_manager.record_cook(canonical_recipe_id, result.cooked_at, "cooking", result.cooking_record_id)
	if _diary_manager != null:
		if is_first_cooking:
			_diary_manager.generate_first_cooking_journal(result, canonical_recipe_id, _current_rabbit_name())
		_diary_manager.generate_cooking_journal(result, canonical_recipe_id, _current_rabbit_name())
		if is_first_recipe:
			_diary_manager.generate_recipe_discovery_journal(result, canonical_recipe_id, _current_rabbit_name())
	save_game()

func _ingredients_for_runtime_recipe(recipe_id: String) -> Dictionary:
	var result := {}
	if _cooking_manager == null:
		return result
	var runtime_id := CookingHistoryManager.runtime_recipe_id(recipe_id)
	var recipe := _cooking_manager.get_recipe(runtime_id)
	if recipe == null:
		return result
	for ingredient: RecipeIngredientData in recipe.ingredients:
		result[ingredient.item_id] = ingredient.required_amount
	return result

func _on_life_location_completed(result: LifeLocationResult) -> void:
	if result == null or not result.success:
		return
	var food_id := ""
	if not result.food_use_record_id.is_empty():
		var food_history := life_history_manager.get_food_use(result.food_use_record_id)
		if food_history != null:
			food_id = food_history.food_id
	var history := life_location_history_manager.record_activity(result, food_id)
	if history == null:
		return
	if _diary_manager != null:
		_diary_manager.generate_picnic_journal(result, _current_rabbit_name())
		if result.activity_id == "picnic_eat" and not food_id.is_empty():
			_diary_manager.generate_picnic_food_journal(result, food_id, _current_rabbit_name())
	save_game()

func _repair_week6_dependencies() -> void:
	if _shop_manager != null:
		var state := _shop_manager.to_dict()
		var day_key := str(state.get("day_key", ""))
		if not day_key.is_empty():
			var raw_offers: Array = []
			var offers_variant: Variant = state.get("daily_offers", [])
			if offers_variant is Array:
				raw_offers = offers_variant
			var purchase_counts: Dictionary = {}
			var counts_variant: Variant = state.get("daily_purchase_amounts", {})
			if counts_variant is Dictionary:
				purchase_counts = counts_variant
			shop_history_manager.record_daily_state(day_key, raw_offers, purchase_counts, _loaded_save.last_saved_at if _loaded_save != null else -1.0)
		for product: ShopProductData in _shop_manager.get_catalog().products:
			if product.unlock_state == ShopProductData.UNLOCKED and shop_history_manager.get_product_unlock(product.product_id) == null:
				shop_history_manager.record_product_unlock_values(product.product_id, product.unlocked_at, "repair", "shop_state")
				if _diary_manager != null:
					_diary_manager.generate_product_unlock_journal(product, _current_rabbit_name())
	var recipe_counts := {}
	var recipe_first_at := {}
	var recipe_first_record := {}
	for raw: Dictionary in cooking_history_manager.cooking_history_to_array():
		var entry := CookingHistoryEntry.from_dict(raw)
		recipe_counts[entry.recipe_id] = int(recipe_counts.get(entry.recipe_id, 0)) + 1
		if not recipe_first_at.has(entry.recipe_id) or float(recipe_first_at[entry.recipe_id]) <= 0.0 or (entry.cooked_at > 0.0 and entry.cooked_at < float(recipe_first_at[entry.recipe_id])):
			recipe_first_at[entry.recipe_id] = entry.cooked_at
			recipe_first_record[entry.recipe_id] = entry.cooking_record_id
	for recipe_id: String in recipe_counts:
		recipe_collection_manager.ensure_minimum_cook_count(recipe_id, int(recipe_counts[recipe_id]), float(recipe_first_at.get(recipe_id, 0.0)), "repair", str(recipe_first_record.get(recipe_id, "cooking_history")))
	if _cooking_manager != null:
		for recipe: RecipeData in _cooking_manager.get_recipes():
			if recipe.is_unlocked and cooking_history_manager.get_recipe_unlock(recipe.recipe_id) == null:
				cooking_history_manager.record_recipe_unlock(recipe.recipe_id, recipe.unlocked_at, "repair", "cooking_state")

func _capture_week7_persistent(save: SaveData) -> void:
	_sync_week7_from_runtime()
	village_development_history_manager.repair_consistency(TimeManager.get_now())
	save.building_slots = village_development_history_manager.building_slots.duplicate(true)
	save.unlocked_building_ids = village_development_history_manager.unlocked_building_ids.duplicate()
	save.buildable_building_ids = ["cafe"]
	save.active_constructions = village_development_history_manager.active_constructions.duplicate(true)
	save.building_unlock_history = village_development_history_manager.building_unlock_history_to_array()
	save.building_placement_history = village_development_history_manager.building_placement_history_to_array()
	save.construction_history = village_development_history_manager.construction_history_to_array()
	save.cafe_experience = village_development_history_manager.cafe_experience
	save.cafe_activity_history = village_development_history_manager.cafe_activity_history_to_array()
	save.cafe_experience_history = village_development_history_manager.cafe_experience_history_to_array()
	save.village_progress_state = village_development_history_manager.village_progress_state.duplicate(true)
	save.village_progress_history = village_development_history_manager.village_progress_history_to_array()
	save.growth_appearance_state = village_development_history_manager.growth_appearance_state
	save.growth_appearance_history = village_development_history_manager.growth_appearance_history_to_array()

func _sync_week7_from_runtime() -> void:
	_discover_week5_runtime_managers()
	var parent_node := get_parent()
	if parent_node != null:
		var village_variant: Variant = parent_node.get("village_data")
		if village_variant is VillageData:
			var village: VillageData = village_variant
			if village.building_records.has("coffee_shop") and village.building_records["coffee_shop"] is Dictionary:
				var raw: Dictionary = village.building_records["coffee_shop"]
				var slot_id := VillageDevelopmentHistoryManager.canonical_slot_id(str(raw.get("slot_id", "")))
				if not slot_id.is_empty():
					village_development_history_manager.record_building_placement("cafe", slot_id, float(raw.get("placed_at", 0.0)))
			if not village.active_construction.is_empty():
				var active := ConstructionRecord.from_dict(village.active_construction)
				if active.building_id in ["coffee_shop", "cafe"]:
					var definition: BuildingData = _building_manager.get_building("coffee_shop") if _building_manager != null else null
					var coin_cost := definition.coin_cost if definition != null else 0
					var materials: Dictionary = definition.material_costs.duplicate(true) if definition != null else {}
					village_development_history_manager.record_construction_start(active, coin_cost, materials)
	if _building_manager != null:
		var cafe: BuildingData = _building_manager.get_building("coffee_shop")
		if cafe != null and cafe.is_unlocked:
			var source_event := "cafe_barista_arrives_001" if _life_event_manager != null and _life_event_manager.has_completed_life_event("cafe_barista_arrives_001") else "runtime_building_state"
			village_development_history_manager.record_building_unlock("cafe", _week7_event_time(source_event), source_event)
	var rabbit := _current_rabbit()
	if rabbit != null:
		village_development_history_manager.cafe_experience = maxi(village_development_history_manager.cafe_experience, rabbit.cafe_experience)
	if _village_manager != null:
		var progress_variant: Variant = _village_manager.get_village_progress()
		if progress_variant is Dictionary:
			village_development_history_manager.village_progress_state = progress_variant.duplicate(true)
		elif progress_variant is Object and progress_variant.has_method("to_dict"):
			village_development_history_manager.village_progress_state = progress_variant.to_dict()
	if _growth_manager != null:
		var appearance_variant: Variant = _growth_manager.get_appearance_state()
		if appearance_variant is String:
			village_development_history_manager.growth_appearance_state = appearance_variant

func _on_week7_construction_started(record: ConstructionRecord) -> void:
	if record == null or record.building_id not in ["coffee_shop", "cafe"]:
		return
	var definition: BuildingData = _building_manager.get_building("coffee_shop") if _building_manager != null else null
	var coin_cost := definition.coin_cost if definition != null else 0
	var materials: Dictionary = definition.material_costs.duplicate(true) if definition != null else {}
	var history := village_development_history_manager.record_construction_start(record, coin_cost, materials)
	if history != null and _diary_manager != null:
		var placement: BuildingPlacementHistoryEntry = null
		for raw: Dictionary in village_development_history_manager.building_placement_history:
			var candidate := BuildingPlacementHistoryEntry.from_dict(raw)
			if candidate.building_id == "cafe":
				placement = candidate
				break
		if placement != null:
			_diary_manager.generate_week7_building_placement_journal(placement, _current_rabbit_name())
		_diary_manager.generate_week7_construction_journal(history, _current_rabbit_name())
	save_game()

func _on_week7_construction_completed(result: ConstructionResult) -> void:
	if result == null or result.building_id not in ["coffee_shop", "cafe"]:
		return
	var history := village_development_history_manager.record_construction_complete(result)
	if history != null and _diary_manager != null:
		var journal := _diary_manager.generate_week7_cafe_complete_journal(history, _current_rabbit_name())
		_add_week7_album_moment("cafe_completed", history.construction_record_id, "咖啡館完成", journal.content if journal != null else "咖啡館正式完成，村莊多了一個新的生活場所。", "village", 1, history.completed_at, journal.journal_id if journal != null else "", "cafe_completed")
	save_game()

func _on_week7_village_progress_changed(progress: VillageProgressData) -> void:
	var history := village_development_history_manager.record_village_progress(progress, TimeManager.get_now())
	if history != null and _diary_manager != null and history.new_level > history.old_level:
		_diary_manager.generate_week7_village_progress_journal(history, _current_rabbit_name())
	save_game()

func _on_week7_history_changed() -> void:
	# History signals can be emitted while save_game() is already collecting data.
	# Defer the write to avoid recursive save loops.
	call_deferred("save_game")

func _repair_week7_dependencies() -> void:
	if _loaded_save == null:
		return
	village_development_history_manager.setup_from_save(_loaded_save)
	_sync_week7_from_runtime()
	village_development_history_manager.repair_consistency(TimeManager.get_now())

	# Recreate missing permanent journals from History only. Never re-spend costs or
	# re-apply Café rewards during repair.
	if _diary_manager != null:
		for raw: Dictionary in village_development_history_manager.building_unlock_history:
			var entry := BuildingUnlockHistoryEntry.from_dict(raw)
			_diary_manager.generate_week7_building_unlock_journal(entry, _current_rabbit_name())
		for raw: Dictionary in village_development_history_manager.building_placement_history:
			var entry := BuildingPlacementHistoryEntry.from_dict(raw)
			_diary_manager.generate_week7_building_placement_journal(entry, _current_rabbit_name())
		for raw: Dictionary in village_development_history_manager.construction_history:
			var entry := ConstructionHistoryEntry.from_dict(raw)
			_diary_manager.generate_week7_construction_journal(entry, _current_rabbit_name())
			if entry.is_completed:
				_diary_manager.generate_week7_cafe_complete_journal(entry, _current_rabbit_name())
		for raw: Dictionary in village_development_history_manager.cafe_activity_history:
			_diary_manager.generate_week7_cafe_activity_journal(CafeActivityHistoryEntry.from_dict(raw), _current_rabbit_name())

	# GrowthAlbum repair: fill the moment only, never recreate its special journal.
	if _growth_album_manager != null:
		for raw: Dictionary in village_development_history_manager.building_unlock_history:
			var unlock := BuildingUnlockHistoryEntry.from_dict(raw)
			_add_week7_album_moment("cafe_unlock", unlock.source_event_id if not unlock.source_event_id.is_empty() else "cafe_unlock_migrated", "咖啡館解鎖", "村莊正式有了建造咖啡館的計畫。", "village", 0, unlock.unlocked_at, "")
		for raw: Dictionary in village_development_history_manager.construction_history:
			var construction := ConstructionHistoryEntry.from_dict(raw)
			if construction.is_completed:
				_add_week7_album_moment("cafe_completed", construction.construction_record_id, "咖啡館完成", "咖啡館正式完成，村莊多了一個新的生活場所。", "village", 1, construction.completed_at, "")
				break
		if _growth_manager != null and _growth_manager.get_forest_growth_stage() >= 3:
			_add_week7_album_moment("forest_stage3", "growth_forest_stage3_001", "森林第三階段", "Amy 的森林成長已經進入第三階段。", "forest", 3, TimeManager.get_now(), "")
		if _growth_manager != null and _growth_manager.get_lakeside_growth_stage() >= 2:
			_add_week7_album_moment("lakeside_stage2", "growth_lakeside_stage2_001", "湖畔第二階段", "Amy 的湖畔成長已經進入第二階段。", "lakeside", 2, TimeManager.get_now(), "")

func _add_week7_album_moment(moment_id: String, source_event_id: String, title: String, description: String, growth_path: String, stage: int, at: float, journal_id: String, illustration_id: String = "") -> void:
	if _growth_album_manager == null or source_event_id.is_empty():
		return
	_growth_album_manager.add_week7_moment(moment_id, source_event_id, title, description, growth_path, stage, at, journal_id, illustration_id)

func _week7_event_time(event_id: String) -> float:
	if _life_event_manager != null:
		var events_variant: Variant = _life_event_manager.get("_events")
		if events_variant is Dictionary and events_variant.has(event_id):
			var event := events_variant[event_id] as LifeEventData
			if event != null:
				return event.confirmed_at if event.confirmed_at > 0.0 else event.triggered_at
	return 0.0

func _find_journal_id_for_life_event(event_id: String) -> String:
	if _diary_manager == null:
		return ""
	for entry: JournalEntry in _diary_manager.get_all_journals():
		if entry.life_event_id == event_id:
			return entry.journal_id
	return ""

func _growth_mark_for_event(event_id: String) -> String:
	match event_id:
		"growth_leaf_mark_001":
			return "leaf_mark"
		"growth_sprout_mark_001":
			return "sprout_mark"
		"growth_lake_interest_001":
			return "lake_interest"
		"growth_forest_stage3_001":
			return "forest_stage3"
		"growth_lakeside_stage2_001":
			return "lakeside_stage2"
	return ""

func _current_rabbit() -> RabbitData:
	if _rabbit_manager == null:
		return null
	var rabbits := _rabbit_manager.get_all_rabbits()
	return rabbits[0] if not rabbits.is_empty() else null

func _current_rabbit_name() -> String:
	var rabbit := _current_rabbit()
	return rabbit.rabbit_name if rabbit != null else "Amy"

func _capture_week4(save: SaveData, rabbit: RabbitData) -> void:
	var village := VillageData.from_dict(rabbit.village_data) if not rabbit.village_data.is_empty() else VillageData.create_migrated_week3_default()
	save.village_data = village.to_dict()

func _restore_activity(save: SaveData, rabbit: RabbitData) -> void:
	if not save.current_activity.is_empty():
		var activity_owner := _rabbit_manager.get_rabbit(str(save.current_activity.get("rabbit_name", rabbit.rabbit_name)))
		var restored := ActiveActivityData.from_dict(save.current_activity, activity_owner)
		if restored != null and not restored.is_completed:
			var definition := _activity_manager.get_activity(restored.activity.activity_id)
			if definition != null:
				restored.activity = definition
			_activity_manager.restore_activity(restored)
			return
	rabbit.is_away = false
	rabbit.current_activity = ""
	rabbit.current_state = ""

func _load() -> SaveData:
	var primary := _read(SAVE_PATH)
	if primary != null:
		return primary
	return _read(SAVE_BACKUP_PATH)

func _read(path: String) -> SaveData:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return null
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return null
	var save := SaveData.from_dict(json.data)
	return save if save.is_supported_version() else null

func _create_default(rabbit: RabbitData) -> RabbitData:
	_rabbit_manager.clear_rabbits()
	_diary_manager.clear_journals()
	_activity_manager.restore_activity(null)
	if _growth_album_manager != null:
		_growth_album_manager.clear_entries()
	if _growth_manager != null:
		_growth_manager.setup(rabbit)
		_growth_manager.load_from_save_data(SaveData.new())
	if rabbit.village_data.is_empty():
		rabbit.village_data = VillageData.create_migrated_week3_default().to_dict()
	_rabbit_manager.add_rabbit(rabbit)
	return rabbit

func _apply_week3(rabbit: RabbitData, save: SaveData) -> void:
	rabbit.forest_experience = save.forest_experience
	rabbit.fishing_experience = save.fishing_experience
	rabbit.intimacy = save.intimacy
	rabbit.forest_activity_count = save.forest_activity_count
	rabbit.fishing_activity_count = save.fishing_activity_count
	rabbit.home_activity_count = save.home_activity_count
	rabbit.total_activity_count = save.total_activity_count
	if rabbit.unlocked_growth_marks.is_empty():
		rabbit.unlocked_growth_marks = save.unlocked_growth_marks.duplicate(true)
	if rabbit.pending_growth_event.is_empty():
		rabbit.pending_growth_event = save.pending_growth_event.duplicate(true)

func _has_dependencies() -> bool:
	return _rabbit_manager != null and _diary_manager != null and _activity_manager != null

func _backup_valid_primary() -> void:
	if not FileAccess.file_exists(SAVE_PATH) or not _is_valid_save_file(SAVE_PATH):
		return
	var source := ProjectSettings.globalize_path(SAVE_PATH)
	var destination := ProjectSettings.globalize_path(SAVE_BACKUP_PATH)
	if FileAccess.file_exists(SAVE_BACKUP_PATH):
		DirAccess.remove_absolute(destination)
	DirAccess.copy_absolute(source, destination)

func _is_valid_save_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return false
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return false
	var save := SaveData.from_dict(json.data)
	return save.is_supported_version()

func _write(save: SaveData) -> bool:
	var file := FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(save.to_dict(), "\t"))
	file.close()
	var temp := ProjectSettings.globalize_path(SAVE_TEMP_PATH)
	var destination := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(destination)
	return DirAccess.rename_absolute(temp, destination) == OK
