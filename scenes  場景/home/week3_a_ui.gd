extends Node

const LOCATION_DATA := {
	"home": {
		"name": "Amy 的家",
		"icon": "🏠",
		"description": "Amy 可以在這裡休息，恢復精神。",
		"activities": ["home_rest"]
	},
	"forest": {
		"name": "森林",
		"icon": "🌲",
		"description": "這裡有一條安靜的小路，也有通往森林深處的方向。",
		"activities": ["forest_walk", "forest_explore"]
	},
	"lake": {
		"name": "湖邊",
		"icon": "🎣",
		"description": "水面很平靜，偶爾可以看見魚游過。",
		"activities": ["fishing"]
	}
}

const LEAF_MARK_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/characters/leaf_mark.png")

const ACTIVITY_NAMES := {
	"home_rest": "在家休息",
	"forest_walk": "森林散步",
	"forest_explore": "森林探索",
	"fishing": "湖邊釣魚"
}

@onready var host: Node = get_parent()
@onready var player: RabbitCharacter = host.get_node("Background/Player")
@onready var hud_layout: VBoxContainer = host.get_node("CanvasLayer/AUI/MainHUD/Margin/Layout")
@onready var main_panel: PanelContainer = host.get_node("CanvasLayer/AUI/MainHUD")
@onready var old_forest_button: Button = host.get_node("CanvasLayer/AUI/MainHUD/Margin/Layout/ForestButton")
@onready var old_fishing_button: Button = host.get_node("CanvasLayer/AUI/MainHUD/Margin/Layout/FishingButton")

var layer: CanvasLayer
var map_layer: CanvasLayer
var location_popup: Control
var location_title: Label
var location_description: Label
var activity_list: VBoxContainer
var growth_popup: Control
var album_window: Control
var album_list: VBoxContainer
var forest_tendency: Label
var lake_tendency: Label
var leaf_mark: Sprite2D
var interaction_locked := false


func _ready() -> void:
	call_deferred("_setup")


func _setup() -> void:
	old_forest_button.hide()
	old_fishing_button.hide()
	main_panel.offset_bottom = 790.0
	_create_hud_extensions()
	_create_map_location_buttons()
	_create_overlay_layer()
	_create_location_popup()
	_create_growth_event_popup()
	_create_album_window()
	_create_leaf_mark()
	_refresh_growth_ui()
	player.rabbit_status_changed.connect(_on_rabbit_status_changed)
	player.activity_manager.activity_started.connect(func(_active: ActiveActivityData) -> void: _close_transient_windows())


func _create_hud_extensions() -> void:
	var separator := HSeparator.new()
	hud_layout.add_child(separator)

	var location_heading := Label.new()
	location_heading.text = "村莊地點"
	location_heading.add_theme_font_size_override("font_size", 18)
	location_heading.add_theme_color_override("font_color", Color("#566a4e"))
	hud_layout.add_child(location_heading)

	var location_row := HBoxContainer.new()
	location_row.add_theme_constant_override("separation", 7)
	hud_layout.add_child(location_row)
	for location_id in ["home", "forest", "lake"]:
		var button := Button.new()
		var data: Dictionary = LOCATION_DATA[location_id]
		button.text = "%s %s" % [data.icon, data.name]
		button.custom_minimum_size = Vector2(108, 48)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_open_location.bind(location_id))
		location_row.add_child(button)

	forest_tendency = Label.new()
	forest_tendency.add_theme_font_size_override("font_size", 16)
	forest_tendency.add_theme_color_override("font_color", Color("#51704e"))
	hud_layout.add_child(forest_tendency)

	lake_tendency = Label.new()
	lake_tendency.add_theme_font_size_override("font_size", 16)
	lake_tendency.add_theme_color_override("font_color", Color("#527584"))
	hud_layout.add_child(lake_tendency)

	var album_button := Button.new()
	album_button.text = "🍃  成長相簿"
	album_button.custom_minimum_size = Vector2(0, 48)
	album_button.add_theme_font_size_override("font_size", 18)
	album_button.pressed.connect(_open_album)
	hud_layout.add_child(album_button)


func _create_map_location_buttons() -> void:
	map_layer = CanvasLayer.new()
	map_layer.name = "MapLocationButtons"
	map_layer.layer = 2
	add_child(map_layer)
	_add_map_location_button("home", "🏠  Amy 的家", Vector2(440, 245))
	_add_map_location_button("forest", "🌲  森林入口", Vector2(1360, 140))
	_add_map_location_button("lake", "🎣  湖邊", Vector2(1420, 760))


func _create_overlay_layer() -> void:
	layer = CanvasLayer.new()
	layer.name = "Week3AUI"
	layer.layer = 18
	add_child(layer)


