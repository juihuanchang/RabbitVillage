class_name SaveManager
extends Node


const SAVE_PATH: String = "user://save.json"
const SAVE_VERSION: int = 1


var _rabbit_manager: RabbitManager
var _diary_manager: DiaryManager
var _activity_manager: ActivityManager


## 使用前先將目前遊戲使用的三個管理器交給 SaveManager。
func setup(
		rabbit_manager: RabbitManager,
		diary_manager: DiaryManager,
		activity_manager: ActivityManager
) -> void:
	_rabbit_manager = rabbit_manager
	_diary_manager = diary_manager
	_activity_manager = activity_manager


## 提供給 B、Player 或其他系統主動呼叫。
func save_game() -> bool:
	if not _has_dependencies():
		push_error("SaveManager：尚未執行 setup()。")
		return false

	var save_data := SaveData.new()
	save_data.save_version = SAVE_VERSION
	save_data.last_saved_at = TimeManager.get_now()

	# 保存所有兔子資料。
	for rabbit: RabbitData in _rabbit_manager.get_all_rabbits():
		if rabbit != null:
			save_data.rabbits.append(rabbit.to_dict())

	# 保存目前活動。
	# 沒有進行中的活動時維持空 Dictionary。
	if _activity_manager.active_activity != null:
		save_data.current_activity = (
			_activity_manager.active_activity.to_dict()
		)

	# 保存全部日記。
	save_data.journals = _diary_manager.to_array()

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error(
			"SaveManager：無法開啟存檔，錯誤碼：" +
			str(FileAccess.get_open_error())
		)
		return false

	var json_text := JSON.stringify(
		save_data.to_dict(),
		"\t"
	)

	file.store_string(json_text)
	file.flush()
	file.close()

	print("SaveManager：存檔完成：", SAVE_PATH)
	return true


## 啟動遊戲時呼叫。
## 有存檔就讀取；沒有或損壞時建立預設存檔。
## 回傳遊戲目前主要使用的 RabbitData。
func load_or_create(
		default_rabbit: RabbitData
) -> RabbitData:
	if not _has_dependencies():
		push_error("SaveManager：尚未執行 setup()。")
		return default_rabbit

	if default_rabbit == null:
		push_error("SaveManager：預設兔子不可為 null。")
		return null

	if not has_save_file():
		print("SaveManager：第一次進入遊戲，建立預設存檔。")
		return _create_default_save(default_rabbit)

	var json_text := FileAccess.get_file_as_string(
		SAVE_PATH
	)

	if json_text.strip_edges().is_empty():
		return _recover_corrupted_save(
			default_rabbit,
			"存檔內容為空。"
		)

	var json := JSON.new()
	var parse_error := json.parse(json_text)

	if parse_error != OK:
		var reason := (
			"JSON 解析失敗：%s，第 %d 行"
			% [
				json.get_error_message(),
				json.get_error_line()
			]
		)

		return _recover_corrupted_save(
			default_rabbit,
			reason
		)

	if typeof(json.data) != TYPE_DICTIONARY:
		return _recover_corrupted_save(
			default_rabbit,
			"存檔最外層不是 Dictionary。"
		)

	var save_data := SaveData.from_dict(
		json.data as Dictionary
	)

	if not save_data.is_supported_version():
		return _recover_corrupted_save(
			default_rabbit,
			"不支援的存檔版本：" +
			str(save_data.save_version)
		)

	return _apply_save_data(
		save_data,
		default_rabbit
	)


