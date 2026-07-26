class_name RabbitManager
extends Node

var _rabbits: Dictionary = {}

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

func has_rabbit(rabbit_name: String) -> bool:
	return _rabbits.has(rabbit_name.strip_edges().to_lower())

func get_all_rabbits() -> Array[RabbitData]:
	var result: Array[RabbitData] = []
	result.assign(_rabbits.values())
	return result

func get_rabbit_count() -> int:
	return _rabbits.size()

func remove_rabbit(rabbit_name: String) -> bool:
	return _rabbits.erase(rabbit_name.strip_edges().to_lower())

func clear_rabbits() -> void:
	_rabbits.clear()