func _add_map_location_button(location_id: String, label: String, position: Vector2) -> void:
	var button := Button.new()
	button.name = "%sArea" % location_id.capitalize()
	button.text = label
	button.position = position
	button.size = Vector2(210, 54)
	button.tooltip_text = "前往%s" % LOCATION_DATA[location_id].name
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _solid_button_style(Color("#fff8e8e8")))
	button.add_theme_stylebox_override("hover", _solid_button_style(Color("#fffdf5")))
	button.add_theme_color_override("font_color", Color("#40573e"))
	button.pressed.connect(_open_location.bind(location_id))
	map_layer.add_child(button)


func _create_location_popup() -> void:
	location_popup = Control.new()
	location_popup.name = "LocationPopup"
	location_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	location_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(location_popup)

	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.12, 0.08, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	location_popup.add_child(shade)

	var card := PanelContainer.new()
	card.position = Vector2(650, 220)
	card.size = Vector2(620, 600)
	card.add_theme_stylebox_override("panel", _card_style(Color("#fffaf0"), Color("#b89559")))
	location_popup.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	location_title = Label.new()
	location_title.add_theme_font_size_override("font_size", 34)
	location_title.add_theme_color_override("font_color", Color("#3d5c3d"))
	box.add_child(location_title)
	location_description = Label.new()
	location_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	location_description.add_theme_font_size_override("font_size", 20)
	location_description.add_theme_color_override("font_color", Color("#665b4b"))
	box.add_child(location_description)
	var line := HSeparator.new()
	box.add_child(line)
	var heading := Label.new()
	heading.text = "可以進行的活動"
	heading.add_theme_font_size_override("font_size", 20)
	box.add_child(heading)
	activity_list = VBoxContainer.new()
	activity_list.add_theme_constant_override("separation", 12)
	box.add_child(activity_list)
	var close := Button.new()
	close.text = "返回村莊"
	close.custom_minimum_size = Vector2(0, 52)
	close.pressed.connect(func() -> void: location_popup.hide())
	box.add_child(close)
	location_popup.hide()


func _open_location(location_id: String) -> void:
	if interaction_locked or player.activity_manager.has_active_activity():
		return
	var data: Dictionary = LOCATION_DATA[location_id]
	var available_ids: Array[String] = []
	for activity_id: String in data.activities:
		if player.activity_manager.get_activity(activity_id) != null:
			available_ids.append(activity_id)
	if available_ids.size() == 1:
		_choose_activity(available_ids[0])
		return
	location_title.text = "%s  %s" % [data.icon, data.name]
	location_description.text = data.description
	for child in activity_list.get_children():
		child.queue_free()
	for activity_id: String in data.activities:
		var activity := player.activity_manager.get_activity(activity_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 66)
		button.add_theme_font_size_override("font_size", 20)
		if activity == null:
			button.text = "%s　（等待 B 的活動資料）" % ACTIVITY_NAMES[activity_id]
			button.disabled = true
		else:
			button.text = "%s　·　%d 秒" % [activity.activity_name, int(activity.duration_seconds)]
			button.pressed.connect(_choose_activity.bind(activity_id))
		activity_list.add_child(button)
	location_popup.show()


func _choose_activity(activity_id: String) -> void:
	location_popup.hide()
	host.call("_open_activity_popup", activity_id)


func _create_growth_event_popup() -> void:
	growth_popup = Control.new()
	growth_popup.name = "GrowthEventPopup"
	growth_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	growth_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(growth_popup)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.1, 0.06, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	growth_popup.add_child(shade)
	var card := PanelContainer.new()
	card.position = Vector2(610, 205)
	card.size = Vector2(700, 650)
	card.add_theme_stylebox_override("panel", _card_style(Color("#fffaf0"), Color("#88a968")))
	growth_popup.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	margin.add_child(box)
	var kicker := Label.new()
	kicker.text = "SPECIAL GROWTH MEMORY"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_color_override("font_color", Color("#78915c"))
	box.add_child(kicker)
	var title := Label.new()
	title.text = "🍃  耳朵旁的小葉子"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#3f653f"))
	box.add_child(title)
	var leaf := Label.new()
	leaf.text = "🍃"
	leaf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaf.add_theme_font_size_override("font_size", 100)
	box.add_child(leaf)
	var content := Label.new()
	content.text = "Amy 從森林回來時，耳朵旁黏著一片小葉子。\n牠似乎很喜歡，沒有把它拿下來。"
	content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_font_size_override("font_size", 22)
	content.add_theme_color_override("font_color", Color("#4f5546"))
	content.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.8))
	content.add_theme_constant_override("shadow_offset_x", 1)
	content.add_theme_constant_override("shadow_offset_y", 1)
	box.add_child(content)
	var confirm := Button.new()
	confirm.text = "看看 Amy"
	confirm.custom_minimum_size = Vector2(0, 58)
	confirm.add_theme_font_size_override("font_size", 21)
	confirm.add_theme_stylebox_override("normal", _solid_button_style(Color("#557a50")))
	confirm.add_theme_stylebox_override("hover", _solid_button_style(Color("#6b9164")))
	confirm.add_theme_color_override("font_color", Color.WHITE)
	confirm.pressed.connect(_confirm_growth_event)
	box.add_child(confirm)
	growth_popup.hide()


