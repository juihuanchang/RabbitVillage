class_name RabbitCharacter
extends CharacterBody2D

signal rabbit_status_changed(rabbit: RabbitData)

@export_category("Rabbit")
@export var rabbit_name := "Amy"
@export_range(0, 100) var initial_hunger := 70
@export_range(0, 100) var initial_mood := 70
@export_range(0, 100) var initial_energy := 70
@export_category("Movement")
@export var speed := 300.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var character_sprite: CanvasItem = $Sprite2D

var rabbit_data: RabbitData
var activity_manager := ActivityManager.new()
var rabbit_manager := RabbitManager.new()
var diary_manager := DiaryManager.new()
var save_manager := SaveManager.new()
var growth_manager := GrowthManager.new()
var growth_album_manager := GrowthAlbumManager.new()
var village_manager := VillageManager.new()
var building_manager := BuildingManager.new()
var construction_manager := ConstructionManager.new()
var village_event_manager := VillageEventManager.new()
var building_interaction_manager := BuildingInteractionManager.new()
var farm_manager := FarmManager.new()
var notice_manager := NoticeManager.new()
var village_history_manager := VillageHistoryManager.new()
var inventory_manager := InventoryManager.new()
var currency_manager := CurrencyManager.new()
var reward_manager := RewardManager.new()
var life_event_manager := LifeEventManager.new()
var food_manager := FoodManager.new()
var village_data: VillageData
var _save_requested := false
var _home_tick_elapsed := 0.0
var _test_reset_elapsed := 0.0
var _last_village_stage := 0

const TEST_AUTO_RESET_SECONDS := 30.0
const TEST_AUTO_RESET_VALUE := 70
const HOME_TICK_SECONDS := 15.0
const HOME_ENERGY_GAIN := 5
const HOME_HUNGER_LOSS := 2
const HOME_MOOD_LOSS := 2

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_attach_system_managers()
	load_game_state()
	_connect_system_signals()
	_restore_pending_system_state()
	_on_village_state_changed()
	rabbit_status_changed.emit(rabbit_data)


func _attach_system_managers() -> void:
	for manager: Node in [activity_manager, rabbit_manager, diary_manager, save_manager, growth_manager, growth_album_manager, village_manager, building_manager, construction_manager, village_event_manager, building_interaction_manager, farm_manager, notice_manager, village_history_manager, inventory_manager, currency_manager, reward_manager, life_event_manager, food_manager]:
		add_child(manager)


func load_game_state() -> void:
	save_manager.setup(rabbit_manager, diary_manager, activity_manager, growth_manager, growth_album_manager)
	rabbit_data = save_manager.load_or_create(
		RabbitData.new(rabbit_name, initial_hunger, initial_mood, initial_energy)
	)
	growth_manager.setup(rabbit_data)
	village_data = VillageData.from_dict(rabbit_data.village_data)
	inventory_manager.setup({"carrot": village_data.carrot_inventory})
	currency_manager.setup()
	life_event_manager.setup(inventory_manager, growth_manager, village_event_manager)
	reward_manager.setup(inventory_manager, currency_manager)
	activity_manager.setup(rabbit_data, reward_manager, life_event_manager, growth_manager)
	rabbit_manager.setup(rabbit_data)
	food_manager.setup(inventory_manager, rabbit_data, activity_manager, life_event_manager, growth_manager, village_event_manager)
	village_manager.setup(village_data)
	building_manager.setup(village_data)
	construction_manager.setup(village_data, building_manager, village_manager)
	village_event_manager.setup(village_data, rabbit_data, building_manager, growth_manager)
	farm_manager.setup(village_data, building_manager, village_manager, inventory_manager)
	building_interaction_manager.setup(village_data, rabbit_data, activity_manager, building_manager, village_manager, growth_manager, village_event_manager)
	notice_manager.setup(village_data, village_manager, building_manager, construction_manager, farm_manager, growth_manager)
	village_history_manager.setup(village_data)
	_last_village_stage = village_manager.get_village_level()


