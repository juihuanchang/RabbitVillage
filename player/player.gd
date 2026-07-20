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
@onready var character_visual: CanvasItem = $ColorRect
@onready var character_sprite: CanvasItem = $Sprite2D

var rabbit_data: RabbitData
var activity_manager: ActivityManager
var _last_countdown_second: int = -1


func _ready() -> void:
	rabbit_data = RabbitData.new(
		rabbit_name,
		initial_hunger,
		initial_mood,
		initial_energy
	)

	activity_manager = ActivityManager.new()
	activity_manager.name = "ActivityManager"
	add_child(activity_manager)

	activity_manager.activity_started.connect(_on_activity_started)
	activity_manager.countdown_changed.connect(_on_countdown_changed)
	activity_manager.activity_completed.connect(_on_activity_completed)
	activity_manager.rabbit_returned.connect(_on_rabbit_returned)

	print_status()


func _physics_process(_delta: float) -> void:
	if rabbit_data.is_away:
		velocity = Vector2.ZERO
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F:
			start_forest_walk()


## Can also be called by a UI button.
func start_forest_walk() -> bool:
	if activity_manager.start_forest_walk(rabbit_data):
		return true

	print("無法開始森林散步：角色可能正在外出或體力不足。")
	return false


func get_rabbit_data() -> RabbitData:
	return rabbit_data


func _on_activity_started(active: ActiveActivityData) -> void:
	_last_countdown_second = -1
	character_visual.visible = false
	character_sprite.visible = false
	collision_shape.set_deferred("disabled", true)
	print(active.rabbit.rabbit_name, "開始", active.activity.activity_name)
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


func _on_rabbit_returned(returned_rabbit: RabbitData) -> void:
	character_visual.visible = true
	character_sprite.visible = true
	collision_shape.set_deferred("disabled", false)
	print(returned_rabbit.rabbit_name, "已回村")
	rabbit_status_changed.emit(returned_rabbit)


func print_status() -> void:
	print(
		"名字：", rabbit_data.rabbit_name,
		"｜飢餓：", rabbit_data.hunger,
		"｜心情：", rabbit_data.mood,
		"｜體力：", rabbit_data.energy,
		"｜外出：", rabbit_data.is_away
	)
