class_name RabbitManager
extends Node

signal rabbit_need_state_changed(hunger_state: String, energy_state: String, mood_state: String)

var _rabbits: Dictionary = {}
var _current_rabbit: RabbitData

func setup(rabbit: RabbitData) -> void:
	_current_rabbit = rabbit
	if rabbit != null and not rabbit.data_changed.is_connected(_on_rabbit_data_changed):
		rabbit.data_changed.connect(_on_rabbit_data_changed)
	_emit_need_state()

func add_rabbit(rabbit: RabbitData) -> bool:
	if rabbit == null or rabbit.rabbit_name.strip_edges().is_empty():
		return false
	var key := rabbit.rabbit_name.strip_edges().to_lower()
	if _rabbits.has(key):
		return false
	_rabbits[key] = rabbit
	return true

func get_rabbit(rabbit_name: String) -> RabbitData:
	return _rabbits.get(rabbit_name.strip_edges().to_lower()) as RabbitData

func get_all_rabbits() -> Array[RabbitData]:
	var result: Array[RabbitData] = []
	result.assign(_rabbits.values())
	return result

func clear_rabbits() -> void:
	_rabbits.clear()

func get_hunger_state() -> String:
	var value := _current_rabbit.hunger if _current_rabbit != null else 0
	if value < 20: return "critical"
	if value < 40: return "low"
	if value < 80: return "normal"
	return "full"

func get_energy_state() -> String:
	var value := _current_rabbit.energy if _current_rabbit != null else 0
	if value < 10: return "critical"
	if value < 30: return "low"
	if value < 70: return "normal"
	return "high"

func get_mood_state() -> String:
	var value := _current_rabbit.mood if _current_rabbit != null else 0
	if value < 20: return "critical"
	if value < 40: return "low"
	if value < 70: return "normal"
	return "happy"

func get_overall_need_state() -> String:
	var states := [get_hunger_state(), get_energy_state(), get_mood_state()]
	if states.has("critical"): return "critical"
	if states.has("low"): return "low"
	return "normal"

func _on_rabbit_data_changed() -> void: _emit_need_state()
func _emit_need_state() -> void:
	rabbit_need_state_changed.emit(get_hunger_state(), get_energy_state(), get_mood_state())
