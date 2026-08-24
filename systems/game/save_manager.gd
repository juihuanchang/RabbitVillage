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

var resource_history_manager := ResourceHistoryManager.new()
var life_history_manager := LifeHistoryManager.new()
var item_collection_manager := ItemCollectionManager.new()

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

func _prepare_week5_persistent_managers(save: SaveData) -> void:
	resource_history_manager.setup(save.inventory_history, save.currency_history, save.reward_history, save.item_discovery_history)
	life_history_manager.setup(save.food_use_history, save.growth_path_history, save.life_event_history)
	item_collection_manager.setup(save.item_collection)
	if _diary_manager != null:
		_diary_manager.setup_week5_limits(save.last_food_journal_date, save.last_needs_journal_date)

func _ensure_week5_managers() -> void:
	for manager: Node in [resource_history_manager, life_history_manager, item_collection_manager]:
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
	_week5_signals_connected = true

func _apply_loaded_week5_runtime() -> void:
	if _loaded_save == null:
		return
	_discover_week5_runtime_managers()
	if _inventory_manager != null:
		_inventory_manager.setup(_loaded_save.inventory)
	if _currency_manager != null:
		_currency_manager.setup(_loaded_save.currency_data)
	_apply_growth_progress(_loaded_save.growth_path_progress)
	_restore_reward_guard(_loaded_save.reward_history)
	_restore_life_event_state(_loaded_save)
	_repair_collection_from_inventory()
	_repair_discovery_dependencies()
	_repair_reward_history_dependencies()
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
	if _growth_manager.has_growth_mark("lake_interest"):
		lakeside_stage = maxi(lakeside_stage, 1)
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
	save.growth_path_progress = _loaded_save.growth_path_progress.duplicate(true)
	save.growth_path_history = _loaded_save.growth_path_history.duplicate(true)
	save.life_event_history = _loaded_save.life_event_history.duplicate(true)
	save.pending_life_events = _loaded_save.pending_life_events.duplicate(true)
	save.completed_life_event_ids = _loaded_save.completed_life_event_ids.duplicate()
	save.last_food_journal_date = _diary_manager.get_last_food_journal_date() if _diary_manager != null else _loaded_save.last_food_journal_date
	save.last_needs_journal_date = _diary_manager.get_last_needs_journal_date() if _diary_manager != null else _loaded_save.last_needs_journal_date

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
	if _diary_manager != null:
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
		journal = _diary_manager.generate_growth_event_journal(source_event_id, growth_path, new_stage, mark_id, _current_rabbit_name())
		if journal == null:
			journal = _diary_manager.get_journal_for_growth_event(source_event_id)
	if _growth_album_manager != null and source_event_id in ["growth_sprout_mark_001", "growth_lake_interest_001"]:
		var title := journal.title if journal != null else ("嫩芽" if growth_path == "forest" else "湖畔興趣")
		var description := journal.content if journal != null else "Amy 的成長留下了新的記錄。"
		var illustration_id := journal.illustration_id if journal != null else ""
		var journal_id := journal.journal_id if journal != null else ""
		_growth_album_manager.add_week5_growth_entry(mark_id, source_event_id, title, description, growth_path, new_stage, TimeManager.get_now(), journal_id, illustration_id)
	save_game()

func _on_growth_album_updated(_entry: GrowthAlbumEntry) -> void:
	save_game()

func _on_journal_created(_entry: JournalEntry) -> void:
	save_game()

func _on_activity_completed_for_life_journal(active: ActiveActivityData) -> void:
	if active == null or active.activity == null or _growth_manager == null or _diary_manager == null:
		return
	if active.activity.location_id == "forest" and _growth_manager.get_forest_growth_stage() >= 2:
		_diary_manager.generate_growth_lifestyle_journal("forest", _growth_manager.get_forest_growth_stage(), active.activity_record_id, _current_rabbit_name(), active.completed_at)
	elif active.activity.location_id == "lake" and _growth_manager.get_lakeside_growth_stage() >= 1:
		_diary_manager.generate_growth_lifestyle_journal("lakeside", _growth_manager.get_lakeside_growth_stage(), active.activity_record_id, _current_rabbit_name(), active.completed_at)

func _on_rabbit_need_state_changed(hunger_state: String, energy_state: String, mood_state: String) -> void:
	if not _week5_runtime_ready or _diary_manager == null:
		return
	var rabbit := _current_rabbit()
	if rabbit != null:
		_diary_manager.generate_needs_journal_from_states(rabbit, hunger_state, energy_state, mood_state, rabbit.rabbit_name)

func _growth_mark_for_event(event_id: String) -> String:
	match event_id:
		"growth_leaf_mark_001":
			return "leaf_mark"
		"growth_sprout_mark_001":
			return "sprout_mark"
		"growth_lake_interest_001":
			return "lake_interest"
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
