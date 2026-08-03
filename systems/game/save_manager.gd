class_name SaveManager
extends Node

const SAVE_PATH := "user://save.json"
const SAVE_BACKUP_PATH := "user://save_backup.json"
const SAVE_TEMP_PATH := "user://save_temp.json"

var _rabbit_manager: RabbitManager
var _diary_manager: DiaryManager
var _activity_manager: ActivityManager
var _growth_manager: GrowthManager
var _growth_album_manager: GrowthAlbumManager

func setup(rabbits: RabbitManager, diary: DiaryManager, activities: ActivityManager, growth: GrowthManager = null, growth_album: GrowthAlbumManager = null) -> void:
	_rabbit_manager = rabbits
	_diary_manager = diary
	_activity_manager = activities
	_growth_manager = growth
	_growth_album_manager = growth_album

func save_game() -> bool:
	if not _has_dependencies():
		return false
	var data := SaveData.new()
	data.last_saved_at = TimeManager.get_now()
	for rabbit: RabbitData in _rabbit_manager.get_all_rabbits():
		data.rabbits.append(rabbit.to_dict())
		# Mirror the active rabbit's week-three values at top level for compatibility.
		data.forest_experience = rabbit.forest_experience
		data.fishing_experience = rabbit.fishing_experience
		data.intimacy = rabbit.intimacy
		data.forest_activity_count = rabbit.forest_activity_count
		data.fishing_activity_count = rabbit.fishing_activity_count
		data.home_activity_count = rabbit.home_activity_count
		data.total_activity_count = rabbit.total_activity_count
		data.unlocked_growth_marks = rabbit.unlocked_growth_marks.duplicate(true)
		data.pending_growth_event = rabbit.pending_growth_event.duplicate(true)
	if _activity_manager.active_activity != null:
		data.current_activity = _activity_manager.active_activity.to_dict()
	data.completed_activity_ids = _activity_manager.get_completed_record_ids()
	data.journals = _diary_manager.to_array()
	if _growth_manager != null:
		data.all_activity_records = _growth_manager.get_all_activity_records()
		data.growth_tendencies = _growth_manager.get_growth_tendencies()
	if _growth_album_manager != null:
		data.growth_album_entries = _growth_album_manager.to_array()
	_create_backup_if_possible()
	return _write_save_file(data)

func load_or_create(default_rabbit: RabbitData) -> RabbitData:
	var data := _load_save_data()
	if data == null:
		return _create_default(default_rabbit)
	_rabbit_manager.clear_rabbits()
	_activity_manager.set_completed_record_ids(data.completed_activity_ids)
	_diary_manager.load_from_array(data.journals)
	for raw: Dictionary in data.rabbits:
		_rabbit_manager.add_rabbit(RabbitData.from_dict(raw))
	var rabbit := _rabbit_manager.get_rabbit(default_rabbit.rabbit_name)
	if rabbit == null:
		rabbit = default_rabbit
		_apply_week3_defaults_to_rabbit(rabbit, data)
		_rabbit_manager.add_rabbit(rabbit)
	if _growth_manager != null:
		_growth_manager.setup(rabbit)
		_growth_manager.load_from_save_data(data)
	if _growth_album_manager != null:
		_growth_album_manager.load_from_array(data.growth_album_entries)
	if not data.current_activity.is_empty():
		var owner_name := str(data.current_activity.get("rabbit_name", rabbit.rabbit_name))
		var activity_owner := _rabbit_manager.get_rabbit(owner_name)
		var restored := ActiveActivityData.from_dict(data.current_activity, activity_owner)
		if restored != null and not restored.is_completed:
			var current_definition := _activity_manager.get_activity(restored.activity.activity_id)
			if current_definition != null:
				restored.activity = current_definition
			_activity_manager.restore_activity(restored)
		else:
			rabbit.is_away = false
			rabbit.current_activity = ""
			rabbit.current_state = ""
	else:
		rabbit.is_away = false
		rabbit.current_activity = ""
		rabbit.current_state = ""
	return rabbit

func _load_save_data() -> SaveData:
	var primary := _read_save_from_path(SAVE_PATH)
	if primary != null:
		return primary
	var backup := _read_save_from_path(SAVE_BACKUP_PATH)
	if backup != null:
		return backup
	return null

func _read_save_from_path(path: String) -> SaveData:
	if not FileAccess.file_exists(path):
		return null
	var file_text := FileAccess.get_file_as_string(path)
	if file_text.is_empty():
		return null
	var json := JSON.new()
	if json.parse(file_text) != OK or not (json.data is Dictionary):
		return null
	var data := SaveData.from_dict(json.data)
	if not data.is_supported_version():
		return null
	return data

func _create_default(rabbit: RabbitData) -> RabbitData:
	_rabbit_manager.clear_rabbits()
	_diary_manager.clear_journals()
	_activity_manager.restore_activity(null)
	if _growth_album_manager != null:
		_growth_album_manager.clear_entries()
	if _growth_manager != null:
		_growth_manager.setup(rabbit)
		_growth_manager.load_from_save_data(SaveData.new())
	_rabbit_manager.add_rabbit(rabbit)
	save_game()
	return rabbit

func _apply_week3_defaults_to_rabbit(rabbit: RabbitData, data: SaveData) -> void:
	rabbit.forest_experience = int(data.forest_experience)
	rabbit.fishing_experience = int(data.fishing_experience)
	rabbit.intimacy = int(data.intimacy)
	rabbit.forest_activity_count = int(data.forest_activity_count)
	rabbit.fishing_activity_count = int(data.fishing_activity_count)
	rabbit.home_activity_count = int(data.home_activity_count)
	rabbit.total_activity_count = int(data.total_activity_count)
	if rabbit.unlocked_growth_marks.is_empty():
		rabbit.unlocked_growth_marks = data.unlocked_growth_marks.duplicate(true)
	if rabbit.pending_growth_event.is_empty():
		rabbit.pending_growth_event = data.pending_growth_event.duplicate(true)

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BACKUP_PATH)

func _has_dependencies() -> bool:
	return _rabbit_manager != null and _diary_manager != null and _activity_manager != null

func _create_backup_if_possible() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var global_save := ProjectSettings.globalize_path(SAVE_PATH)
	var global_backup := ProjectSettings.globalize_path(SAVE_BACKUP_PATH)
	if FileAccess.file_exists(SAVE_BACKUP_PATH):
		DirAccess.remove_absolute(global_backup)
	DirAccess.copy_absolute(global_save, global_backup)

func _write_save_file(data: SaveData) -> bool:
	var temp_file := FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if temp_file == null:
		return false
	temp_file.store_string(JSON.stringify(data.to_dict(), "\t"))
	temp_file.close()
	var global_temp := ProjectSettings.globalize_path(SAVE_TEMP_PATH)
	var global_save := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(global_save)
	var rename_result := DirAccess.rename_absolute(global_temp, global_save)
	return rename_result == OK
