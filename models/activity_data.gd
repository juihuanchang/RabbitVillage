class_name ActivityData
extends Resource


## 系統使用的固定活動編號，不應隨顯示名稱改變。
## 例如：forest_walk、fishing
@export var activity_id: String = ""

## 顯示給玩家看的活動名稱。
@export var activity_name: String = ""

@export_range(0.1, 86400.0, 0.1, "suffix:s")
var duration_seconds: float = 30.0

@export var energy_change: int = 0
@export var hunger_change: int = 0
@export var mood_change: int = 0


func _init(
		initial_id: String = "",
		initial_name: String = "",
		initial_duration_seconds: float = 30.0,
		initial_energy_change: int = 0,
		initial_hunger_change: int = 0,
		initial_mood_change: int = 0
) -> void:
	activity_id = initial_id.strip_edges().to_lower()
	activity_name = initial_name.strip_edges()
	duration_seconds = maxf(initial_duration_seconds, 0.1)
	energy_change = initial_energy_change
	hunger_change = initial_hunger_change
	mood_change = initial_mood_change


## 建立森林散步活動。
static func create_forest_walk() -> ActivityData:
	return ActivityData.new(
		"forest_walk",
		"森林散步",
		10.0,
		-5,
		8,
		8
	)


## 先準備釣魚活動資料，之後 B 可以直接使用。
static func create_fishing() -> ActivityData:
	return ActivityData.new(
		"fishing",
		"釣魚",
		10.0,
		-5,
		8,
		5
	)


## 轉換成可寫入 JSON 的資料。
func to_dict() -> Dictionary:
	return {
		"activity_id": activity_id,
		"activity_name": activity_name,
		"duration_seconds": duration_seconds,
		"energy_change": energy_change,
		"hunger_change": hunger_change,
		"mood_change": mood_change
	}


## 從存檔資料還原活動。
static func from_dict(data: Dictionary) -> ActivityData:
	return ActivityData.new(
		str(data.get("activity_id", "")),
		str(data.get("activity_name", "")),
		float(data.get("duration_seconds", 30.0)),
		int(data.get("energy_change", 0)),
		int(data.get("hunger_change", 0)),
		int(data.get("mood_change", 0))
	)