extends Node

const CAFE_VIEW_SCENE := preload("res://scenes  場景/cafe/CafeView.tscn")
const CAFE_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/coffee_shop.png")
const SLOT_IDS := ["building_slot_01", "building_slot_02", "building_slot_03", "building_slot_04", "building_slot_05"]
const CAFE_COST := {"coin": 80, "twig": 10, "driftwood": 5, "small_stone": 4}
const CAFE_ACTIVITY_NAMES := {
	"cafe_hot_drink": "喝熱飲",
	"cafe_help_serve": "幫忙端飲料",
	"cafe_relax": "安靜坐一下"
}

var player: RabbitCharacter
var hud_layer: CanvasLayer
var modal_layer: CanvasLayer
var scene_layer: CanvasLayer
var launcher: PanelContainer
var expansion_window: Control
var construction_panel: PanelContainer
var construction_label: Label
var cafe_status_label: Label
var cafe_cost_label: Label
var progress_label: Label
var growth_label: Label
var diary_list: VBoxContainer
var build_button: Button
var enter_cafe_button: Button
var slot_buttons: Dictionary = {}
var selected_slot_id := ""
var selected_diary_filter := "全部"
var modal_queue: Array[Dictionary] = []
var modal_busy := false
var cafe_view: Control
var _last_construction_id := ""
var _last_cafe_state := ""
var _last_second := -1
var _overlay_root: Node2D


func _ready() -> void:
	player = get_parent().get_node_or_null("Background/Player") as RabbitCharacter
	if player == null:
		push_error("VillageExpansionUI 找不到 Background/Player")
		return
	_create_layers()
	_create_launcher()
	_create_expansion_window()
	_create_construction_status()
	_create_growth_overlay()
	_connect_runtime_signals()
	_refresh_all()
	_last_cafe_state = _cafe_state()


func _process(_delta: float) -> void:
	if player == null:
		return
	var current_state := _cafe_state()
	if current_state != _last_cafe_state:
		var old_state := _last_cafe_state
		_last_cafe_state = current_state
		_refresh_all()
		if current_state == BuildingState.COMPLETED and old_state != BuildingState.COMPLETED:
			_enqueue_modal("咖啡廳完工了！", "施工圍欄已經撤下，咖啡廳正式成為村莊的一部分。\n\nAmy 現在可以進去看看。", 100, _open_cafe)
	_refresh_construction_status()
	_refresh_growth_overlay()


func _create_layers() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "VillageExpansionHUDLayer"
	hud_layer.layer = 31
	add_child(hud_layer)
	modal_layer = CanvasLayer.new()
	modal_layer.name = "VillageExpansionModalLayer"
	modal_layer.layer = 130
	add_child(modal_layer)
	scene_layer = CanvasLayer.new()
	scene_layer.name = "CafeSceneLayer"
	scene_layer.layer = 80
	add_child(scene_layer)


