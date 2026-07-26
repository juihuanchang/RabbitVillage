extends Node2D

@onready var player: RabbitCharacter = $Background/Player
@onready var ui: Control = $CanvasLayer/AUI
@onready var panel: PanelContainer = $CanvasLayer/AUI/MainHUD
@onready var name_label: Label = $CanvasLayer/AUI/MainHUD/Margin/Layout/Name
@onready var state_label: Label = $CanvasLayer/AUI/MainHUD/Margin/Layout/State
@onready var hunger_bar: ProgressBar = $CanvasLayer/AUI/MainHUD/Margin/Layout/Stats/HungerBar
@onready var mood_bar: ProgressBar = $CanvasLayer/AUI/MainHUD/Margin/Layout/Stats/MoodBar
@onready var energy_bar: ProgressBar = $CanvasLayer/AUI/MainHUD/Margin/Layout/Stats/EnergyBar
@onready var hunger_value: Label = $CanvasLayer/AUI/MainHUD/Margin/Layout/Stats/HungerValue
@onready var mood_value: Label = $CanvasLayer/AUI/MainHUD/Margin/Layout/Stats/MoodValue
@onready var energy_value: Label = $CanvasLayer/AUI/MainHUD/Margin/Layout/Stats/EnergyValue
@onready var forest_button: Button = $CanvasLayer/AUI/MainHUD/Margin/Layout/ForestButton
@onready var fishing_button: Button = $CanvasLayer/AUI/MainHUD/Margin/Layout/FishingButton
@onready var diary_button: Button = $CanvasLayer/AUI/DiaryButton
@onready var popup: Control = $CanvasLayer/AUI/ActivityPopup
@onready var popup_card: PanelContainer = $CanvasLayer/AUI/ActivityPopup/Card
@onready var popup_message: Label = $CanvasLayer/AUI/ActivityPopup/Card/Margin/Layout/Message
@onready var start_button: Button = $CanvasLayer/AUI/ActivityPopup/Card/Margin/Layout/Buttons/Start
@onready var cancel_button: Button = $CanvasLayer/AUI/ActivityPopup/Card/Margin/Layout/Buttons/Cancel
@onready var activity_status: PanelContainer = $CanvasLayer/AUI/ActivityStatus
@onready var remaining_label: Label = $CanvasLayer/AUI/ActivityStatus/Margin/Layout/Remaining
@onready var finish_label: Label = $CanvasLayer/AUI/ActivityStatus/Margin/Layout/Finish
@onready var diary_window: Control = $CanvasLayer/AUI/DiaryWindow
@onready var diary_card: PanelContainer = $CanvasLayer/AUI/DiaryWindow/Card
@onready var diary_list: VBoxContainer = $CanvasLayer/AUI/DiaryWindow/Card/Margin/Layout/Scroll/Entries
@onready var close_diary: Button = $CanvasLayer/AUI/DiaryWindow/Card/Margin/Layout/Header/Close
@onready var toast: Label = $CanvasLayer/AUI/Toast

var _toast_tween: Tween


func _ready() -> void:
	_style_interface()
	forest_button.pressed.connect(_open_forest_popup)
	fishing_button.pressed.connect(func() -> void: _show_toast("池邊釣魚即將開放 ✦"))
	diary_button.pressed.connect(_open_diary)
	start_button.pressed.connect(_start_forest)
	cancel_button.pressed.connect(func() -> void: popup.hide())
	close_diary.pressed.connect(func() -> void: diary_window.hide())
	player.rabbit_status_changed.connect(_update_rabbit_status)
	player.activity_manager.countdown_changed.connect(_on_countdown_changed)
	player.activity_manager.activity_started.connect(_on_activity_started)
	player.activity_manager.rabbit_returned.connect(_on_rabbit_returned)
	player.diary_manager.journals_changed.connect(_refresh_diary)
	_update_rabbit_status(player.get_rabbit_data())
	_refresh_diary()
	if player.activity_manager.active_activity != null:
		_on_activity_started(player.activity_manager.active_activity)


func _style_interface() -> void:
	panel.add_theme_stylebox_override("panel", _card(Color("#fff7df"), Color("#c9ae78"), 28, 12))
	popup_card.add_theme_stylebox_override("panel", _card(Color("#fffaf0"), Color("#b89559"), 28, 18))
	diary_card.add_theme_stylebox_override("panel", _card(Color("#fffaf0"), Color("#b89559"), 28, 18))
	activity_status.add_theme_stylebox_override("panel", _card(Color("#294b31e8"), Color("#88ac75"), 18, 8))
	for button in [forest_button, start_button]:
		button.add_theme_stylebox_override("normal", _button_style(Color("#507e55")))
		button.add_theme_stylebox_override("hover", _button_style(Color("#659a68")))
		button.add_theme_color_override("font_color", Color.WHITE)
	for bar in [hunger_bar, mood_bar, energy_bar]:
		bar.add_theme_stylebox_override("background", _bar_style(Color("#e7ddc4")))
	hunger_bar.add_theme_stylebox_override("fill", _bar_style(Color("#e49b4b")))
	mood_bar.add_theme_stylebox_override("fill", _bar_style(Color("#df7784")))
	energy_bar.add_theme_stylebox_override("fill", _bar_style(Color("#66a975")))
	for label in [hunger_value, mood_value, energy_value]:
		label.add_theme_color_override("font_color", Color("#4f473b"))


