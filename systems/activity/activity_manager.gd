class_name ActivityManager
extends Node

signal activity_started(active_activity: ActiveActivityData)
signal countdown_changed(active_activity: ActiveActivityData, remaining_seconds: float)
signal activity_completed(active_activity: ActiveActivityData)
signal rabbit_returned(rabbit: RabbitData)

var active_activity: ActiveActivityData


func start_activity(rabbit: RabbitData, activity: ActivityData) -> bool:
	if rabbit == null or activity == null:
		return false
	if active_activity != null or rabbit.is_away:
		return false

	var required_energy := maxi(0, -activity.energy_change)
	if rabbit.energy < required_energy:
		return false

	rabbit.is_away = true
	active_activity = ActiveActivityData.new(rabbit, activity, TimeManager.get_now())
	activity_started.emit(active_activity)
	countdown_changed.emit(active_activity, active_activity.get_remaining_seconds(TimeManager.get_now()))
	return true


func start_forest_walk(rabbit: RabbitData) -> bool:
	return start_activity(rabbit, ActivityData.create_forest_walk())


func _process(_delta: float) -> void:
	if active_activity == null:
		return

	var now := TimeManager.get_now()
	countdown_changed.emit(active_activity, active_activity.get_remaining_seconds(now))
	if TimeManager.is_completed(active_activity.ends_at, now):
		_complete_activity()


## Call after loading save data or when the game regains focus.
func check_for_completion() -> bool:
	if active_activity == null or not TimeManager.is_completed(active_activity.ends_at):
		return false

	_complete_activity()
	return true


func _complete_activity() -> void:
	var completed := active_activity
	var rabbit := completed.rabbit
	rabbit.energy += completed.activity.energy_change
	rabbit.hunger += completed.activity.hunger_change
	rabbit.mood += completed.activity.mood_change
	activity_completed.emit(completed)

	rabbit.is_away = false
	active_activity = null
	rabbit_returned.emit(rabbit)