func _create_launcher() -> void:
	launcher = PanelContainer.new()
	launcher.position = Vector2(1570, 270)
	launcher.size = Vector2(320, 270)
	launcher.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff8e9ee"), Color("#8e704d"), 22, 2, 10))
	hud_layer.add_child(launcher)
	var box := _margin_vbox(launcher, 18)
	var title := _label("村莊擴張", 23, Color("#59402c"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var open := _button("建築與村莊進度")
	open.pressed.connect(_open_expansion)
	box.add_child(open)
	enter_cafe_button = _button("進入咖啡廳")
	enter_cafe_button.pressed.connect(_open_cafe)
	box.add_child(enter_cafe_button)
	var badge := _label("可放置建築　×1", 17, Color("#6e593f"))
	badge.name = "BuildingBadge"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(badge)


func _create_expansion_window() -> void:
	expansion_window = _window_root("VillageExpansionWindow")
	var card := _card(expansion_window, Vector2(180, 65), Vector2(1560, 950))
	var layout := _margin_vbox(card, 28)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	layout.add_child(header)
	var title := _label("村莊正式擴張", 34, Color("#543d2b"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_label("咖啡廳建設 · 成長深化", 19, Color("#7d6851")))
	header.add_child(_close_button(expansion_window))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 22)
	layout.add_child(columns)
	var building_column := VBoxContainer.new()
	building_column.custom_minimum_size = Vector2(800, 0)
	building_column.add_theme_constant_override("separation", 14)
	columns.add_child(building_column)
	var info_column := VBoxContainer.new()
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_column.add_theme_constant_override("separation", 14)
	columns.add_child(info_column)

	var cafe_card := PanelContainer.new()
	cafe_card.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#f7ecd8"), Color("#c09a68"), 20, 2))
	building_column.add_child(cafe_card)
	var cafe_box := _margin_vbox(cafe_card, 22)
	var cafe_header := HBoxContainer.new()
	cafe_box.add_child(cafe_header)
	var image := TextureRect.new()
	image.texture = CAFE_TEXTURE
	image.custom_minimum_size = Vector2(210, 130)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cafe_header.add_child(image)
	var cafe_text := VBoxContainer.new()
	cafe_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cafe_header.add_child(cafe_text)
	cafe_text.add_child(_label("咖啡廳", 30, Color("#533c2a")))
	var description := _label("一位咖啡師想在村莊開店。完成後，Amy 能在這裡喝熱飲、幫忙與休息。", 18, Color("#665341"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cafe_text.add_child(description)
	cafe_status_label = _label("", 19, Color("#496249"))
	cafe_text.add_child(cafe_status_label)
	cafe_cost_label = _label("", 18, Color("#594b3d"))
	cafe_cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cafe_box.add_child(cafe_cost_label)
	build_button = _button("選擇咖啡廳")
	build_button.pressed.connect(_begin_placement)
	cafe_box.add_child(build_button)

	building_column.add_child(_label("選擇建築預留地", 24, Color("#59402c")))
	var slots := GridContainer.new()
	slots.columns = 3
	slots.add_theme_constant_override("h_separation", 12)
	slots.add_theme_constant_override("v_separation", 12)
	building_column.add_child(slots)
	for index in SLOT_IDS.size():
		var slot_id: String = str(SLOT_IDS[index])
		var button := _button("＋\n建築預留地 %02d" % (index + 1))
		button.custom_minimum_size = Vector2(240, 92)
		button.pressed.connect(_select_slot.bind(slot_id))
		slots.add_child(button)
		slot_buttons[slot_id] = button

	var placement_actions := HBoxContainer.new()
	placement_actions.add_theme_constant_override("separation", 12)
	building_column.add_child(placement_actions)
	var preview := _button("查看放置預覽")
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.pressed.connect(_preview_placement)
	placement_actions.add_child(preview)
	var cancel := _button("取消選擇")
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_cancel_placement)
	placement_actions.add_child(cancel)

	var progress_card := PanelContainer.new()
	progress_card.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#edf3e5"), Color("#91a77c"), 18, 2))
	info_column.add_child(progress_card)
	var progress_box := _margin_vbox(progress_card, 20)
	progress_box.add_child(_label("村莊進度", 26, Color("#43563c")))
	progress_label = _label("", 18, Color("#4e5547"))
	progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_box.add_child(progress_label)

	var growth_card := PanelContainer.new()
	growth_card.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#eaf1de"), Color("#8ba070"), 18, 2))
	info_column.add_child(growth_card)
	var growth_box := _margin_vbox(growth_card, 20)
	growth_box.add_child(_label("Amy 的成長方向", 26, Color("#43563c")))
	growth_label = _label("", 18, Color("#4e5547"))
	growth_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	growth_box.add_child(growth_label)

	var diary_card := PanelContainer.new()
	diary_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diary_card.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fffaf0"), Color("#c6aa7e"), 18, 2))
	info_column.add_child(diary_card)
	var diary_box := _margin_vbox(diary_card, 18)
	diary_box.add_child(_label("日記篩選", 24, Color("#59402c")))
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	diary_box.add_child(filters)
	for filter_name in ["全部", "咖啡廳", "建築", "森林", "湖畔", "生活", "Forest Rabbit", "Lakeside Rabbit"]:
		var filter_button := Button.new()
		filter_button.text = filter_name
		filter_button.pressed.connect(_set_diary_filter.bind(filter_name))
		filters.add_child(filter_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diary_box.add_child(scroll)
	diary_list = VBoxContainer.new()
	diary_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diary_list.add_theme_constant_override("separation", 5)
	scroll.add_child(diary_list)


func _create_construction_status() -> void:
	construction_panel = PanelContainer.new()
	construction_panel.position = Vector2(610, 25)
	construction_panel.size = Vector2(700, 92)
	construction_panel.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#3f4d36eb"), Color("#9ab07d"), 18, 2, 8))
	hud_layer.add_child(construction_panel)
	var box := _margin_vbox(construction_panel, 14)
	construction_label = _label("咖啡廳施工中", 21, Color.WHITE)
	construction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(construction_label)
	construction_panel.hide()


func _create_growth_overlay() -> void:
	_overlay_root = Node2D.new()
	_overlay_root.name = "GrowthAppearanceOverlay"
	player.add_child.call_deferred(_overlay_root)


func _connect_runtime_signals() -> void:
	_connect_if_present(player.construction_manager, "construction_started", _on_construction_started)
	_connect_if_present(player.construction_manager, "construction_completed", _on_construction_completed)
	_connect_if_present(player.village_event_manager, "village_event_created", _on_village_event)
	_connect_if_present(player.life_event_manager, "life_event_triggered", _on_village_event)
	_connect_if_present(player.growth_manager, "growth_event_created", _on_growth_event)
	_connect_if_present(player.growth_manager, "growth_event_confirmed", _on_growth_event)
	_connect_if_present(player.diary_manager, "journals_changed", _refresh_diary)


func _open_expansion() -> void:
	_refresh_all()
	expansion_window.show()


func _begin_placement() -> void:
	selected_slot_id = ""
	_refresh_slots()
	_enqueue_modal("選擇咖啡廳位置", "可用的建築預留地已經高亮。\n請選擇 Slot 01～05，再查看放置預覽。", 40)


func _select_slot(slot_id: String) -> void:
	if _slot_is_occupied(slot_id):
		_enqueue_modal("這塊地已被使用", "%s 已有建築，請選擇其他預留地。" % _slot_title(slot_id), 50)
		return
	selected_slot_id = slot_id
	_refresh_slots()


func _preview_placement() -> void:
	if selected_slot_id.is_empty():
		_enqueue_modal("尚未選擇位置", "請先選擇一塊高亮的建築預留地。", 50)
		return
	var formal_ready := _cafe_runtime_ready()
	var body := "咖啡廳將建在 %s。\n\n成本\n%s\n\n施工測試時間：30 秒" % [_slot_title(selected_slot_id), _cost_text(false)]
	if not formal_ready:
		body += "\n\n咖啡廳尚未正式開放，因此目前不會扣除金幣或素材。"
	_enqueue_modal("咖啡廳放置預覽", body, 80, _confirm_placement if formal_ready else Callable())


func _confirm_placement() -> void:
	if not _cafe_runtime_ready():
		return
	var runtime_slot := _runtime_slot_id(selected_slot_id)
	var cafe_id := _runtime_cafe_id()
	var check: Dictionary = player.can_place_building(cafe_id, runtime_slot)
	if not bool(check.get("ok", false)):
		_enqueue_modal("無法建造", _reason_text(str(check.get("reason", "現在無法放置咖啡廳"))), 100)
		return
	var placed: Dictionary = player.place_building(cafe_id, runtime_slot)
	if not bool(placed.get("ok", false)):
		_enqueue_modal("放置失敗", _reason_text(str(placed.get("reason", "位置沒有保存"))), 100)
		return
	var started: Dictionary = player.start_construction("cafe")
	if not bool(started.get("ok", false)):
		_enqueue_modal("施工未開始", _reason_text(str(started.get("reason", "請稍後再試"))), 100)
		return
	selected_slot_id = ""
	_refresh_all()
	_enqueue_modal("施工開始", "咖啡廳已放入預留地，施工倒數正式開始。\n關閉遊戲後，真實時間仍會繼續。", 90)


func _cancel_placement() -> void:
	selected_slot_id = ""
	_refresh_slots()


func _open_cafe() -> void:
	if _cafe_state() != BuildingState.COMPLETED:
		_enqueue_modal("咖啡廳尚未完工", "完成施工後才能進入咖啡廳。", 60)
		return
	if cafe_view == null:
		cafe_view = CAFE_VIEW_SCENE.instantiate() as Control
		cafe_view.back_requested.connect(_close_cafe)
		cafe_view.activity_requested.connect(_start_cafe_activity)
		scene_layer.add_child(cafe_view)
	cafe_view.set_activity_enabled(true)
	cafe_view.set_experience_hint(_cafe_experience_hint())
	cafe_view.show()


func _close_cafe() -> void:
	if cafe_view != null:
		cafe_view.hide()


func _start_cafe_activity(activity_id: String) -> void:
	if player.has_method("start_cafe_activity"):
		var result: Variant = player.call("start_cafe_activity", activity_id)
		if result is Dictionary and bool(result.get("ok", false)):
			_close_cafe()
			_enqueue_modal("咖啡廳活動開始", "Amy 開始「%s」了。\n活動會沿用離線完成規則。" % CAFE_ACTIVITY_NAMES.get(activity_id, "咖啡廳活動"), 70)
			return
		var reason := str(result.get("reason", "目前無法開始")) if result is Dictionary else "目前無法開始"
		_enqueue_modal("無法開始活動", _reason_text(reason), 80)
		return
	_enqueue_modal("活動尚未開放", "「%s」目前還不能開始。" % CAFE_ACTIVITY_NAMES.get(activity_id, activity_id), 70)


func _refresh_all() -> void:
	_refresh_cafe_card()
	_refresh_slots()
	_refresh_progress()
	_refresh_growth()
	_refresh_diary()
	_refresh_construction_status()


func _refresh_cafe_card() -> void:
	var state := _cafe_state()
	var state_text: String = str({
		BuildingState.LOCKED: "尚未解鎖 · 等待咖啡師來到村莊",
		BuildingState.AVAILABLE: "已解鎖 · 可以選擇位置",
		BuildingState.PLACED: "已放置 · 準備施工",
		BuildingState.CONSTRUCTING: "施工中",
		BuildingState.COMPLETED: "已完工 · 可以進入"
	}.get(state, "咖啡廳尚未開放"))
	if not _cafe_runtime_ready():
		state_text = "咖啡廳建設功能準備中"
	cafe_status_label.text = str(state_text)
	cafe_cost_label.text = "建造成本\n%s\n建造時間　30 秒（測試設定保留）" % _cost_text(true)
	build_button.disabled = state in [BuildingState.CONSTRUCTING, BuildingState.COMPLETED]
	build_button.text = "施工中" if state == BuildingState.CONSTRUCTING else "已完工" if state == BuildingState.COMPLETED else "選擇咖啡廳與位置"
	enter_cafe_button.disabled = state != BuildingState.COMPLETED
	var badge := launcher.get_node_or_null("MarginContainer/VBoxContainer/BuildingBadge") as Label
	if badge != null:
		badge.text = "可放置建築　×%d" % (1 if state == BuildingState.AVAILABLE else 0)


func _refresh_slots() -> void:
	for slot_id: String in SLOT_IDS:
		var button := slot_buttons[slot_id] as Button
		var occupied := _slot_is_occupied(slot_id)
		var selected := selected_slot_id == slot_id
		button.disabled = occupied
		button.text = "%s\n%s" % [_slot_title(slot_id), "已放置建築" if occupied else "咖啡廳預覽" if selected else "＋ 建築預留地"]
		button.modulate = Color("#a8d49b") if selected else Color("#b9b4a9") if occupied else Color.WHITE


func _refresh_progress() -> void:
	var completed := 0
	var unlocked := 0
	if player.village_data != null:
		for raw: Dictionary in player.village_data.building_records.values():
			if str(raw.get("state", "")) == BuildingState.COMPLETED:
				completed += 1
		unlocked = player.village_data.unlocked_building_ids.size()
	var life_locations := 1 + (1 if _cafe_state() == BuildingState.COMPLETED else 0)
	var growth_count := player.get_unlocked_growth_marks().size()
	progress_label.text = "建築　%d 棟完成／%d 棟已解鎖\n生活地點　%d\nAmy 成長印記　%d\n村莊階段　%d\n\nAmy 的生活正在一點一點改變村莊。" % [completed, unlocked, life_locations, growth_count, player.get_village_level()]


func _refresh_growth() -> void:
	var forest_stage := 2 if player.has_growth_mark("sprout_mark") else 1 if player.has_growth_mark("leaf_mark") else 0
	var lakeside_stage := 1 if player.get_fishing_experience() > 0 else 0
	var forest_tendency := player.get_growth_tendency("forest")
	var lakeside_tendency := player.get_growth_tendency("lakeside")
	growth_label.text = "森林傾向　%s　· Stage %d\n湖畔傾向　%s　· Stage %d\n\nForest Stage 3：%s\nLakeside Stage 2：%s\n\n外觀採 Base＋Growth Overlay＋Expression，不複製 Amy 場景。" % [
		_tendency_text(forest_tendency), forest_stage,
		_tendency_text(lakeside_tendency), lakeside_stage,
		"已形成" if _has_growth_appearance("forest_stage3") else "繼續累積生活經歷",
		"已形成" if _has_growth_appearance("lakeside_stage2") else "繼續累積湖畔經歷"
	]


func _refresh_diary() -> void:
	if diary_list == null:
		return
	_clear(diary_list)
	var shown := 0
	for entry: JournalEntry in player.get_all_journals():
		if not _journal_matches(entry, selected_diary_filter):
			continue
		var row := _label("• %s" % entry.title, 16, Color("#5a4d40"))
		row.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		diary_list.add_child(row)
		shown += 1
		if shown >= 6:
			break
	if shown == 0:
		diary_list.add_child(_label("目前沒有符合「%s」的日記。" % selected_diary_filter, 16, Color("#897866")))


func _set_diary_filter(filter_name: String) -> void:
	selected_diary_filter = filter_name
	_refresh_diary()


func _refresh_construction_status() -> void:
	if not player.has_active_construction():
		construction_panel.hide()
		_last_second = -1
		return
	var record := player.get_active_construction()
	if record == null or record.building_id not in ["cafe", "coffee_shop"]:
		construction_panel.hide()
		return
	var seconds := ceili(player.get_construction_remaining_seconds())
	if seconds == _last_second:
		return
	_last_second = seconds
	construction_panel.show()
	construction_label.text = "咖啡廳施工中　·　剩餘 %s　·　%s" % [_format_time(seconds), _slot_title(_display_slot_id(record.slot_id))]


func _refresh_growth_overlay() -> void:
	if _overlay_root == null or not is_instance_valid(_overlay_root):
		return
	for child in _overlay_root.get_children():
		child.queue_free()
	if _has_growth_appearance("forest_stage3"):
		var forest_mark := Polygon2D.new()
		forest_mark.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(0, -18), Vector2(12, 0), Vector2(0, 8)])
		forest_mark.color = Color("#6e9c4f")
		forest_mark.position = Vector2(0, -96)
		_overlay_root.add_child(forest_mark)
	if _has_growth_appearance("lakeside_stage2"):
		for offset in [-14.0, 0.0, 14.0]:
			var ripple := Line2D.new()
			ripple.width = 3.0
			ripple.default_color = Color("#75a9bd")
			ripple.points = PackedVector2Array([Vector2(offset - 8, -72), Vector2(offset, -77), Vector2(offset + 8, -72)])
			_overlay_root.add_child(ripple)


func _on_construction_started(record: Variant) -> void:
	if record != null and str(_value(record, "building_id", "")) in ["cafe", "coffee_shop"]:
		_last_construction_id = str(_value(record, "construction_record_id", ""))
		_refresh_all()


func _on_construction_completed(result: Variant) -> void:
	if result != null and str(_value(result, "building_id", "")) in ["cafe", "coffee_shop"]:
		_refresh_all()
		_enqueue_modal("咖啡廳完工了！", "Amy 看著新咖啡廳亮起燈，村莊第一次真的有了新的生活去處。", 100, _open_cafe)


func _on_growth_event(event: Variant) -> void:
	if event == null:
		return
	var event_id := str(_value(event, "event_id", ""))
	if "forest" in event_id:
		_enqueue_modal("森林傾向變得更明顯了", "Amy 身上出現了新的森林印記。", 90)
	elif "lakeside" in event_id or "fishing" in event_id:
		_enqueue_modal("湖畔的記憶留下來了", "一道像水波的細微印記，記住了 Amy 在湖邊度過的日子。", 90)
	_refresh_all()


func _on_village_event(event: Variant) -> void:
	if event == null:
		return
	var event_id := str(_value(event, "event_id", ""))
	if event_id in ["building_cafe_unlock_001", "cafe_barista_arrives_001"]:
		_enqueue_modal(
			"村莊事件：咖啡師來到村莊",
			"一位咖啡師來到村莊。\n\n「如果有地方的話，我想在這裡開一家小咖啡廳。」\n\n解鎖新建築：咖啡廳",
			120,
			_open_expansion
		)


func _enqueue_modal(title: String, body: String, priority := 50, action: Callable = Callable()) -> void:
	modal_queue.append({"title": title, "body": body, "priority": priority, "action": action})
	modal_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.priority) > int(b.priority))
	if not modal_busy:
		call_deferred("_show_next_modal")


