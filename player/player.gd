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
var village_data: VillageData
var _save_requested := false
var _home_tick_elapsed := 0.0
var _test_reset_elapsed := 0.0

const TEST_AUTO_RESET_SECONDS := 30.0
const TEST_AUTO_RESET_VALUE := 70
const HOME_TICK_SECONDS := 15.0
const HOME_ENERGY_GAIN := 5
const HOME_HUNGER_LOSS := 2
const HOME_MOOD_LOSS := 2

func _ready() -> void:
	get_tree().auto_accept_quit = false
	for manager: Node in [activity_manager, rabbit_manager, diary_manager, save_manager, growth_manager, growth_album_manager, village_manager, building_manager, construction_manager, village_event_manager, building_interaction_manager, farm_manager, notice_manager]:
		add_child(manager)
	save_manager.setup(rabbit_manager, diary_manager, activity_manager, growth_manager, growth_album_manager)
	rabbit_data = save_manager.load_or_create(
		RabbitData.new(rabbit_name, initial_hunger, initial_mood, initial_energy)
	)
	activity_manager.setup(rabbit_data)
	growth_manager.setup(rabbit_data)
	village_data = VillageData.from_dict(rabbit_data.village_data)
	village_manager.setup(village_data)
	building_manager.setup(village_data)
	construction_manager.setup(village_data, building_manager, village_manager)
	village_event_manager.setup(village_data, rabbit_data, building_manager, growth_manager)
	farm_manager.setup(village_data, building_manager, village_manager)
	building_interaction_manager.setup(village_data, rabbit_data, activity_manager, building_manager, village_manager, growth_manager, village_event_manager)
	notice_manager.setup(village_data, village_manager, building_manager, construction_manager, farm_manager, growth_manager)
	activity_manager.activity_started.connect(_on_activity_started)
	activity_manager.activity_completed.connect(_on_activity_completed)
	growth_manager.growth_event_created.connect(_on_growth_event_created)
	growth_manager.growth_mark_unlocked.connect(_on_growth_mark_unlocked)
	for manager_signal in [village_manager.village_progress_changed, construction_manager.construction_started, construction_manager.construction_completed, village_event_manager.village_event_created, village_event_manager.village_event_completed, building_interaction_manager.building_interaction_started, building_interaction_manager.building_interaction_completed, farm_manager.farm_cycle_started, farm_manager.farm_ready, farm_manager.carrots_harvested, notice_manager.notice_generated, notice_manager.notice_read]:
		manager_signal.connect(func(_value = null) -> void: _on_village_state_changed())
	construction_manager.construction_completed.connect(_on_construction_completed)
	building_interaction_manager.building_interaction_completed.connect(func(_result: BuildingUseResult) -> void: village_event_manager.check_event_conditions())
	notice_manager.notice_read.connect(func(_notice: DailyNoticeData) -> void: village_event_manager.check_event_conditions())
	farm_manager.carrots_harvested.connect(func(_result: HarvestResult) -> void: village_event_manager.check_event_conditions())
	activity_manager.rabbit_returned.connect(_on_rabbit_returned)
	rabbit_data.data_changed.connect(_on_data_changed)
	diary_manager.journal_added.connect(func(_entry: JournalEntry) -> void: _request_save())
	growth_album_manager.album_entry_added.connect(func(_entry: GrowthAlbumEntry) -> void: _request_save())
	_update_character_visibility()
	activity_manager.check_for_completion()
	construction_manager.check_construction_completion()
	building_interaction_manager.check_rest_pavilion_completion()
	farm_manager.check_farm_ready_state()
	village_event_manager.check_event_conditions()
	_on_village_state_changed()
	rabbit_status_changed.emit(rabbit_data)

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

func StartActivity(activity_id: String) -> Dictionary:
	return start_activity(activity_id)

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
	if result.building_id == "carrot_farm": farm_manager.start_first_growth_cycle()
	village_event_manager.check_event_conditions()

