class_name SaveManager
extends Node


const SAVE_PATH := "user://save.json"


## 儲存兔子和日記。
func save_game(
		rabbit_manager: RabbitManager,
		diary_manager: DiaryManager
) -> bool:
	if rabbit_manager == null:
		push_error("SaveManager：rabbit_manager 不可為 null")
		return false

	if diary_manager == null:
		push_error("SaveManager：diary_manager 不可為 null")
		return false

	var save_data := SaveData.new()

	for rabbit: RabbitData in rabbit_manager.get_all_rabbits():
		save_data.rabbits.append(_rabbit_to_dict(rabbit))

	save_data.journals = diary_manager.to_array()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("無法開啟存檔：" + SAVE_PATH)
		return false

	var json_text := JSON.stringify(
		save_data.to_dict(),
		"\t"
	)

	file.store_string(json_text)
	file.close()

	print("遊戲已存檔：", SAVE_PATH)
	return true


## 讀取兔子和日記。
func load_game(
		rabbit_manager: RabbitManager,
		diary_manager: DiaryManager
) -> bool:
	if rabbit_manager == null or diary_manager == null:
		return false

	if not FileAccess.file_exists(SAVE_PATH):
		print("目前沒有存檔")
		return false

	var json_text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed_data: Variant = JSON.parse_string(json_text)

	if typeof(parsed_data) != TYPE_DICTIONARY:
		push_error("存檔 JSON 格式錯誤")
		return false

	var save_data := SaveData.from_dict(
		parsed_data as Dictionary
	)

	rabbit_manager.clear_rabbits()

	for rabbit_data: Dictionary in save_data.rabbits:
		var rabbit := _rabbit_from_dict(rabbit_data)

		if rabbit != null:
			rabbit_manager.add_rabbit(rabbit)

	diary_manager.load_from_array(save_data.journals)

	print("遊戲讀檔完成")
	return true


## 將 RabbitData 轉換成 Dictionary。
func _rabbit_to_dict(rabbit: RabbitData) -> Dictionary:
	return {
		"rabbit_name": rabbit.rabbit_name,
		"hunger": rabbit.hunger,
		"mood": rabbit.mood,
		"energy": rabbit.energy
	}


## 將 Dictionary 還原成 RabbitData。
func _rabbit_from_dict(data: Dictionary) -> RabbitData:
	var rabbit_name := str(data.get("rabbit_name", ""))

	if rabbit_name.is_empty():
		return null

	return RabbitData.new(
		rabbit_name,
		int(data.get("hunger", 100)),
		int(data.get("mood", 100)),
		int(data.get("energy", 100))
	)


## 是否已經有存檔。
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 刪除存檔，測試時可能會用到。
func delete_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	return DirAccess.remove_absolute(
		ProjectSettings.globalize_path(SAVE_PATH)
	) == OK