func _show_next_modal() -> void:
	if modal_busy or modal_queue.is_empty():
		return
	modal_busy = true
	var item: Dictionary = modal_queue.pop_front()
	var action: Callable = item.action
	var primary_text := "前往看看" if action.is_valid() else "知道了"
	UIModalPresenter.show_actions(modal_layer, str(item.title), str(item.body), primary_text, func() -> void:
		if action.is_valid():
			action.call()
		modal_busy = false
		call_deferred("_show_next_modal")
	, "稍後" if action.is_valid() else "", func() -> void:
		modal_busy = false
		call_deferred("_show_next_modal")
	, CAFE_TEXTURE if "咖啡" in str(item.title) else null)


func _cafe_runtime_ready() -> bool:
	return not _runtime_cafe_id().is_empty()


func _runtime_cafe_id() -> String:
	if player.get_building("cafe") != null:
		return "cafe"
	if player.get_building("coffee_shop") != null:
		return "coffee_shop"
	return ""


func _cafe_state() -> String:
	var id := _runtime_cafe_id()
	return player.get_building_state(id) if not id.is_empty() else BuildingState.LOCKED


func _slot_is_occupied(display_slot_id: String) -> bool:
	if player.village_data == null:
		return false
	var runtime_slot := _runtime_slot_id(display_slot_id)
	for raw: Dictionary in player.village_data.building_records.values():
		if str(raw.get("slot_id", "")) == runtime_slot:
			return true
	return false


