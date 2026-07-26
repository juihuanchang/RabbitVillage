class_name RabbitManager
extends Node


var _rabbits: Dictionary[String, RabbitData] = {}


func add_rabbit(rabbit: RabbitData) -> bool:
	if rabbit == null:
		push_error("RabbitManager：RabbitData 不可為 null。")
		return false

	var cleaned_name := rabbit.rabbit_name.strip_edges()

	if cleaned_name.is_empty():
		push_error("RabbitManager：兔子名稱不可為空。")
		return false

	var key := cleaned_name.to_lower()

	if _rabbits.has(key):
		push_warning("RabbitManager：兔子已存在：" + cleaned_name)
		return false

	rabbit.rabbit_name = cleaned_name
	_rabbits[key] = rabbit
	return true


func get_rabbit(rabbit_name: String) -> RabbitData:
	var key := rabbit_name.strip_edges().to_lower()
	return _rabbits.get(key) as RabbitData


func has_rabbit(rabbit_name: String) -> bool:
	var key := rabbit_name.strip_edges().to_lower()
	return _rabbits.has(key)


func get_all_rabbits() -> Array[RabbitData]:
	var result: Array[RabbitData] = []
	result.assign(_rabbits.values())
	return result


func get_rabbit_count() -> int:
	return _rabbits.size()


func remove_rabbit(rabbit_name: String) -> bool:
	var key := rabbit_name.strip_edges().to_lower()
	return _rabbits.erase(key)


## 讀檔前清空目前資料，避免重複加入。
func clear_rabbits() -> void:
	_rabbits.clear()