func _connect_system_signals() -> void:
	activity_manager.activity_started.connect(_on_activity_started)
	activity_manager.activity_completed.connect(_on_activity_completed)
	growth_manager.growth_event_created.connect(_on_growth_event_created)
	growth_manager.growth_mark_unlocked.connect(_on_growth_mark_unlocked)
	for manager_signal in [village_manager.village_progress_changed, construction_manager.construction_started, construction_manager.construction_completed, village_event_manager.village_event_created, village_event_manager.village_event_completed, building_interaction_manager.building_interaction_started, building_interaction_manager.building_interaction_completed, farm_manager.farm_cycle_started, farm_manager.farm_ready, farm_manager.carrots_harvested, notice_manager.notice_generated, notice_manager.notice_read]:
		manager_signal.connect(func(_value = null) -> void: _on_village_state_changed())
	village_manager.village_progress_changed.connect(_on_c_village_progress_changed)
	construction_manager.construction_started.connect(_on_c_construction_started)
	village_event_manager.village_event_completed.connect(_on_c_village_event_completed)
	building_interaction_manager.building_interaction_completed.connect(_on_c_building_use_completed)
	farm_manager.farm_cycle_started.connect(_on_c_farm_cycle_started)
	farm_manager.carrots_harvested.connect(_on_c_harvested)
	notice_manager.notice_read.connect(_on_c_notice_read)
	village_history_manager.history_changed.connect(_on_village_state_changed)
	construction_manager.construction_completed.connect(_on_construction_completed)
	building_interaction_manager.building_interaction_completed.connect(func(_result: BuildingUseResult) -> void: village_event_manager.check_event_conditions())
	notice_manager.notice_read.connect(func(_notice: DailyNoticeRecord) -> void: village_event_manager.check_event_conditions())
	farm_manager.carrots_harvested.connect(func(_result: HarvestResult) -> void: village_event_manager.check_event_conditions())
	activity_manager.rabbit_returned.connect(_on_rabbit_returned)
	rabbit_data.data_changed.connect(_on_data_changed)
	diary_manager.journal_added.connect(func(_entry: JournalEntry) -> void: _request_save())
	growth_album_manager.album_entry_added.connect(func(_entry: GrowthAlbumEntry) -> void: _request_save())
	inventory_manager.inventory_changed.connect(func(_item_id: String, _old_amount: int, _new_amount: int, _source_type: String, _source_id: String) -> void: life_event_manager.check_life_events())


func _restore_pending_system_state() -> void:
	_update_character_visibility()
	activity_manager.check_for_completion()
	construction_manager.check_construction_completion()
	building_interaction_manager.check_rest_pavilion_completion()
	farm_manager.check_farm_ready_state()
	village_event_manager.check_event_conditions()

func _process(delta: float) -> void:
	construction_manager.check_construction_completion()
	building_interaction_manager.check_rest_pavilion_completion()
	farm_manager.check_farm_ready_state()
	if rabbit_data != null:
		_test_reset_elapsed += delta
		if _test_reset_elapsed >= TEST_AUTO_RESET_SECONDS:
			_test_reset_elapsed = 0.0
			rabbit_data.hunger = TEST_AUTO_RESET_VALUE
			rabbit_data.mood = TEST_AUTO_RESET_VALUE
			rabbit_data.energy = TEST_AUTO_RESET_VALUE
			rabbit_status_changed.emit(rabbit_data)
			save_manager.save_game()
	if rabbit_data == null or rabbit_data.is_away or not rabbit_data.current_activity.is_empty():
		_home_tick_elapsed = 0.0
		return
	_home_tick_elapsed += delta
	if _home_tick_elapsed >= HOME_TICK_SECONDS:
		_home_tick_elapsed -= HOME_TICK_SECONDS
		rabbit_data.energy += HOME_ENERGY_GAIN
		rabbit_data.hunger -= HOME_HUNGER_LOSS
		rabbit_data.mood -= HOME_MOOD_LOSS
		rabbit_status_changed.emit(rabbit_data)

func _physics_process(_delta: float) -> void:
	if rabbit_data == null or rabbit_data.is_away or not rabbit_data.current_activity.is_empty():
		velocity = Vector2.ZERO
		return
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * speed
	move_and_slide()