func _runtime_slot_id(display_slot_id: String) -> String:
	if _runtime_cafe_id() == "cafe":
		return display_slot_id
	var suffix := display_slot_id.trim_prefix("building_slot_")
	return "Slot%s" % suffix


func _display_slot_id(runtime_slot_id: String) -> String:
	if runtime_slot_id.begins_with("building_slot_"):
		return runtime_slot_id
	if runtime_slot_id.begins_with("Slot"):
		return "building_slot_%s" % runtime_slot_id.trim_prefix("Slot")
	return runtime_slot_id


func _slot_title(slot_id: String) -> String:
	return "Slot %s" % slot_id.right(2)


func _cost_text(show_owned: bool) -> String:
	var lines: Array[String] = []
	var owned_coin := player.get_coin_amount()
	lines.append("Coin　%d / %d" % [owned_coin, CAFE_COST.coin] if show_owned else "Coin × %d" % CAFE_COST.coin)
	for item_id in ["twig", "driftwood", "small_stone"]:
		var names := {"twig": "Twig", "driftwood": "Driftwood", "small_stone": "Small Stone"}
		var owned := player.get_item_amount(item_id)
		lines.append("%s　%d / %d" % [names[item_id], owned, CAFE_COST[item_id]] if show_owned else "%s × %d" % [names[item_id], CAFE_COST[item_id]])
	return "\n".join(lines)