func get_village_progress() -> VillageProgressData: return village_manager.get_village_progress()
func get_village_level() -> int: return village_manager.get_village_level()
func get_village_experience() -> int: return village_manager.get_village_experience()
func has_pending_village_event() -> bool: return village_event_manager.has_pending_event()
func get_pending_village_event() -> VillageEventData: return village_event_manager.get_pending_event()
func confirm_village_event(id: String) -> VillageEventResult: return village_event_manager.confirm_event(id)
func GetVillageProgress() -> VillageProgressData: return get_village_progress()
func GetVillageLevel() -> int: return get_village_level()
func GetVillageExperience() -> int: return get_village_experience()
func HasPendingVillageEvent() -> bool: return has_pending_village_event()
func GetPendingVillageEvent() -> VillageEventData: return get_pending_village_event()
func ConfirmVillageEvent(id: String) -> VillageEventResult: return confirm_village_event(id)
func GetAllBuildings() -> Array[BuildingData]: return building_manager.get_all_buildings()
func GetBuilding(id: String) -> BuildingData: return building_manager.get_building(id)
func CanPlaceBuilding(id: String, slot: String) -> Dictionary: return building_manager.can_place_building(id, slot)
func PlaceBuilding(id: String, slot: String) -> Dictionary: var r := building_manager.place_building(id, slot); _on_village_state_changed(); return r
func GetBuildingState(id: String) -> String: return building_manager.get_building_state(id)
func StartConstruction(id: String) -> Dictionary: return construction_manager.start_construction(id)
func HasActiveConstruction() -> bool: return construction_manager.has_active_construction()
func GetActiveConstruction() -> ConstructionRecord: return construction_manager.get_active_construction()
func GetConstructionRemainingSeconds() -> float: return construction_manager.get_construction_remaining_seconds()
func GetConstructionEndTime() -> float: return construction_manager.get_construction_end_time()
func CanUseRestPavilion() -> Dictionary: return building_interaction_manager.can_use_rest_pavilion()
func StartRestPavilionUse() -> Dictionary: return building_interaction_manager.start_rest_pavilion_use()
func GetRestPavilionUseRemaining() -> float: return building_interaction_manager.get_rest_pavilion_use_remaining()
func GetRestPavilionCooldownRemaining() -> float: return building_interaction_manager.get_rest_pavilion_cooldown_remaining()
func HasTodayNotice() -> bool: return notice_manager.has_today_notice()
func GetTodayNotice() -> DailyNoticeData: return notice_manager.get_today_notice()
func MarkTodayNoticeRead() -> bool: return notice_manager.mark_today_notice_read()
func GetNoticeConditionContext() -> Dictionary: return notice_manager.get_notice_condition_context()
func GetFarmState() -> String: return farm_manager.get_farm_state()
func StartFirstGrowthCycle() -> Dictionary: return farm_manager.start_first_growth_cycle()
func StartNextGrowthCycle() -> Dictionary: return farm_manager.start_next_growth_cycle()
func HasActiveGrowthCycle() -> bool: return farm_manager.has_active_growth_cycle()
func IsFarmReady() -> bool: return farm_manager.is_farm_ready()
func GetFarmRemainingSeconds() -> float: return farm_manager.get_farm_remaining_seconds()
func GetFarmReadyTime() -> float: return farm_manager.get_farm_ready_time()
func HarvestCarrots() -> HarvestResult: return farm_manager.harvest_carrots()
func GetCarrotAmount() -> int: return farm_manager.get_carrot_amount()
func GetTotalHarvestCount() -> int: return farm_manager.get_total_harvest_count()
func GetCurrentFarmCycle() -> FarmCycleData: return farm_manager.get_current_farm_cycle()

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

func GetActivitiesByLocation(location_id: String) -> Array[ActivityData]: return get_activities_by_location(location_id)
func GetActivityData(activity_id: String) -> ActivityData: return get_activity_data(activity_id)
func GetForestExperience() -> int: return get_forest_experience()
func GetFishingExperience() -> int: return get_fishing_experience()
func GetIntimacy() -> int: return get_intimacy()
func GetForestActivityCount() -> int: return get_forest_activity_count()
func GetFishingActivityCount() -> int: return get_fishing_activity_count()
func HasGrowthMark(mark_id: String) -> bool: return has_growth_mark(mark_id)
func GetUnlockedGrowthMarks() -> Array[GrowthMarkData]: return get_unlocked_growth_marks()
func HasPendingGrowthEvent() -> bool: return has_pending_growth_event()
func GetPendingGrowthEvent() -> GrowthEventData: return get_pending_growth_event()
func ConfirmGrowthEvent(event_id: String) -> bool: return confirm_growth_event(event_id)
func GetGrowthTendency(path_id: String) -> String: return get_growth_tendency(path_id)
func GetGrowthAlbumEntries() -> Array[GrowthAlbumEntry]: return get_growth_album_entries()
func GetAllActivityRecords() -> Array[Dictionary]: return get_all_activity_records()

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
