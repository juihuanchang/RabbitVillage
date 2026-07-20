extends Node2D

@onready var player: RabbitCharacter = $Background/Player
@onready var name_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/NameLabel
@onready var hunger_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/HungerLabel
@onready var mood_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/MoodLabel
@onready var energy_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/EnergyLabel
@onready var away_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/AwayLabel
@onready var activity_name_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/ActivityNameLabel
@onready var duration_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/DurationLabel
@onready var activity_energy_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/ActivityEnergyLabel
@onready var activity_mood_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/ActivityMoodLabel
@onready var countdown_label: Label = $CanvasLayer/UI/StatusPanel/Margin/VBox/CountdownLabel
@onready var start_button: Button = $CanvasLayer/UI/StatusPanel/Margin/VBox/StartButton


func _ready() -> void:
	player.rabbit_status_changed.connect(_update_rabbit_status)
	player.activity_manager.countdown_changed.connect(_on_countdown_changed)
	start_button.pressed.connect(_on_start_button_pressed)
	_update_rabbit_status(player.get_rabbit_data())
	_show_forest_walk_data()


func _update_rabbit_status(rabbit: RabbitData) -> void:
	name_label.text = "名字：%s" % rabbit.rabbit_name
	hunger_label.text = "飢餓：%d / 100" % rabbit.hunger
	mood_label.text = "心情：%d / 100" % rabbit.mood
	energy_label.text = "體力：%d / 100" % rabbit.energy
	away_label.text = "是否外出：%s" % ("是" if rabbit.is_away else "否")
	start_button.disabled = rabbit.is_away
	start_button.text = "森林散步進行中" if rabbit.is_away else "開始森林散步（F）"
	if not rabbit.is_away:
		countdown_label.text = "狀態：在村莊"


func _show_forest_walk_data() -> void:
	var forest_walk := ActivityData.create_forest_walk()
	activity_name_label.text = "活動：%s" % forest_walk.activity_name
	duration_label.text = "時間：%d 秒" % int(forest_walk.duration_seconds)
	activity_energy_label.text = "體力變化：%+d" % forest_walk.energy_change
	activity_mood_label.text = "心情變化：%+d" % forest_walk.mood_change


func _on_start_button_pressed() -> void:
	player.start_forest_walk()


func _on_countdown_changed(
		_active_activity: ActiveActivityData,
		remaining_seconds: float
) -> void:
	countdown_label.text = "剩餘時間：%d 秒" % ceili(remaining_seconds)