func _cafe_experience_hint() -> String:
	if player.has_method("get_cafe_experience"):
		var experience := int(player.call("get_cafe_experience"))
		if experience >= 24:
			return "Amy 已經很熟悉咖啡廳的節奏了。"
		if experience >= 10:
			return "Amy 最近好像開始熟悉咖啡廳了。"
	return "Amy 還在熟悉這間咖啡廳。"


func _has_growth_appearance(state_id: String) -> bool:
	if player.has_method("get_growth_appearance_state"):
		return str(player.call("get_growth_appearance_state")) == state_id
	return player.has_growth_mark(state_id)


func _journal_matches(entry: JournalEntry, filter_name: String) -> bool:
	if filter_name == "全部":
		return true
	var haystack := "%s %s %s %s %s" % [entry.journal_type, entry.title, entry.building_id, entry.location_id, entry.activity_id]
	match filter_name:
		"咖啡廳": return "cafe" in haystack or "咖啡" in haystack
		"建築": return "building" in haystack or "construction" in haystack or "建築" in haystack or "施工" in haystack
		"森林": return "forest" in haystack or "森林" in haystack
		"湖畔": return "lake" in haystack or "fishing" in haystack or "湖" in haystack
		"生活": return "life" in haystack or "生活" in haystack
		"Forest Rabbit": return "forest_rabbit" in haystack or "forest_final" in haystack
		"Lakeside Rabbit": return "lakeside_rabbit" in haystack or "lakeside_final" in haystack
	return true


