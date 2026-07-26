class_name RabbitCharacter
extends CharacterBody2D


signal rabbit_status_changed(rabbit: RabbitData)


@export_category("Rabbit")
@export var rabbit_name: String = "Amy"
@export_range(0, 100) var initial_hunger: int = 100
@export_range(0, 100) var initial_mood: int = 50
@export_range(0, 100) var initial_energy: int = 100

@export_category("Movement")
@export var speed: float = 300.0


@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var character_sprite: CanvasItem = $Sprite2D


var rabbit_data: RabbitData
var activity_manager: ActivityManager

var rabbit_manager: RabbitManager = RabbitManager.new()
var diary_manager: DiaryManager = DiaryManager.new()
var save_manager: SaveManager = SaveManager.new()


const HOME_TICK_SECONDS: float = 15.0
const HOME_ENERGY_GAIN: int = 5
const HOME_HUNGER_LOSS: int = 2
const HOME_MOOD_LOSS: int = 2


var _last_countdown_second: int = -1
var _home_tick_elapsed: float = 0.0

## 避免同一幀因為多個數值變化而連續寫入多次存檔。
var _save_requested: bool = false


func _ready() -> void:
	# 關閉視窗時由本腳本先存檔，再結束遊戲。
	get_tree().auto_accept_quit = false

	# 第一次進入時使用的預設資料。
	var default_rabbit := RabbitData.new(
		rabbit_name,
		initial_hunger,
		initial_mood,
		initial_energy,
		false
	)

	# 建立活動管理器。
	activity_manager = ActivityManager.new()

	activity_manager.name = "ActivityManager"
	rabbit_manager.name = "RabbitManager"
	diary_manager.name = "DiaryManager"
	save_manager.name = "SaveManager"

	# 將所有管理器加入場景樹。
	add_child(activity_manager)
	add_child(rabbit_manager)
	add_child(diary_manager)
	add_child(save_manager)

	# 連接活動訊號。
	activity_manager.activity_started.connect(
		_on_activity_started
	)

	activity_manager.countdown_changed.connect(
		_on_countdown_changed
	)

	activity_manager.activity_completed.connect(
		_on_activity_completed
	)

	activity_manager.rabbit_returned.connect(
		_on_rabbit_returned
	)

	# 將管理器交給 SaveManager。
	save_manager.setup(
		rabbit_manager,
		diary_manager,
		activity_manager
	)

	# 有存檔時讀取；沒有或損壞時建立預設存檔。
	rabbit_data = save_manager.load_or_create(
		default_rabbit
	)

	if rabbit_data == null:
		push_error("RabbitCharacter：兔子資料建立失敗。")
		return

	# 兔子數值改變時要求存檔。
	rabbit_data.data_changed.connect(
		_on_rabbit_data_changed
	)

	# 新增日記時要求存檔。
	diary_manager.journal_added.connect(
		_on_journal_added
	)

	_update_character_visibility()

	# 讀檔後檢查：
	# 若玩家關閉遊戲期間活動已經結束，
	# 會立即完成活動並產生日記。
	activity_manager.check_for_completion()

	print_status()

	print(
		"目前日記數量：",
		diary_manager.get_journal_count()
	)


func _process(delta: float) -> void:
	if rabbit_data == null:
		return

	# 外出時不執行居家數值變化。
	if rabbit_data.is_away:
		_home_tick_elapsed = 0.0
		return

	_home_tick_elapsed += delta

	if _home_tick_elapsed >= HOME_TICK_SECONDS:
		_home_tick_elapsed -= HOME_TICK_SECONDS
		_apply_home_tick()


## 每 15 秒更新一次居家狀態。
func _apply_home_tick() -> void:
	if rabbit_data == null:
		return

	rabbit_data.energy += HOME_ENERGY_GAIN
	rabbit_data.hunger -= HOME_HUNGER_LOSS
	rabbit_data.mood -= HOME_MOOD_LOSS

	rabbit_status_changed.emit(rabbit_data)

	print(
		"居家狀態更新：體力 +",
		HOME_ENERGY_GAIN,
		"、飢餓 -",
		HOME_HUNGER_LOSS,
		"、心情 -",
		HOME_MOOD_LOSS
	)

	# RabbitData 的 data_changed 會自動要求存檔，
	# 不需要在這裡再傳入管理器。
	_request_save()


func _physics_process(_delta: float) -> void:
	if rabbit_data == null:
		return

	# 兔子外出時不能移動。
	if rabbit_data.is_away:
		velocity = Vector2.ZERO
		return

	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	velocity = direction * speed
	move_and_slide()


func _unhandled_key_input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		if event.physical_keycode == KEY_F:
			start_forest_walk()


## 也可以由 UI 按鈕呼叫。
func start_forest_walk() -> bool:
	if rabbit_data == null:
		return false

	if activity_manager.start_forest_walk(
		rabbit_data
	):
		return true

	print(
		"無法開始森林散步：",
		"角色可能正在外出或體力不足。"
	)

	return false


