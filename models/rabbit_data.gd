class_name RabbitData
extends Resource


## 名稱、飢餓、心情、體力或外出狀態改變時發出。
## SaveManager 之後會監聽這個訊號並自動存檔。
signal data_changed


@export var rabbit_name: String = "":
	set(value):
		var new_name := value.strip_edges()

		if rabbit_name == new_name:
			return

		rabbit_name = new_name
		data_changed.emit()


@export_range(0, 100) var hunger: int = 100:
	set(value):
		var new_value := clampi(value, 0, 100)

		if hunger == new_value:
			return

		hunger = new_value
		data_changed.emit()


## 規格中的預設心情為 50。
@export_range(0, 100) var mood: int = 50:
	set(value):
		var new_value := clampi(value, 0, 100)

		if mood == new_value:
			return

		mood = new_value
		data_changed.emit()


@export_range(0, 100) var energy: int = 100:
	set(value):
		var new_value := clampi(value, 0, 100)

		if energy == new_value:
			return

		energy = new_value
		data_changed.emit()


@export var is_away: bool = false:
	set(value):
		if is_away == value:
			return

		is_away = value
		data_changed.emit()


func _init(
		initial_name: String = "",
		initial_hunger: int = 100,
		initial_mood: int = 50,
		initial_energy: int = 100,
		initial_is_away: bool = false
) -> void:
	rabbit_name = initial_name
	hunger = initial_hunger
	mood = initial_mood
	energy = initial_energy
	is_away = initial_is_away


## 轉換成可以寫入 JSON 的資料。
func to_dict() -> Dictionary:
	return {
		"rabbit_name": rabbit_name,
		"hunger": hunger,
		"mood": mood,
		"energy": energy,
		"is_away": is_away
	}


## 從存檔資料還原兔子。
static func from_dict(data: Dictionary) -> RabbitData:
	var loaded_name := str(
		data.get("rabbit_name", "")
	).strip_edges()

	if loaded_name.is_empty():
		push_error("RabbitData：存檔中的兔子名稱為空。")
		return null

	return RabbitData.new(
		loaded_name,
		int(data.get("hunger", 100)),
		int(data.get("mood", 50)),
		int(data.get("energy", 100)),
		bool(data.get("is_away", false))
	)