func start_activity(activity_id: String) -> Dictionary:
	return activity_manager.start_activity(activity_id)

func get_rabbit_data() -> RabbitData:
	return rabbit_data

func get_all_journals() -> Array[JournalEntry]:
	return diary_manager.get_all_journals()

func get_latest_journal() -> JournalEntry:
	return diary_manager.get_latest_journal()

func get_journal_count() -> int:
	return diary_manager.get_journal_count()

func get_growth_album_entries() -> Array[GrowthAlbumEntry]:
	return growth_album_manager.get_all_entries()

func save_now() -> bool:
	return save_manager.save_game()

func _on_activity_started(_active: ActiveActivityData) -> void:
	_update_character_visibility()
	rabbit_status_changed.emit(rabbit_data)
	save_manager.save_game()

func _on_activity_completed(active: ActiveActivityData) -> void:
	diary_manager.create_journal_from_activity(active)
	growth_manager.record_completed_activity(active)
	notice_manager.recent_activity_location = active.activity.location_id
	village_manager.add_village_experience(5)
	village_event_manager.check_event_conditions()
	rabbit_status_changed.emit(rabbit_data)
	save_manager.save_game()

func _on_village_state_changed() -> void:
	if rabbit_data == null or village_data == null: return
	rabbit_data.village_data = village_data.to_dict()
	rabbit_status_changed.emit(rabbit_data)
	save_manager.save_game()

func _on_construction_completed(result: ConstructionResult) -> void:
	if result == null:
		return
	diary_manager.generate_construction_journal(result, rabbit_data.rabbit_name, village_manager.get_village_level())
	if not village_history_manager.update_construction_completed(result.construction_record_id, result.completed_at):
		var history := ConstructionHistoryEntry.new()
		history.construction_record_id = result.construction_record_id
		history.building_id = result.building_id
		history.slot_id = result.slot_id
		history.started_at = result.started_at
		history.completed_at = result.completed_at
		village_history_manager.add_construction_history(history)
	village_history_manager.mark_building_completed(result.building_id, result.slot_id, result.completed_at)
	if result.building_id == "carrot_farm":
		farm_manager.start_first_growth_cycle()
	village_event_manager.check_event_conditions()

func get_village_progress() -> VillageProgressData: return village_manager.get_village_progress()
func get_village_level() -> int: return village_manager.get_village_level()
func get_village_experience() -> int: return village_manager.get_village_experience()
func has_pending_village_event() -> bool: return village_event_manager.has_pending_event()
func get_pending_village_event() -> VillageEventData: return village_event_manager.get_pending_event()
func confirm_village_event(id: String) -> VillageEventResult: return village_event_manager.confirm_event(id)
func get_all_buildings() -> Array[BuildingData]: return building_manager.get_all_buildings()
func get_building(id: String) -> BuildingData: return building_manager.get_building(id)
func can_place_building(id: String, slot: String) -> Dictionary: return building_manager.can_place_building(id, slot)
func place_building(id: String, slot: String) -> Dictionary:
	var result := building_manager.place_building(id, slot)
	if bool(result.get("ok", false)):
		var record := result.get("record") as BuildingRecord
		if record != null:
			village_history_manager.mark_building_placed(record.building_id, record.slot_id, record.placed_at)
	_on_village_state_changed()
	return result
func get_building_state(id: String) -> String: return building_manager.get_building_state(id)
func start_construction(id: String) -> Dictionary: return construction_manager.start_construction(id)
func cancel_construction() -> Dictionary:
	var result := construction_manager.cancel_construction()
	if bool(result.get("ok", false)): _on_village_state_changed()
	return result
func reclaim_building(id: String) -> Dictionary:
	var result := building_manager.reclaim_building(id)
	if bool(result.get("ok", false)): _on_village_state_changed()
	return result
func adopt_completed_building(id: String, slot: String) -> bool:
	var ok := building_manager.adopt_completed_building(id, slot)
	if ok: _on_village_state_changed()
	return ok
