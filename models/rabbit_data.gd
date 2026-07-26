class_name RabbitData
extends Resource

signal data_changed

@export var rabbit_name: String = "Amy":
	set(value):
		rabbit_name = value.strip_edges()
		data_changed.emit()
@export_range(0, 100) var hunger: int = 100:
	set(value):
		hunger = clampi(value, 0, 100)
		data_changed.emit()
@export_range(0, 100) var mood: int = 50:
	set(value):
		mood = clampi(value, 0, 100)
		data_changed.emit()
@export_range(0, 100) var energy: int = 100:
	set(value):
		energy = clampi(value, 0, 100)
		data_changed.emit()
@export var is_away: bool = false:
	set(value):
		is_away = value
		data_changed.emit()
@export var current_activity: String = "":
	set(value):
		current_activity = value.strip_edges().to_lower()
		data_changed.emit()

func _init(
		initial_name: String = "Amy",
		initial_hunger: int = 100,
		initial_mood: int = 50,
		initial_energy: int = 100,
		initial_is_away: bool = false,
		initial_current_activity: String = ""
) -> void:
	rabbit_name = initial_name
	hunger = initial_hunger
	mood = initial_mood
	energy = initial_energy
	is_away = initial_is_away
	current_activity = initial_current_activity

func to_dict() -> Dictionary:
	return {
		"rabbit_name": rabbit_name,
		"hunger": hunger,
		"mood": mood,
		"energy": energy,
		"is_away": is_away,
		"current_activity": current_activity
	}

static func from_dict(data: Dictionary) -> RabbitData:
	var loaded_name := str(data.get("rabbit_name", "Amy")).strip_edges()
	if loaded_name.is_empty():
		loaded_name = "Amy"
	return RabbitData.new(
		loaded_name,
		int(data.get("hunger", 100)),
		int(data.get("mood", 50)),
		int(data.get("energy", 100)),
		bool(data.get("is_away", false)),
		str(data.get("current_activity", ""))
	)
