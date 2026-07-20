class_name RabbitManager
extends Node

var _rabbits: Dictionary[String, RabbitData] = {}


func add_rabbit(rabbit: RabbitData) -> bool:
	if rabbit == null or rabbit.rabbit_name.is_empty():
		return false

	var key := rabbit.rabbit_name.to_lower()
	if _rabbits.has(key):
		return false

	_rabbits[key] = rabbit
	return true


func get_rabbit(rabbit_name: String) -> RabbitData:
	return _rabbits.get(rabbit_name.to_lower()) as RabbitData


func get_all_rabbits() -> Array[RabbitData]:
	var result: Array[RabbitData] = []
	result.assign(_rabbits.values())
	return result


func remove_rabbit(rabbit_name: String) -> bool:
	return _rabbits.erase(rabbit_name.to_lower())