func has_active_construction() -> bool: return construction_manager.has_active_construction()
func get_active_construction() -> ConstructionRecord: return construction_manager.get_active_construction()
func get_construction_remaining_seconds() -> float: return construction_manager.get_construction_remaining_seconds()
func get_construction_end_time() -> float: return construction_manager.get_construction_end_time()
func can_use_rest_pavilion() -> Dictionary: return building_interaction_manager.can_use_rest_pavilion()
func start_rest_pavilion_use() -> Dictionary: return building_interaction_manager.start_rest_pavilion_use()
func get_rest_pavilion_use_remaining() -> float: return building_interaction_manager.get_rest_pavilion_use_remaining()
func get_rest_pavilion_cooldown_remaining() -> float: return building_interaction_manager.get_rest_pavilion_cooldown_remaining()
func has_today_notice() -> bool: return notice_manager.has_today_notice()
func get_today_notice() -> DailyNoticeRecord:
	var notice := notice_manager.get_today_notice()
	return notice if notice != null else notice_manager.generate_today_notice()
func mark_today_notice_read() -> bool: return notice_manager.mark_today_notice_read()
func get_notice_condition_context() -> Dictionary: return notice_manager.get_notice_condition_context()
func get_farm_state() -> String: return farm_manager.get_farm_state()
func start_first_growth_cycle() -> Dictionary: return farm_manager.start_first_growth_cycle()
func start_next_growth_cycle() -> Dictionary: return farm_manager.start_next_growth_cycle()
func has_active_growth_cycle() -> bool: return farm_manager.has_active_growth_cycle()
func is_farm_ready() -> bool: return farm_manager.is_farm_ready()
func get_farm_remaining_seconds() -> float: return farm_manager.get_farm_remaining_seconds()
func get_farm_ready_time() -> float: return farm_manager.get_farm_ready_time()
func harvest_carrots() -> HarvestResult: return farm_manager.harvest_carrots()
func get_carrot_amount() -> int: return farm_manager.get_carrot_amount()
func get_total_harvest_count() -> int: return farm_manager.get_total_harvest_count()
func get_current_farm_cycle() -> FarmCycleData: return farm_manager.get_current_farm_cycle()
func can_eat_carrot() -> bool: return food_manager.can_eat_carrot()
func eat_carrot() -> FoodUseResult: return food_manager.eat_carrot()
func get_item_amount(item_id: String) -> int: return inventory_manager.get_item_amount(item_id)
func get_coin_amount() -> int: return currency_manager.get_coin_amount()
func has_pending_life_event() -> bool: return life_event_manager.has_pending_life_event()
func get_pending_life_event() -> LifeEventData: return life_event_manager.get_pending_life_event()
func confirm_life_event(event_id: String) -> LifeEventResult: return life_event_manager.confirm_life_event(event_id)

func save_today_notice(record: DailyNoticeRecord) -> bool:
	var ok := notice_manager.save_today_notice(record)
	if ok: _on_village_state_changed()
	return ok