## 預留給之後的釣魚按鈕或 B 呼叫。
func start_fishing() -> bool:
	if rabbit_data == null:
		return false

	if activity_manager.start_fishing(
		rabbit_data
	):
		return true

	print(
		"無法開始釣魚：",
		"角色可能正在外出或體力不足。"
	)

	return false


func get_rabbit_data() -> RabbitData:
	return rabbit_data


## 提供給 A：取得完整日記清單。
## 沒有日記時會回傳空陣列。
func get_all_journals() -> Array[JournalEntry]:
	return diary_manager.get_all_journals()


## 提供給 A：取得最新日記。
## 沒有日記時回傳 null。
func get_latest_journal() -> JournalEntry:
	return diary_manager.get_latest_journal()


## 提供給 A：取得目前日記數量。
func get_journal_count() -> int:
	return diary_manager.get_journal_count()


## 提供給 B 或其他系統主動存檔。
func save_now() -> bool:
	return save_manager.save_game()


func _on_activity_started(
		active: ActiveActivityData
) -> void:
	_last_countdown_second = -1
	_home_tick_elapsed = 0.0

	character_sprite.visible = false

	collision_shape.set_deferred(
		"disabled",
		true
	)

	print(
		active.rabbit.rabbit_name,
		"開始",
		active.activity.activity_name
	)

	print(
		"活動紀錄編號：",
		active.activity_record_id
	)

	rabbit_status_changed.emit(rabbit_data)

	# 規格要求：活動開始時存檔。
	if not save_manager.save_game():
		push_error("RabbitCharacter：活動開始存檔失敗。")


func _on_countdown_changed(
		active: ActiveActivityData,
		remaining_seconds: float
) -> void:
	var displayed_second := ceili(
		remaining_seconds
	)

	if displayed_second == _last_countdown_second:
		return

	_last_countdown_second = displayed_second

	print(
		active.activity.activity_name,
		"剩餘：",
		displayed_second,
		" 秒"
	)


func _on_activity_completed(
		active: ActiveActivityData
) -> void:
	print(
		active.activity.activity_name,
		"完成"
	)

	print(
		"活動紀錄編號：",
		active.activity_record_id
	)

	# DiaryManager 會：
	# 1. 檢查 activity_record_id 是否重複
	# 2. 建立 journal_id
	# 3. 隨機抽取對應活動模板
	# 4. 建立正式日記
	# 5. 排序並加入日記清單
	var entry := (
		diary_manager.create_journal_from_activity(
			active
		)
	)

	if entry != null:
		print("新增日記成功")
		print("日記編號：", entry.journal_id)
		print("日期：", entry.date)
		print("活動編號：", entry.activity_id)
		print("標題：", entry.title)
		print("內容：", entry.content)
	else:
		print(
			"本次沒有新增日記，",
			"可能是活動紀錄已經產生日記。"
		)

	rabbit_status_changed.emit(rabbit_data)
	print_status()

	# 即使日記建立失敗，也要保存活動完成狀態。
	if not save_manager.save_game():
		push_error("RabbitCharacter：活動完成存檔失敗。")


func _on_rabbit_returned(
		returned_rabbit: RabbitData
) -> void:
	character_sprite.visible = true

	collision_shape.set_deferred(
		"disabled",
		false
	)

	print(
		returned_rabbit.rabbit_name,
		"已回村"
	)

	rabbit_status_changed.emit(
		returned_rabbit
	)

	# 此時 ActivityManager 已清除 active_activity，
	# 再次保存「兔子已回家、沒有目前活動」的最終狀態。
	if save_manager.save_game():
		print("兔子回家，遊戲已存檔")
	else:
		push_error("RabbitCharacter：兔子回家存檔失敗。")


## RabbitData 的名稱、飢餓、心情、體力或外出狀態改變。
func _on_rabbit_data_changed() -> void:
	_request_save()


## DiaryManager 新增一篇日記。
func _on_journal_added(
	_entry: JournalEntry
) -> void:
	_request_save()


## 將同一幀內多次存檔要求合併成一次。
func _request_save() -> void:
	if _save_requested:
		return

	_save_requested = true
	call_deferred("_flush_requested_save")


func _flush_requested_save() -> void:
	_save_requested = false

	if not save_manager.save_game():
		push_error("RabbitCharacter：自動存檔失敗。")


func _update_character_visibility() -> void:
	if rabbit_data == null:
		return

	var is_home := not rabbit_data.is_away

	character_sprite.visible = is_home

	collision_shape.set_deferred(
		"disabled",
		not is_home
	)


## 桌面關閉視窗或行動裝置暫停時存檔。
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		if is_instance_valid(save_manager):
			save_manager.save_game()

	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(save_manager):
			save_manager.save_game()

		get_tree().quit()


func print_status() -> void:
	if rabbit_data == null:
		return

	print(
		"名字：", rabbit_data.rabbit_name,
		"｜飢餓：", rabbit_data.hunger,
		"｜心情：", rabbit_data.mood,
		"｜體力：", rabbit_data.energy,
		"｜外出：", rabbit_data.is_away
	)