## 將讀取到的存檔套用到遊戲。
func _apply_save_data(
		save_data: SaveData,
		default_rabbit: RabbitData
) -> RabbitData:
	_rabbit_manager.clear_rabbits()
	_diary_manager.load_from_array(
		save_data.journals
	)
	_activity_manager.active_activity = null

	# 還原兔子。
	for rabbit_data: Dictionary in save_data.rabbits:
		var restored_rabbit := RabbitData.from_dict(
			rabbit_data
		)

		if restored_rabbit != null:
			_rabbit_manager.add_rabbit(
				restored_rabbit
			)

	# 存檔中沒有有效兔子時，使用預設兔子。
	if _rabbit_manager.get_rabbit_count() == 0:
		default_rabbit.is_away = false
		_rabbit_manager.add_rabbit(default_rabbit)

	var selected_rabbit := _rabbit_manager.get_rabbit(
		default_rabbit.rabbit_name
	)

	if selected_rabbit == null:
		var all_rabbits := (
			_rabbit_manager.get_all_rabbits()
		)

		if not all_rabbits.is_empty():
			selected_rabbit = all_rabbits[0]
		else:
			selected_rabbit = default_rabbit

	# 沒有進行中活動時，確保兔子在家。
	if save_data.current_activity.is_empty():
		for rabbit: RabbitData in (
			_rabbit_manager.get_all_rabbits()
		):
			rabbit.is_away = false

		print(
			"SaveManager：讀檔完成，日記數量：",
			_diary_manager.get_journal_count()
		)

		return selected_rabbit

	var activity_rabbit_name := str(
		save_data.current_activity.get(
			"rabbit_name",
			""
		)
	)

	var activity_rabbit := _rabbit_manager.get_rabbit(
		activity_rabbit_name
	)

	var restored_activity := (
		ActiveActivityData.from_dict(
			save_data.current_activity,
			activity_rabbit
		)
	)

	# 活動資料損壞時保留其他資料，
	# 只清除目前活動並讓兔子回家。
	if restored_activity == null:
		push_error(
			"SaveManager：目前活動無法還原，已清除活動資料。"
		)

		for rabbit: RabbitData in (
			_rabbit_manager.get_all_rabbits()
		):
			rabbit.is_away = false

		_activity_manager.active_activity = null
		save_game()
		return selected_rabbit

	# 如果活動已標記完成，但當時尚未成功產生日記，
	# 讀檔時補上日記，且不再次套用數值變化。
	if restored_activity.is_completed:
		restored_activity.rabbit.is_away = false
		_activity_manager.active_activity = null

		if not _diary_manager.has_activity_record_id(
			restored_activity.activity_record_id
		):
			_diary_manager.create_journal_from_activity(
				restored_activity
			)

		save_game()
		return selected_rabbit

	# 尚未完成的活動恢復到 ActivityManager，
	# 之後呼叫 check_for_completion() 判斷是否已到期。
	restored_activity.rabbit.is_away = true
	_activity_manager.active_activity = restored_activity

	print(
		"SaveManager：讀檔完成，恢復活動：",
		restored_activity.activity.activity_name
	)

	return selected_rabbit


## 第一次進入遊戲時建立預設資料與存檔。
func _create_default_save(
		default_rabbit: RabbitData
) -> RabbitData:
	_rabbit_manager.clear_rabbits()
	_diary_manager.clear_journals()
	_activity_manager.active_activity = null

	default_rabbit.is_away = false

	if default_rabbit.rabbit_name.is_empty():
		default_rabbit.rabbit_name = "Amy"

	_rabbit_manager.add_rabbit(default_rabbit)

	if not save_game():
		push_error("SaveManager：建立預設存檔失敗。")

	return default_rabbit


## 存檔無法解析時：
## 1. 顯示錯誤
## 2. 保留損壞檔案
## 3. 建立新的預設存檔
func _recover_corrupted_save(
		default_rabbit: RabbitData,
		reason: String
) -> RabbitData:
	push_error(
		"SaveManager：存檔損壞，將建立新存檔。原因：" +
		reason
	)

	_backup_corrupted_save()

	return _create_default_save(
		default_rabbit
	)


## 將損壞存檔改名保留，方便未來擴充復原機制。
func _backup_corrupted_save() -> void:
	if not has_save_file():
		return

	var backup_path := (
		"user://save_corrupted_%d.json"
		% int(TimeManager.get_now())
	)

	var source_absolute := (
		ProjectSettings.globalize_path(
			SAVE_PATH
		)
	)

	var backup_absolute := (
		ProjectSettings.globalize_path(
			backup_path
		)
	)

	var rename_error := DirAccess.rename_absolute(
		source_absolute,
		backup_absolute
	)

	if rename_error == OK:
		print(
			"SaveManager：損壞存檔已保留於：",
			backup_path
		)
	else:
		push_warning(
			"SaveManager：無法備份損壞存檔，錯誤碼：" +
			str(rename_error)
		)


func has_save_file() -> bool:
	return FileAccess.file_exists(
		SAVE_PATH
	)


## 測試第一次進入遊戲時可以使用。
func delete_save() -> bool:
	if not has_save_file():
		return false

	var absolute_path := ProjectSettings.globalize_path(
		SAVE_PATH
	)

	var remove_error := DirAccess.remove_absolute(
		absolute_path
	)

	if remove_error != OK:
		push_error(
			"SaveManager：刪除存檔失敗，錯誤碼：" +
			str(remove_error)
		)
		return false

	print("SaveManager：存檔已刪除。")
	return true


func _has_dependencies() -> bool:
	return (
		_rabbit_manager != null
		and _diary_manager != null
		and _activity_manager != null
	)