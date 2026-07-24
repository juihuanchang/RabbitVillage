class_name RabbitCharacter
extends CharacterBody2D


signal rabbit_status_changed(rabbit: RabbitData)


@export_category("Rabbit")
@export var rabbit_name: String = "小麥"
@export_range(0, 100) var initial_hunger: int = 80
@export_range(0, 100) var initial_mood: int = 70
@export_range(0, 100) var initial_energy: int = 20

@export_category("Movement")
@export var speed: float = 300.0


@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var character_sprite: CanvasItem = $Sprite2D


var rabbit_data: RabbitData
var activity_manager: ActivityManager

var rabbit_manager: RabbitManager = RabbitManager.new()
var diary_manager: DiaryManager = DiaryManager.new()
var save_manager: SaveManager = SaveManager.new()

const HOME_TICK_SECONDS := 15.0
const HOME_ENERGY_GAIN := 5
const HOME_HUNGER_LOSS := 2
const HOME_MOOD_LOSS := 2

var _last_countdown_second: int = -1
var _home_tick_elapsed: float = 0.0


func _ready() -> void:
	# 先建立場景中的預設兔子資料。
	rabbit_data = RabbitData.new(
		rabbit_name,
		initial_hunger,
		initial_mood,
		initial_energy
	)

	# 建立活動管理器。
	activity_manager = ActivityManager.new()
	activity_manager.name = "ActivityManager"

	# 將各個管理器加入場景樹。
	rabbit_manager.name = "RabbitManager"
	diary_manager.name = "DiaryManager"
	save_manager.name = "SaveManager"

	add_child(activity_manager)
	add_child(rabbit_manager)
	add_child(diary_manager)
	add_child(save_manager)

	# 連接活動訊號。
	activity_manager.activity_started.connect(_on_activity_started)
	activity_manager.countdown_changed.connect(_on_countdown_changed)
	activity_manager.activity_completed.connect(_on_activity_completed)
	activity_manager.rabbit_returned.connect(_on_rabbit_returned)

	# 嘗試讀取舊存檔。
	var loaded := save_manager.load_game(
		rabbit_manager,
		diary_manager
	)

	if loaded:
		# 找出存檔中的同名兔子。
		var loaded_rabbit := rabbit_manager.get_rabbit(
			rabbit_data.rabbit_name
		)

		if loaded_rabbit != null:
			rabbit_data = loaded_rabbit
		else:
			# 舊存檔中沒有這隻兔子時，加入目前的預設資料。
			rabbit_manager.add_rabbit(rabbit_data)

		print("讀檔成功")
		print("目前日記數量：", diary_manager.get_journal_count())
	else:
		# 第一次執行，尚未建立存檔。
		rabbit_manager.add_rabbit(rabbit_data)
		print("沒有舊存檔，使用新的兔子資料")

	print_status()


func _process(delta: float) -> void:
	if rabbit_data == null or rabbit_data.is_away:
		_home_tick_elapsed = 0.0
		return
	_home_tick_elapsed += delta
	if _home_tick_elapsed >= HOME_TICK_SECONDS:
		_home_tick_elapsed -= HOME_TICK_SECONDS
		_apply_home_tick()


func _apply_home_tick() -> void:
	rabbit_data.energy += HOME_ENERGY_GAIN
	rabbit_data.hunger -= HOME_HUNGER_LOSS
	rabbit_data.mood -= HOME_MOOD_LOSS
	rabbit_status_changed.emit(rabbit_data)
	save_manager.save_game(rabbit_manager, diary_manager)
	print("居家狀態更新：體力 +5、飢餓 -2、心情 -2")


func _physics_process(_delta: float) -> void:
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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F:
			start_forest_walk()


## 也可以由 UI 按鈕呼叫。
func start_forest_walk() -> bool:
	if activity_manager.start_forest_walk(rabbit_data):
		return true

	print("無法開始森林散步：角色可能正在外出或體力不足。")
	return false


func get_rabbit_data() -> RabbitData:
	return rabbit_data


func _on_activity_started(active: ActiveActivityData) -> void:
	_last_countdown_second = -1

	character_sprite.visible = false
	collision_shape.set_deferred("disabled", true)

	print(
		active.rabbit.rabbit_name,
		"開始",
		active.activity.activity_name
	)

	rabbit_status_changed.emit(rabbit_data)


func _on_countdown_changed(
		_active: ActiveActivityData,
		remaining_seconds: float
) -> void:
	var displayed_second := ceili(remaining_seconds)

	if displayed_second == _last_countdown_second:
		return

	_last_countdown_second = displayed_second
	print("森林散步剩餘：", displayed_second, " 秒")


func _on_activity_completed(active: ActiveActivityData) -> void:
	print(active.activity.activity_name, "完成")

	print_status()
	rabbit_status_changed.emit(rabbit_data)

	# 根據完成的活動產生日記。
	var entry := JournalGenerator.generate(active)

	if entry == null:
		push_error("日記產生失敗")
		return

	# 將日記加入 DiaryManager。
	var added := diary_manager.add_journal(entry)

	if not added:
		push_error("日記新增失敗")
		return

	print("新增日記成功")
	print(entry.content)


func _on_rabbit_returned(returned_rabbit: RabbitData) -> void:
	character_sprite.visible = true
	collision_shape.set_deferred("disabled", false)

	print(returned_rabbit.rabbit_name, "已回村")
	rabbit_status_changed.emit(returned_rabbit)

	# 日記新增完、兔子回家後，將資料寫入存檔。
	var success := save_manager.save_game(
		rabbit_manager,
		diary_manager
	)

	if success:
		print("兔子回家，遊戲已存檔")
	else:
		push_error("遊戲存檔失敗")


func print_status() -> void:
	print(
		"名字：", rabbit_data.rabbit_name,
		"｜飢餓：", rabbit_data.hunger,
		"｜心情：", rabbit_data.mood,
		"｜體力：", rabbit_data.energy,
		"｜外出：", rabbit_data.is_away
	)