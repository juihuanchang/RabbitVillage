class_name RabbitData
extends Resource

signal data_changed

@export var rabbit_name := "Amy": set = _set_name
@export_range(0, 100) var hunger := 100: set = _set_hunger
@export_range(0, 100) var mood := 50: set = _set_mood
@export_range(0, 100) var energy := 100: set = _set_energy
@export var is_away := false: set = _set_is_away
@export var current_activity := "": set = _set_current_activity
@export var current_state := "": set = _set_current_state
@export var forest_experience := 0: set = _set_forest_experience
@export var fishing_experience := 0: set = _set_fishing_experience
@export var intimacy := 0: set = _set_intimacy
@export var forest_activity_count := 0: set = _set_forest_activity_count
@export var fishing_activity_count := 0: set = _set_fishing_activity_count
@export var home_activity_count := 0: set = _set_home_activity_count
@export var total_activity_count := 0: set = _set_total_activity_count
@export var unlocked_growth_marks: Array[Dictionary] = []
@export var pending_growth_event: Dictionary = {}

func _init(initial_name := "Amy", initial_hunger := 100, initial_mood := 50,
	initial_energy := 100, initial_is_away := false, initial_current_activity := "") -> void:
	rabbit_name = initial_name
	hunger = initial_hunger
	mood = initial_mood
	energy = initial_energy
	is_away = initial_is_away
	current_activity = initial_current_activity

func _set_name(value: String) -> void: rabbit_name = value.strip_edges(); data_changed.emit()
func _set_hunger(value: int) -> void: hunger = clampi(value, 0, 100); data_changed.emit()
func _set_mood(value: int) -> void: mood = clampi(value, 0, 100); data_changed.emit()
func _set_energy(value: int) -> void: energy = clampi(value, 0, 100); data_changed.emit()
func _set_is_away(value: bool) -> void: is_away = value; data_changed.emit()
func _set_current_activity(value: String) -> void: current_activity = value.strip_edges().to_lower(); data_changed.emit()
func _set_current_state(value: String) -> void: current_state = value; data_changed.emit()
func _set_forest_experience(value: int) -> void: forest_experience = maxi(value, 0); data_changed.emit()
func _set_fishing_experience(value: int) -> void: fishing_experience = maxi(value, 0); data_changed.emit()
func _set_intimacy(value: int) -> void: intimacy = maxi(value, 0); data_changed.emit()
func _set_forest_activity_count(value: int) -> void: forest_activity_count = maxi(value, 0); data_changed.emit()
func _set_fishing_activity_count(value: int) -> void: fishing_activity_count = maxi(value, 0); data_changed.emit()
func _set_home_activity_count(value: int) -> void: home_activity_count = maxi(value, 0); data_changed.emit()
func _set_total_activity_count(value: int) -> void: total_activity_count = maxi(value, 0); data_changed.emit()

func to_dict() -> Dictionary:
	return {
		"rabbit_name": rabbit_name, "hunger": hunger, "mood": mood, "energy": energy,
		"is_away": is_away, "current_activity": current_activity, "current_state": current_state,
		"forest_experience": forest_experience, "fishing_experience": fishing_experience,
		"intimacy": intimacy, "forest_activity_count": forest_activity_count,
		"fishing_activity_count": fishing_activity_count, "home_activity_count": home_activity_count,
		"total_activity_count": total_activity_count,
		"unlocked_growth_marks": unlocked_growth_marks.duplicate(),
		"pending_growth_event": pending_growth_event.duplicate(true)
	}

static func from_dict(data: Dictionary) -> RabbitData:
	var loaded_name := str(data.get("rabbit_name", "Amy")).strip_edges()
	if loaded_name.is_empty(): loaded_name = "Amy"
	var result := RabbitData.new(loaded_name, int(data.get("hunger", 100)), int(data.get("mood", 50)),
		int(data.get("energy", 100)), bool(data.get("is_away", false)), str(data.get("current_activity", "")))
	result.current_state = str(data.get("current_state", ""))
	result.forest_experience = int(data.get("forest_experience", 0))
	result.fishing_experience = int(data.get("fishing_experience", 0))
	result.intimacy = int(data.get("intimacy", 0))
	result.forest_activity_count = int(data.get("forest_activity_count", 0))
	result.fishing_activity_count = int(data.get("fishing_activity_count", 0))
	result.home_activity_count = int(data.get("home_activity_count", 0))
	result.total_activity_count = int(data.get("total_activity_count", 0))
	for mark: Variant in data.get("unlocked_growth_marks", []):
		if mark is Dictionary:
			result.unlocked_growth_marks.append(mark.duplicate(true))
		else:
			# Migrates early week-three saves which stored only the mark id.
			result.unlocked_growth_marks.append({"id": str(mark), "is_unlocked": true, "unlocked_at": 0.0})
	if data.get("pending_growth_event", {}) is Dictionary: result.pending_growth_event = data.get("pending_growth_event", {}).duplicate(true)
	return result
