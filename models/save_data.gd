class_name SaveData
extends Resource


## 目前支援的存檔版本。
const CURRENT_VERSION: int = 1


## 存檔版本。
var save_version: int = CURRENT_VERSION

## 所有兔子資料。
var rabbits: Array[Dictionary] = []

## 目前進行中的活動。
## 沒有活動時為空 Dictionary。
var current_activity: Dictionary = {}

## 所有日記資料。
var journals: Array[Dictionary] = []

## 最後存檔時間，使用 Unix 時間。
var last_saved_at: float = 0.0


## 將完整存檔轉成可寫入 JSON 的 Dictionary。
func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"rabbits": rabbits,
		"current_activity": current_activity,
		"journals": journals,
		"last_saved_at": last_saved_at
	}


## 將 JSON Dictionary 還原成 SaveData。
static func from_dict(data: Dictionary) -> SaveData:
	var save_data := SaveData.new()

	# 相容之前使用 "version" 的舊存檔。
	save_data.save_version = int(
		data.get(
			"save_version",
			data.get("version", 0)
		)
	)

	var raw_rabbits: Variant = data.get(
		"rabbits",
		[]
	)

	if raw_rabbits is Array:
		for item: Variant in raw_rabbits:
			if item is Dictionary:
				save_data.rabbits.append(
					item as Dictionary
				)
			else:
				push_warning(
					"SaveData：忽略格式錯誤的兔子資料。"
				)
	else:
		push_warning(
			"SaveData：rabbits 不是 Array。"
		)

	var raw_activity: Variant = data.get(
		"current_activity",
		{}
	)

	if raw_activity is Dictionary:
		save_data.current_activity = (
			raw_activity as Dictionary
		)
	else:
		push_warning(
			"SaveData：current_activity 格式錯誤，視為沒有活動。"
		)
		save_data.current_activity = {}

	var raw_journals: Variant = data.get(
		"journals",
		[]
	)

	if raw_journals is Array:
		for item: Variant in raw_journals:
			if item is Dictionary:
				save_data.journals.append(
					item as Dictionary
				)
			else:
				push_warning(
					"SaveData：忽略格式錯誤的日記資料。"
				)
	else:
		push_warning(
			"SaveData：journals 不是 Array。"
		)

	save_data.last_saved_at = float(
		data.get("last_saved_at", 0.0)
	)

	return save_data


## 檢查存檔版本是否為目前支援的版本。
func is_supported_version() -> bool:
	return save_version == CURRENT_VERSION