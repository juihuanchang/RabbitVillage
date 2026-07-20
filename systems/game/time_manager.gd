class_name TimeManager
extends Node


## Returns real-world Unix time in seconds (UTC).
static func get_now() -> float:
	return Time.get_unix_time_from_system()


static func is_completed(ends_at: float, now: float = -1.0) -> bool:
	var check_time := get_now() if now < 0.0 else now
	return check_time >= ends_at
