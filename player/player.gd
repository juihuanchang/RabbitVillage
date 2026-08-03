class_name RabbitCharacter
extends CharacterBody2D

signal rabbit_status_changed(rabbit: RabbitData)

@export_category("Rabbit")
@export var rabbit_name := "Amy"
@export_range(0, 100) var initial_hunger := 100
@export_range(0, 100) var initial_mood := 50
@export_range(0, 100) var initial_energy := 100
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
var _save_requested := false
var _home_tick_elapsed := 0.0

const HOME_TICK_SECONDS := 15.0
const HOME_ENERGY_GAIN := 5
const HOME_HUNGER_LOSS := 2
const HOME_MOOD_LOSS := 2

func _ready() -> void:
	get_tree().auto_accept_quit = false
	for manager: Node in [activity_manager, rabbit_manager, diary_manager, save_manager, growth_manager, growth_album_manager]:
		add_child(manager)
	save_manager.setup(rabbit_manager, diary_manager, activity_manager, growth_manager, growth_album_manager)
	rabbit_data = save_manager.load_or_create(
		RabbitData.new(rabbit_name, initial_hunger, initial_mood, initial_energy)
	)
	activity_manager.setup(rabbit_data)
	growth_manager.setup(rabbit_data)
	activity_manager.activity_started.connect(_on_activity_started)
	activity_manager.activity_completed.connect(_on_activity_completed)
	growth_manager.growth_event_created.connect(_on_growth_event_created)
	growth_manager.growth_mark_unlocked.connect(_on_growth_mark_unlocked)
	activity_manager.rabbit_returned.connect(_on_rabbit_returned)
	rabbit_data.data_changed.connect(_on_data_changed)
	diary_manager.journal_added.connect(func(_entry: JournalEntry) -> void: _request_save())
	growth_album_manager.album_entry_added.connect(func(_entry: GrowthAlbumEntry) -> void: _request_save())
	_update_character_visibility()
	activity_manager.check_for_completion()
	rabbit_status_changed.emit(rabbit_data)

func _process(delta: float) -> void:
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
	rabbit_status_changed.emit(rabbit_data)
	save_manager.save_game()

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
