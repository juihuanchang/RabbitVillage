class_name ActivityManager
extends Node


signal activity_started(active_activity: ActiveActivityData)
signal countdown_changed(
	active_activity: ActiveActivityData,
	remaining_seconds: float
)
signal activity_completed(active_activity: ActiveActivityData)
signal rabbit_returned(rabbit: RabbitData)


var active_activity: ActiveActivityData = null


func start_activity(
		rabbit: RabbitData,
		activity: ActivityData
) -> bool:
	if rabbit == null or activity == null:
		push_error("ActivityManager：兔子或活動資料不存在。")
		return false

	if activity.activity_id.is_empty():
		push_error("ActivityManager：activity_id 不可為空。")
		return false

	if active_activity != null or rabbit.is_away:
		return false

	var required_energy := maxi(
		0,
		-activity.energy_change
	)

	if rabbit.energy < required_energy:
		return false

	rabbit.is_away = true

	var now := TimeManager.get_now()

	# ActiveActivityData 會在這裡自動建立
	# 唯一的 activity_record_id。
	active_activity = ActiveActivityData.new(
		rabbit,
		activity,
		now
	)

	activity_started.emit(active_activity)

	countdown_changed.emit(
		active_activity,
		active_activity.get_remaining_seconds(now)
	)

	return true


## 開始森林散步。
func start_forest_walk(rabbit: RabbitData) -> bool:
	return start_activity(
		rabbit,
		ActivityData.create_forest_walk()
	)


## 提供之後的釣魚活動使用。
func start_fishing(rabbit: RabbitData) -> bool:
	return start_activity(
		rabbit,
		ActivityData.create_fishing()
	)


func _process(_delta: float) -> void:
	if active_activity == null:
		return

	# 已完成的活動不可再次完成。
	if active_activity.is_completed:
		return

	var now := TimeManager.get_now()

	countdown_changed.emit(
		active_activity,
		active_activity.get_remaining_seconds(now)
	)

	if TimeManager.is_completed(
		active_activity.ends_at,
		now
	):
		_complete_activity()


## 讀檔後，或遊戲重新取得焦點時呼叫。
## 如果關閉遊戲期間活動已到期，會立刻完成活動。
func check_for_completion() -> bool:
	if active_activity == null:
		return false

	if active_activity.is_completed:
		return false

	if not TimeManager.is_completed(
		active_activity.ends_at
	):
		return false

	_complete_activity()
	return true


func _complete_activity() -> void:
	if active_activity == null:
		return

	if active_activity.is_completed:
		return

	var completed := active_activity
	var rabbit := completed.rabbit
	var activity := completed.activity

	if rabbit == null or activity == null:
		push_error("ActivityManager：完成活動時缺少兔子或活動資料。")
		active_activity = null
		return

	# 必須先標記完成，避免同一筆活動被重複處理。
	completed.mark_completed()

	# 套用活動完成後的數值變化。
	rabbit.energy += activity.energy_change
	rabbit.hunger += activity.hunger_change
	rabbit.mood += activity.mood_change

	# 此時 active_activity 尚未清除，
	# 存檔系統可以保存「活動已完成」的狀態；
	# 日記系統也可取得 activity_record_id。
	activity_completed.emit(completed)

	# 活動處理完畢，讓兔子回家。
	rabbit.is_away = false
	active_activity = null

	rabbit_returned.emit(rabbit)