func get_notice_history() -> Array[Dictionary]: return notice_manager.get_notice_history()
func select_notice_template(context: NoticeConditionData) -> NoticeTemplate: return notice_manager.select_notice_template(context)
func get_carrot_inventory() -> CarrotInventoryEntry: return village_history_manager.get_carrot_inventory()
func generate_village_event_journal(event_id: String) -> JournalEntry: return diary_manager.generate_village_event_journal(event_id, rabbit_data.rabbit_name, TimeManager.get_now(), village_manager.get_village_level())
func generate_construction_journal(result: ConstructionResult) -> JournalEntry: return diary_manager.generate_construction_journal(result, rabbit_data.rabbit_name, village_manager.get_village_level())
func generate_building_use_journal(result: BuildingUseResult) -> JournalEntry: return diary_manager.generate_building_use_journal(result, rabbit_data.rabbit_name, village_manager.get_village_level())
func generate_farm_growth_journal(cycle: FarmCycleData) -> JournalEntry: return diary_manager.generate_farm_growth_journal(cycle, rabbit_data.rabbit_name, village_manager.get_village_level())
func generate_harvest_journal(result: HarvestResult) -> JournalEntry: return diary_manager.generate_harvest_journal(result, rabbit_data.rabbit_name, village_manager.get_village_level())
func has_journal_for_village_event(id: String) -> bool: return diary_manager.has_journal_for_village_event(id)
func has_journal_for_construction(id: String) -> bool: return diary_manager.has_journal_for_construction(id)
func has_journal_for_building_use(id: String) -> bool: return diary_manager.has_journal_for_building_use(id)
func has_journal_for_farm_cycle(id: String) -> bool: return diary_manager.has_journal_for_farm_cycle(id)
func has_journal_for_harvest(id: String) -> bool: return diary_manager.has_journal_for_harvest(id)
func add_building_history(entry: BuildingHistoryEntry) -> bool: return village_history_manager.add_building_history(entry)
func add_construction_history(entry: ConstructionHistoryEntry) -> bool: return village_history_manager.add_construction_history(entry)
func add_building_use_history(entry: BuildingUseHistoryEntry) -> bool: return village_history_manager.add_building_use_history(entry)
func add_farm_cycle_history(entry: FarmCycleHistoryEntry) -> bool: return village_history_manager.add_farm_cycle_history(entry)
func add_harvest_history(entry: HarvestHistoryEntry) -> bool: return village_history_manager.add_harvest_history(entry)
func save_game() -> bool: return save_now()
func load_game() -> RabbitData: return save_manager.load_or_create(RabbitData.new(rabbit_name, initial_hunger, initial_mood, initial_energy))
func migrate_save_data(data: SaveData) -> SaveData: return save_manager.migrate_save_data(data)

func _on_c_village_progress_changed(progress: VillageProgressData) -> void:
	if progress != null and progress.village_level > _last_village_stage:
		_last_village_stage = progress.village_level
		diary_manager.generate_village_growth_journal(progress.village_level, rabbit_data.rabbit_name, TimeManager.get_now())
func _on_c_village_event_completed(result: VillageEventResult) -> void:
	if result == null: return
	diary_manager.generate_village_event_journal(result.event_id, rabbit_data.rabbit_name, result.applied_at, village_manager.get_village_level())
	if not result.unlocked_building_id.is_empty(): village_history_manager.mark_building_unlocked(result.unlocked_building_id, result.applied_at)
func _on_c_construction_started(record: ConstructionRecord) -> void:
	if record == null: return
	diary_manager.generate_construction_start_journal(record, rabbit_data.rabbit_name, village_manager.get_village_level())
	var h := ConstructionHistoryEntry.new(); h.construction_record_id = record.construction_record_id; h.building_id = record.building_id; h.slot_id = record.slot_id; h.started_at = record.started_at
	village_history_manager.add_construction_history(h); village_history_manager.mark_building_construction_started(record.building_id, record.slot_id, record.started_at)
func _on_c_building_use_completed(result: BuildingUseResult) -> void:
	if result == null: return
	diary_manager.generate_building_use_journal(result, rabbit_data.rabbit_name, village_manager.get_village_level())
	var h := BuildingUseHistoryEntry.new(); h.building_use_record_id = result.building_use_record_id if not result.building_use_record_id.is_empty() else result.interaction_record_id; h.building_id = result.building_id; h.started_at = result.started_at; h.completed_at = result.completed_at; h.use_count = result.use_count
	village_history_manager.add_building_use_history(h); village_history_manager.mark_building_used(result.building_id, result.completed_at, result.use_count)
func _on_c_farm_cycle_started(cycle: FarmCycleData) -> void:
	if cycle == null: return
	diary_manager.generate_farm_growth_journal(cycle, rabbit_data.rabbit_name, village_manager.get_village_level())
	var h := FarmCycleHistoryEntry.new(); h.farm_cycle_id = cycle.farm_cycle_id; h.started_at = cycle.started_at; h.ready_at = cycle.ready_at
	village_history_manager.add_farm_cycle_history(h)
