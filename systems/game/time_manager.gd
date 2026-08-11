class_name TimeManager
extends Node


## Returns real-world Unix time in seconds (UTC).
static func get_now() -> float:
	return Time.get_unix_time_from_system()


## Converts Unix UTC time to the computer's local date and time.
static func get_local_datetime(unix_time: float = -1.0) -> Dictionary:
	var timestamp := get_now() if unix_time < 0.0 else unix_time
	var timezone := Time.get_time_zone_from_system()
	var local_timestamp := int(timestamp) + int(timezone.get("bias", 0)) * 60
	return Time.get_datetime_dict_from_unix_time(local_timestamp)


static func is_completed(ends_at: float, now: float = -1.0) -> bool:
	var check_time := get_now() if now < 0.0 else now
	return check_time >= ends_at