func _card(color: Color, border: Color, radius: int, shadow: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0.08, 0.13, 0.08, 0.28)
	box.shadow_size = shadow
	return box


func _button_style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(14)
	box.content_margin_top = 13
	box.content_margin_bottom = 13
	return box


func _bar_style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(7)
	return box


func _update_rabbit_status(rabbit: RabbitData) -> void:
	name_label.text = rabbit.rabbit_name
	state_label.text = "●  森林散步中" if rabbit.is_away else "●  在家休息"
	state_label.modulate = Color("#df9152") if rabbit.is_away else Color("#568c60")
	_set_stat(hunger_bar, hunger_value, rabbit.hunger)
	_set_stat(mood_bar, mood_value, rabbit.mood)
	_set_stat(energy_bar, energy_value, rabbit.energy)
	forest_button.disabled = rabbit.is_away
	forest_button.text = "Amy 外出中…" if rabbit.is_away else "森林散步"
	player.visible = not rabbit.is_away
	activity_status.visible = player.activity_manager.active_activity != null


func _set_stat(bar: ProgressBar, label: Label, value: int) -> void:
	bar.value = value
	label.text = "%d / 100" % value


func _open_forest_popup() -> void:
	if player.get_rabbit_data().is_away:
		_show_toast("Amy 正在外出中")
		return
	popup_message.text = ""
	start_button.disabled = false
	popup.show()


func _start_forest() -> void:
	var rabbit := player.get_rabbit_data()
	if rabbit.energy < 5:
		popup_message.text = "體力不足，先讓 Amy 休息一下吧！"
		start_button.disabled = true
		return
	if not player.start_forest_walk():
		popup_message.text = "Amy 正在外出中，不能開始新的活動。"
		return
	popup.hide()
	_show_toast("Amy 帶著小背包出發了！")


func _on_activity_started(active: ActiveActivityData) -> void:
	activity_status.show()
	_update_rabbit_status(player.get_rabbit_data())
	_on_countdown_changed(active, active.get_remaining_seconds(TimeManager.get_now()))


func _on_countdown_changed(active: ActiveActivityData, remaining: float) -> void:
	remaining_label.text = "剩餘  %02d 秒" % ceili(remaining)
	var finish := Time.get_datetime_dict_from_unix_time(int(active.ends_at))
	finish_label.text = "預計完成  %02d:%02d:%02d" % [finish.hour, finish.minute, finish.second]


func _on_rabbit_returned(rabbit: RabbitData) -> void:
	activity_status.hide()
	_update_rabbit_status(rabbit)
	_refresh_diary()
	_show_toast("Amy 回來了！新的故事已收進日記 ✦")


func _open_diary() -> void:
	_refresh_diary()
	diary_window.show()


func _refresh_diary() -> void:
	for child in diary_list.get_children():
		child.queue_free()
	var journals := player.diary_manager.get_all_journals()
	if journals.is_empty():
		var empty := Label.new()
		empty.text = "\n目前還沒有日記，\n帶 Amy 出門看看吧！"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 22)
		empty.add_theme_color_override("font_color", Color("#8f806d"))
		diary_list.add_child(empty)
		return
	for entry: JournalEntry in journals:
		diary_list.add_child(_make_diary_entry(entry))


func _make_diary_entry(entry: JournalEntry) -> Control:
	var entry_panel := PanelContainer.new()

	entry_panel.add_theme_stylebox_override(
		"panel",
		_card(
			Color("#fffdf7"),
			Color("#ead9bd"),
			16,
			0
		)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	entry_panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	# 日期與時間
	var date_label := Label.new()

	var datetime := Time.get_datetime_dict_from_unix_time(
		int(entry.created_at)
	)

	date_label.text = "%s　%02d:%02d" % [
		entry.date,
		int(datetime.get("hour", 0)),
		int(datetime.get("minute", 0))
	]

	date_label.add_theme_color_override(
		"font_color",
		Color("#9a8b75")
	)

	box.add_child(date_label)

	# 日記標題
	var title_label := Label.new()
	title_label.text = entry.title

	title_label.add_theme_font_size_override(
		"font_size",
		24
	)

	title_label.add_theme_color_override(
		"font_color",
		Color("#48634a")
	)

	box.add_child(title_label)

	# 日記內容
	var content_label := Label.new()
	content_label.text = entry.content

	content_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	content_label.add_theme_font_size_override(
		"font_size",
		18
	)

	content_label.add_theme_color_override(
		"font_color",
		Color("#594f43")
	)

	box.add_child(content_label)

	return entry_panel


func _show_toast(message: String) -> void:
	toast.text = message
	toast.modulate.a = 1.0
	toast.show()
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.35)
	_toast_tween.tween_callback(toast.hide)