func _tendency_text(value: String) -> String:
	return {"none": "尚未形成", "faint": "微弱", "clear": "明顯", "strong": "強烈"}.get(value, value if not value.is_empty() else "尚未形成")


func _format_time(total_seconds: int) -> String:
	var seconds := maxi(0, total_seconds)
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds % 3600) / 60, seconds % 60]


func _reason_text(reason: String) -> String:
	return reason if not reason.is_empty() else "現在無法進行這個操作。"


func _value(source: Variant, key: String, fallback: Variant = null) -> Variant:
	if source == null:
		return fallback
	if source is Dictionary:
		return source.get(key, fallback)
	var property_value: Variant = source.get(key)
	return fallback if property_value == null else property_value


func _connect_if_present(manager: Node, signal_name: String, callback: Callable) -> void:
	if manager != null and manager.has_signal(signal_name) and not manager.is_connected(signal_name, callback):
		manager.connect(signal_name, callback)


func _window_root(node_name: String) -> Control:
	var root := Control.new()
	root.name = node_name
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.hide()
	hud_layer.add_child(root)
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0, 0, 0, 0.48)
	root.add_child(veil)
	return root


func _card(parent: Control, position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = size
	panel.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff8e9"), Color("#9c7549"), 24, 2, 12))
	parent.add_child(panel)
	return panel


func _margin_vbox(parent: Control, amount: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, amount)
	parent.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	return box


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 54)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_stylebox_override("normal", UIStyleFactory.button(Color("#627f51"), 14, 11))
	button.add_theme_stylebox_override("hover", UIStyleFactory.button(Color("#769463"), 14, 11))
	button.add_theme_stylebox_override("pressed", UIStyleFactory.button(Color("#526c43"), 14, 11))
	button.add_theme_color_override("font_color", Color.WHITE)
	return button


func _close_button(window: Control) -> Button:
	var button := _button("關閉")
	button.custom_minimum_size = Vector2(130, 54)
	button.pressed.connect(window.hide)
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