func _confirm_growth_event() -> void:
	if not interaction_locked or not player.has_method("GetPendingGrowthEvent"):
		return
	var pending: GrowthEventData = player.call("GetPendingGrowthEvent")
	if pending == null or not player.has_method("ConfirmGrowthEvent"):
		return
	if not bool(player.call("ConfirmGrowthEvent", pending.event_id)):
		return
	interaction_locked = false
	growth_popup.hide()
	_refresh_growth_ui()


func _create_leaf_mark() -> void:
	leaf_mark = Sprite2D.new()
	leaf_mark.name = "LeafMarkSprite"
	leaf_mark.texture = LEAF_MARK_TEXTURE
	leaf_mark.position = Vector2(22, -104)
	leaf_mark.scale = Vector2(0.045, 0.045)
	leaf_mark.z_index = 2
	player.add_child(leaf_mark)
	leaf_mark.hide()


func _create_album_window() -> void:
	album_window = Control.new()
	album_window.name = "GrowthAlbumWindow"
	album_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	album_window.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(album_window)
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.12, 0.08, 0.58)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	album_window.add_child(shade)
	var card := PanelContainer.new()
	card.position = Vector2(510, 100)
	card.size = Vector2(900, 880)
	card.add_theme_stylebox_override("panel", _card_style(Color("#fffaf0"), Color("#b89559")))
	album_window.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "🍃  Amy 的成長相簿"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#456245"))
	header.add_child(title)
	var close := Button.new()
	close.text = "關閉"
	close.pressed.connect(func() -> void: album_window.hide())
	header.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	album_list = VBoxContainer.new()
	album_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_list.add_theme_constant_override("separation", 16)
	scroll.add_child(album_list)
	album_window.hide()


func _open_album() -> void:
	if interaction_locked:
		return
	_refresh_album()
	album_window.show()


func _refresh_album() -> void:
	for child in album_list.get_children():
		child.queue_free()
	var entries: Array[GrowthAlbumEntry] = player.get_growth_album_entries()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "目前還沒有成長印記。\n\n陪 Amy 多去不同的地方看看吧！"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 26)
		empty.add_theme_color_override("font_color", Color("#4b5f44"))
		empty.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.85))
		empty.add_theme_constant_override("shadow_offset_x", 1)
		empty.add_theme_constant_override("shadow_offset_y", 1)
		album_list.add_child(empty)
		return
	var album_entry: GrowthAlbumEntry = entries[0]
	var entry := PanelContainer.new()
	entry.add_theme_stylebox_override("panel", _card_style(Color("#fffdf5"), Color("#bdd09a")))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	entry.add_child(margin)
	var text := Label.new()
	var unlocked := Time.get_datetime_dict_from_unix_time(int(album_entry.unlocked_at))
	var unlocked_date := "%04d/%02d/%02d" % [unlocked.year, unlocked.month, unlocked.day]
	text.text = "🍃  %s\n\n成長路線：%s\n階段：第%d階段\n取得日期：%s\n\n%s" % [
		album_entry.title, album_entry.growth_path, album_entry.stage, unlocked_date, album_entry.description
	]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 22)
	text.add_theme_color_override("font_color", Color("#4b5f44"))
	margin.add_child(text)
	album_list.add_child(entry)


func _refresh_growth_ui() -> void:
	var has_leaf := _has_leaf_mark()
	leaf_mark.visible = has_leaf and player.visible
	forest_tendency.text = "森林傾向：%s" % ("微弱" if has_leaf else "尚未形成")
	lake_tendency.text = "湖畔傾向：尚未形成"
	if _has_pending_growth_event():
		interaction_locked = true
		_close_transient_windows()
		growth_popup.show()


func _has_leaf_mark() -> bool:
	if player.has_method("HasGrowthMark"):
		return bool(player.call("HasGrowthMark", "leaf_mark"))
	return false


func _has_pending_growth_event() -> bool:
	if player.has_method("GetPendingGrowthEvent"):
		return player.call("GetPendingGrowthEvent") != null
	return false


func _on_rabbit_status_changed(_rabbit: RabbitData) -> void:
	_refresh_growth_ui()


func _close_transient_windows() -> void:
	location_popup.hide()
	album_window.hide()


func _solid_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	return style


func _card_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(26)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 16
	return style
