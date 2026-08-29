class_name CafeView
extends Control

signal back_requested
signal activity_requested(activity_id: String)

const ACTIVITY_DATA := {
	"cafe_hot_drink": {"name": "喝熱飲", "description": "Amy 在窗邊慢慢喝一杯熱飲。", "duration": 30, "need": "不消耗體力", "result": "心情 +8　飢餓 +3"},
	"cafe_help_serve": {"name": "幫忙端飲料", "description": "Amy 幫咖啡師把飲料送到客人桌邊。", "duration": 30, "need": "體力至少 5", "result": "體力 -4　心情 +3　金幣 +6"},
	"cafe_relax": {"name": "安靜坐一下", "description": "找個安靜角落，聽著杯盤輕響休息片刻。", "duration": 30, "need": "無", "result": "心情 +6　體力 +3"}
}

var activity_buttons: Dictionary = {}
var detail_title: Label
var detail_body: Label
var start_button: Button
var selected_activity_id := "cafe_hot_drink"
var experience_hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	_select_activity(selected_activity_id)


func set_activity_enabled(enabled: bool) -> void:
	for button: Button in activity_buttons.values():
		button.disabled = not enabled
	start_button.disabled = not enabled


func set_experience_hint(text: String) -> void:
	if experience_hint != null:
		experience_hint.text = text


func _build_interface() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#dfe8c7")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var glow := ColorRect.new()
	glow.position = Vector2(0, 650)
	glow.size = Vector2(1920, 430)
	glow.color = Color("#b9c99a")
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var header := PanelContainer.new()
	header.position = Vector2(70, 45)
	header.size = Vector2(1780, 110)
	header.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff8e9ed"), Color("#9a754d"), 24, 2, 10))
	add_child(header)
	var header_box := HBoxContainer.new()
	header_box.add_theme_constant_override("separation", 18)
	header.add_child(header_box)
	var heading := _label("村莊咖啡廳", 36, Color("#563d2b"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(heading)
	header_box.add_child(_label("Amy 的新生活場所", 20, Color("#76624c")))
	var back := _button("返回村莊")
	back.custom_minimum_size = Vector2(180, 58)
	back.pressed.connect(func() -> void: back_requested.emit())
	header_box.add_child(back)

	var left := PanelContainer.new()
	left.position = Vector2(90, 190)
	left.size = Vector2(540, 790)
	left.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fffaf0f2"), Color("#b48b5b"), 24, 2, 10))
	add_child(left)
	var left_margin := _margin(left, 30)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 16)
	left_margin.add_child(left_box)
	left_box.add_child(_label("今天想做什麼？", 30, Color("#59402c")))
	var intro := _label("選擇一項咖啡廳活動。活動時間沿用真實時間與離線完成規則。", 18, Color("#6b5a48"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_box.add_child(intro)
	for activity_id: String in ACTIVITY_DATA:
		var button := _button(str(ACTIVITY_DATA[activity_id].name))
		button.custom_minimum_size = Vector2(0, 76)
		button.pressed.connect(_select_activity.bind(activity_id))
		left_box.add_child(button)
		activity_buttons[activity_id] = button
	experience_hint = _label("Amy 還在熟悉這間咖啡廳。", 19, Color("#496249"))
	experience_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	experience_hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_child(experience_hint)

	var right := PanelContainer.new()
	right.position = Vector2(680, 190)
	right.size = Vector2(1150, 790)
	right.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fffdf7f4"), Color("#b48b5b"), 24, 2, 10))
	add_child(right)
	var right_margin := _margin(right, 38)
	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 20)
	right_margin.add_child(right_box)
	right_box.add_child(_label("窗邊的午後", 25, Color("#8a6744")))
	detail_title = _label("", 38, Color("#503a2b"))
	right_box.add_child(detail_title)
	detail_body = _label("", 22, Color("#554b40"))
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_child(detail_body)
	start_button = _button("開始活動")
	start_button.custom_minimum_size = Vector2(0, 70)
	start_button.pressed.connect(func() -> void: activity_requested.emit(selected_activity_id))
	right_box.add_child(start_button)


func _select_activity(activity_id: String) -> void:
	selected_activity_id = activity_id
	var data: Dictionary = ACTIVITY_DATA.get(activity_id, {})
	detail_title.text = str(data.get("name", "咖啡廳活動"))
	detail_body.text = "%s\n\n時間　%d 秒\n需求　%s\n\n可能結果\n%s\n\n活動完成後會顯示結果，第一次體驗也會提示新的日記。" % [str(data.get("description", "")), int(data.get("duration", 30)), str(data.get("need", "無")), str(data.get("result", ""))]
	for id: String in activity_buttons:
		var button := activity_buttons[id] as Button
		button.modulate = Color.WHITE if id == activity_id else Color("#ddd4c5")
	start_button.text = "開始「%s」" % str(data.get("name", "活動"))


func _margin(parent: Control, amount: int) -> MarginContainer:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, amount)
	parent.add_child(margin)
	return margin


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_stylebox_override("normal", UIStyleFactory.button(Color("#6f8c59"), 14, 13))
	button.add_theme_stylebox_override("hover", UIStyleFactory.button(Color("#819e68"), 14, 13))
	button.add_theme_stylebox_override("pressed", UIStyleFactory.button(Color("#5e784c"), 14, 13))
	button.add_theme_color_override("font_color", Color.WHITE)
	return button
