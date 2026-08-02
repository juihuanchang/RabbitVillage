class_name SaveManager
extends Node

const SAVE_PATH := "user://save.json"

var _rabbit_manager: RabbitManager
var _diary_manager: DiaryManager
var _activity_manager: ActivityManager

func setup(rabbits: RabbitManager, diary: DiaryManager, activities: ActivityManager) -> void:
	_rabbit_manager = rabbits
	_diary_manager = diary
	_activity_manager = activities

func save_game() -> bool:
	if not _has_dependencies():
		return false
	var data := SaveData.new()
	data.last_saved_at = TimeManager.get_now()
	for rabbit: RabbitData in _rabbit_manager.get_all_rabbits():
		data.rabbits.append(rabbit.to_dict())
	if _activity_manager.active_activity != null:
		data.current_activity = _activity_manager.active_activity.to_dict()
	data.completed_activity_ids = _activity_manager.get_completed_record_ids()
	data.journals = _diary_manager.to_array()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data.to_dict(), "\t"))
	file.close()
	return true

func load_or_create(default_rabbit: RabbitData) -> RabbitData:
	if not has_save_file():
		return _create_default(default_rabbit)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(SAVE_PATH)) != OK or not (json.data is Dictionary):
		return _create_default(default_rabbit)
	var data := SaveData.from_dict(json.data)
	if not data.is_supported_version():
		return _create_default(default_rabbit)
	_rabbit_manager.clear_rabbits()
	_activity_manager.set_completed_record_ids(data.completed_activity_ids)
	_diary_manager.load_from_array(data.journals)
	for raw: Dictionary in data.rabbits:
		_rabbit_manager.add_rabbit(RabbitData.from_dict(raw))
	var rabbit := _rabbit_manager.get_rabbit(default_rabbit.rabbit_name)
	if rabbit == null:
		rabbit = default_rabbit
		_rabbit_manager.add_rabbit(rabbit)
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

func _create_default(rabbit: RabbitData) -> RabbitData:
	_rabbit_manager.clear_rabbits()
	_diary_manager.clear_journals()
	_activity_manager.restore_activity(null)
	_rabbit_manager.add_rabbit(rabbit)
	save_game()
	return rabbit

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func _has_dependencies() -> bool:
	return _rabbit_manager != null and _diary_manager != null and _activity_manager != null