func _on_c_harvested(result: HarvestResult) -> void:
	if result == null: return
	diary_manager.generate_harvest_journal(result, rabbit_data.rabbit_name, village_manager.get_village_level())
	var h := HarvestHistoryEntry.new(); h.harvest_record_id = result.harvest_record_id; h.farm_cycle_id = result.farm_cycle_id; h.harvested_at = result.harvested_at; h.harvest_amount = result.amount; h.is_first_harvest = result.is_first_harvest
	village_history_manager.add_harvest_history(h); village_history_manager.mark_farm_cycle_harvested(result.farm_cycle_id, result.harvested_at, result.amount); village_history_manager.add_carrots(result.amount, result.harvested_at)
func _on_c_notice_read(notice: DailyNoticeRecord) -> void:
	if notice == null: return
	diary_manager.generate_notice_journal(DailyNoticeRecord.from_dict(notice.to_dict()), rabbit_data.rabbit_name, village_manager.get_village_level())

func _on_growth_event_created(_event: GrowthEventData) -> void:
	rabbit_status_changed.emit(rabbit_data)
	save_manager.save_game()

func _on_growth_mark_unlocked(mark: GrowthMarkData, event: GrowthEventData) -> void:
	var journal := diary_manager.create_growth_journal(rabbit_data.rabbit_name, mark.id, event.triggered_at)
	if journal != null and not growth_album_manager.has_entry_for_growth_mark(mark.id):
		var entry := GrowthAlbumEntry.new(
			"album_%s" % mark.id,
			mark.id,
			mark.display_name,
			"Amy 從森林帶回了一片留在耳朵旁的小葉子。" if mark.id == "leaf_mark" else mark.description,
			mark.growth_path,
			mark.stage,
			mark.unlocked_at,
			journal.journal_id,
			journal.illustration_id
		)
		growth_album_manager.add_album_entry(entry)
	rabbit_status_changed.emit(rabbit_data)
	save_manager.save_game()

func get_activities_by_location(location_id: String) -> Array[ActivityData]: return activity_manager.get_activities_by_location(location_id)
func get_activity_data(activity_id: String) -> ActivityData: return activity_manager.get_activity_data(activity_id)
func get_forest_experience() -> int: return rabbit_data.forest_experience
func get_fishing_experience() -> int: return rabbit_data.fishing_experience
func get_intimacy() -> int: return rabbit_data.intimacy
func get_forest_activity_count() -> int: return rabbit_data.forest_activity_count
func get_fishing_activity_count() -> int: return rabbit_data.fishing_activity_count
func has_growth_mark(mark_id: String) -> bool: return growth_manager.has_growth_mark(mark_id)
func get_unlocked_growth_marks() -> Array[GrowthMarkData]: return growth_manager.get_unlocked_growth_marks()
func has_pending_growth_event() -> bool: return growth_manager.has_pending_growth_event()
func get_pending_growth_event() -> GrowthEventData: return growth_manager.get_pending_growth_event()
func confirm_growth_event(event_id: String) -> bool: return growth_manager.confirm_growth_event(event_id)
func get_growth_tendency(path_id: String) -> String: return growth_manager.get_growth_tendency(path_id)
func get_all_activity_records() -> Array[Dictionary]: return growth_manager.get_all_activity_records()

func _on_rabbit_returned(returned_rabbit: RabbitData) -> void:
	_update_character_visibility()
	rabbit_status_changed.emit(returned_rabbit)
	save_manager.save_game()

func _on_data_changed() -> void:
	_request_save()

func _request_save() -> void:
	if _save_requested:
		return
	_save_requested = true
	call_deferred("_flush_save")

func _flush_save() -> void:
	_save_requested = false
	save_manager.save_game()

func _update_character_visibility() -> void:
	if rabbit_data == null:
		return
	character_sprite.visible = not rabbit_data.is_away
	collision_shape.set_deferred("disabled", rabbit_data.is_away)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(save_manager):
		save_manager.save_game()
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(save_manager):
			save_manager.save_game()
		get_tree().quit()

func print_status() -> void:
	if rabbit_data:
		print(rabbit_data.to_dict())
