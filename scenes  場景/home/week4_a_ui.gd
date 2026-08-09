extends Node

const PAVILION_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/rest_pavilion.png")
const BOARD_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/notice_board.png")
const FARM_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/carrot_farm.png")
const COFFEE_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/coffee_shop.png")
const SLOT_POSITIONS := [Vector2(649,112),Vector2(1359,148),Vector2(127,439),Vector2(520,458),Vector2(811,439),Vector2(1280,465),Vector2(378,764),Vector2(860,758),Vector2(1140,741)]

var states := {"coffee_shop":"available","rest_pavilion":"available","notice_board":"locked","carrot_farm":"locked"}
var placements: Dictionary = {}
var selected_id := ""
var build_mode := true
var carrots := 20
var rest_left := 0.0
var rest_cooldown := 40.0
var farm_state := "ready"
var farm_left := 0.0
# C bridge: stable ids for A-side demo actions, so journals/history can de-duplicate.
var c_farm_cycle_id := ""
var c_harvest_serial := 0
var c_construction_record_ids: Dictionary = {}
var c_construction_started_at: Dictionary = {}
var c_rest_use_id := ""
var c_rest_started_at := 0.0
var c_rest_use_count := 0
var construction_end: Dictionary = {}
var built_once: Dictionary = {}
var _last_construction_second := -1
var toolbar: PanelContainer
var carrot_label: Label
var construction_status_label: Label
var hint: Label
var slot_layer: CanvasLayer
var modal_layer: CanvasLayer
var preview: TextureRect
var card_buttons: Dictionary = {}
var visual_root: Node2D

func _ready() -> void:
	_disable_legacy_coffee_demo()
	_sync_coffee_state()
	_load_village_state()
	_sync_coffee_state()
	visual_root = Node2D.new()
	visual_root.name = "Week4Buildings"
	get_parent().add_child.call_deferred(visual_root)
	_create_layers()
	_create_toolbar()
	_create_carrot_counter()
	_create_construction_status()
	_refresh_all()
	# Older A-side week-four saves may already have completed buildings but no C journals.
	call_deferred("_backfill_c_building_journals")
	call_deferred("_backfill_c_village_event_journals")
	if not c_rest_use_id.is_empty() and rest_left <= 0.0:
		call_deferred("_finish_rest")
	elif rest_left > 0.0:
		call_deferred("_show_rest_lock")
	else:
		call_deferred("_show_first_village_event")

func _show_village_event(title := "村莊事件：新的生活開始", story := "Amy 發現村裡多了幾個能停下腳步的地方。\n\n小休息亭已可建造；公告欄與胡蘿蔔農田會隨村莊進度解鎖。") -> void:
	_show_actions(title, story, "去看看", func(): pass, "稍後再看", func(): pass)

func _show_first_village_event() -> void:
	var player := _player()
	if player != null and player.HasJournalForVillageEvent("village_rest_pavilion_001"):
		return
	_show_actions(
		"村莊事件：村莊的新角落",
		"Amy 發現村莊裡多了一個適合停下腳步的角落。\n\n或許不久之後，這裡會有一座能好好休息的小亭子。",
		"去看看",
		Callable(self, "_record_c_village_event").bind("village_rest_pavilion_001"),
		"稍後再看",
		func(): pass
	)

func _process(delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	for building_id in construction_end.keys():
		if now >= float(construction_end[building_id]):
			states[building_id] = "completed"
			built_once[building_id] = true
			_record_c_construction_complete(str(building_id))
			construction_end.erase(building_id)
			_save_village_state()
			_refresh_all()
			_show_village_event("村莊事件：新建築完成", "%s施工完成了！\nAmy 好奇地靠近，想看看這個新地方。" % _title(building_id))
	var remaining_second := -1
	for building_id in construction_end:
		remaining_second = maxi(remaining_second, ceili(maxf(0.0, float(construction_end[building_id]) - now)))
	if remaining_second != _last_construction_second:
		_last_construction_second = remaining_second
		_refresh_visuals()
	if construction_status_label != null:
		construction_status_label.get_parent().visible = remaining_second >= 0
		if remaining_second >= 0:
			construction_status_label.text = "🏗 施工中：剩餘 %d 秒" % remaining_second
	if rest_left > 0.0:
		rest_left = maxf(0.0, rest_left - delta)
		if rest_left <= 0.0:
			_finish_rest()
		_refresh_rest_hint()
	if rest_cooldown > 0.0:
		rest_cooldown = maxf(0.0, rest_cooldown - delta)
	if farm_left > 0.0:
		farm_left = maxf(0.0, farm_left - delta)
		if farm_left <= 0.0:
			farm_state = "growing" if farm_state == "sprout" else "ready"
			farm_left = 30.0 if farm_state == "growing" else 0.0
			_save_village_state()
			_refresh_all()

func _disable_legacy_coffee_demo() -> void:
	var legacy := get_parent().get_node_or_null("BuildingSystem")
	if legacy != null:
		# 保留地圖上的咖啡廳，只隱藏舊版獨立介面。
		var old_ui := legacy.get_node_or_null("BuildingModeUI")
		if old_ui != null:
			for old_control in old_ui.get_children():
				if old_control is CanvasItem:
					old_control.hide()

func _sync_coffee_state() -> void:
	var legacy := get_parent().get_node_or_null("BuildingSystem")
	if legacy != null and legacy.placed_buildings.values().has("coffee_shop"):
		states.coffee_shop = "completed"
	else:
		states.coffee_shop = "available"

func _player() -> RabbitCharacter:
	return get_parent().get_node_or_null("Background/Player") as RabbitCharacter

func _load_village_state() -> void:
	var player := _player()
	if player == null or player.rabbit_data == null:
		return
	var saved: Dictionary = player.rabbit_data.village_a_state
	if saved.is_empty():
		return
	if saved.get("states", {}) is Dictionary: states = saved.states.duplicate(true)
	if saved.get("placements", {}) is Dictionary: placements = saved.placements.duplicate(true)
	carrots = int(saved.get("carrots", carrots))
	farm_state = str(saved.get("farm_state", farm_state))
	farm_left = float(saved.get("farm_left", farm_left))
	c_farm_cycle_id = str(saved.get("c_farm_cycle_id", c_farm_cycle_id))
	c_harvest_serial = maxi(0, int(saved.get("c_harvest_serial", c_harvest_serial)))
	if saved.get("c_construction_record_ids", {}) is Dictionary: c_construction_record_ids = saved.get("c_construction_record_ids", {}).duplicate(true)
	if saved.get("c_construction_started_at", {}) is Dictionary: c_construction_started_at = saved.get("c_construction_started_at", {}).duplicate(true)
	c_rest_use_id = str(saved.get("c_rest_use_id", c_rest_use_id))
	c_rest_started_at = maxf(0.0, float(saved.get("c_rest_started_at", c_rest_started_at)))
	c_rest_use_count = maxi(0, int(saved.get("c_rest_use_count", c_rest_use_count)))
	rest_left = float(saved.get("rest_left", rest_left))
	rest_cooldown = float(saved.get("rest_cooldown", rest_cooldown))
	if saved.get("construction_end", {}) is Dictionary: construction_end = saved.construction_end.duplicate(true)
	if saved.get("built_once", {}) is Dictionary: built_once = saved.get("built_once", {}).duplicate(true)
	var offline_seconds := maxf(0.0, Time.get_unix_time_from_system() - float(saved.get("saved_at", Time.get_unix_time_from_system())))
	rest_left = maxf(0.0, rest_left - offline_seconds)
	rest_cooldown = maxf(0.0, rest_cooldown - offline_seconds)
	while farm_left > 0.0 and offline_seconds > 0.0:
		if offline_seconds < farm_left:
			farm_left -= offline_seconds
			break
		offline_seconds -= farm_left
		farm_state = "growing" if farm_state == "sprout" else "ready"
		farm_left = 30.0 if farm_state == "growing" else 0.0
	for id in states:
		if states[id] == "completed": built_once[id] = true

func _save_village_state() -> void:
	var player := _player()
	if player == null or player.rabbit_data == null:
		return
	player.rabbit_data.village_a_state = {"states": states, "placements": placements, "carrots": carrots, "farm_state": farm_state, "farm_left": farm_left, "c_farm_cycle_id": c_farm_cycle_id, "c_harvest_serial": c_harvest_serial, "c_construction_record_ids": c_construction_record_ids, "c_construction_started_at": c_construction_started_at, "c_rest_use_id": c_rest_use_id, "c_rest_started_at": c_rest_started_at, "c_rest_use_count": c_rest_use_count, "rest_left": rest_left, "rest_cooldown": rest_cooldown, "construction_end": construction_end, "built_once": built_once, "saved_at": Time.get_unix_time_from_system()}
	player.save_now()

func _create_layers() -> void:
	slot_layer = CanvasLayer.new()
	slot_layer.name = "Week4SlotLayer"
	slot_layer.layer = 15
	add_child(slot_layer)
	modal_layer = CanvasLayer.new()
	modal_layer.name = "Week4ModalLayer"
	modal_layer.layer = 40
	add_child(modal_layer)

func _create_toolbar() -> void:
	var toggle := Button.new()
	toggle.text = "🏗  村莊建築"
	toggle.position = Vector2(1390, 48)
	toggle.size = Vector2(240, 58)
	toggle.add_theme_font_size_override("font_size", 19)
	toggle.pressed.connect(_toggle_build_mode)
	slot_layer.add_child(toggle)
	toolbar = PanelContainer.new()
	toolbar.position = Vector2(330, 885)
	toolbar.size = Vector2(1260, 165)
	toolbar.add_theme_stylebox_override("panel", _panel(Color("#fff9e9ee"), Color("#9b7650")))
	slot_layer.add_child(toolbar)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	toolbar.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	hint = Label.new()
	hint.text = "選擇建築後，再點擊發亮的空地。"
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("#574b3b"))
	box.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	for id in ["coffee_shop", "rest_pavilion", "notice_board", "carrot_farm"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(230, 86)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_select_building.bind(id))
		row.add_child(button)
		card_buttons[id] = button
	var test := Button.new()
	test.text = "測試：解鎖全部"
	test.custom_minimum_size = Vector2(180, 86)
	test.pressed.connect(_unlock_test_buildings)
	row.add_child(test)

func _toggle_build_mode() -> void:
	build_mode = not build_mode
	if not build_mode:
		selected_id = ""
	_refresh_all()

func _create_carrot_counter() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(48, 120)
	panel.size = Vector2(190, 55)
	panel.add_theme_stylebox_override("panel", _panel(Color("#fff9e9e8"), Color("#b48b4f")))
	slot_layer.add_child(panel)
	carrot_label = Label.new()
	carrot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carrot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	carrot_label.add_theme_font_size_override("font_size", 20)
	carrot_label.add_theme_color_override("font_color", Color("#684626"))
	panel.add_child(carrot_label)

func _create_construction_status() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(710, 52)
	panel.size = Vector2(500, 62)
	panel.add_theme_stylebox_override("panel", _panel(Color("#fff8e9ee"), Color("#b48b4f")))
	slot_layer.add_child(panel)
	construction_status_label = Label.new()
	construction_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	construction_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	construction_status_label.add_theme_font_size_override("font_size", 19)
	construction_status_label.add_theme_color_override("font_color", Color("#674927"))
	panel.add_child(construction_status_label)
	panel.hide()
	panel.name = "ConstructionStatus"

func _unlock_test_buildings() -> void:
	states.notice_board = "available"
	states.carrot_farm = "available"
	hint.text = "測試用：公告欄與胡蘿蔔農田已解鎖。"
	_record_c_village_event("village_notice_board_001")
	_record_c_village_event("village_small_farm_001")
	_save_village_state()
	_refresh_all()

func _select_building(id: String) -> void:
	if states[id] == "locked":
		_show_message("尚未解鎖", "這棟建築會在後續村莊進度解鎖。\n現在先用「測試：解鎖全部」查看 A 的介面。")
		return
	if id == "coffee_shop" and states[id] == "completed":
		_confirm_reclaim_coffee()
		return
	if states[id] == "completed" or states[id] == "constructing":
		_confirm_reclaim_building(id)
		return
	selected_id = id
	build_mode = true
	hint.text = "已選擇%s，請點擊一塊發亮空地。" % _title(id)
	_refresh_all()

func _refresh_all() -> void:
	if carrot_label != null:
		carrot_label.text = "🥕 胡蘿蔔：%d" % carrots
	if toolbar != null:
		toolbar.visible = build_mode
	for id in card_buttons:
		var b: Button = card_buttons[id]
		var state: String = states[id]
		b.text = _building_card_text(id, state)
		b.disabled = false
		if state == "locked":
			b.modulate = Color("#a9a39a")
		else:
			b.modulate = Color.WHITE
	_refresh_slots()
	_refresh_visuals()

func _building_card_text(id: String, state: String) -> String:
	if state == "locked":
		return "%s\n🔒 尚未解鎖" % _title(id)
	if state == "constructing":
		return "%s ×0\n施工中・點擊取消" % _title(id)
	if state == "completed":
		return "%s ×0\n點擊收回" % _title(id)
	return "%s ×1\n可建造" % _title(id)

func _occupied_slot_indices() -> Array[int]:
	var occupied: Array[int] = []
	for index in placements.values():
		occupied.append(int(index))
	var legacy := get_parent().get_node_or_null("BuildingSystem")
	if legacy != null:
		for key in legacy.placed_buildings.keys():
			occupied.append(int(key))
	return occupied

func _refresh_slots() -> void:
	for child in slot_layer.get_children():
		if child.name.begins_with("BuildSlot"):
			child.queue_free()
	if not build_mode or selected_id.is_empty():
		return
	var occupied := _occupied_slot_indices()
	for index in SLOT_POSITIONS.size():
		if occupied.has(index):
			continue
		var b := Button.new()
		b.name = "BuildSlot%d" % index
		b.text = "+" if not selected_id.is_empty() else ""
		b.position = SLOT_POSITIONS[index]
		b.size = Vector2(180, 120)
		b.flat = true
		b.add_theme_font_size_override("font_size", 52)
		b.add_theme_color_override("font_color", Color("#fff9c9"))
		b.add_theme_stylebox_override("normal", _slot_style())
		b.pressed.connect(_on_slot.bind(index))
		slot_layer.add_child(b)

func _on_slot(index: int) -> void:
	if selected_id.is_empty():
		return
	var building_id := selected_id
	var detail := "會直接放回原位，不需要施工。" if built_once.get(building_id, false) else "施工測試時間：30 秒"
	_show_confirm("確認建造", "要在這塊空地建造%s嗎？\n\n%s" % [_title(building_id), detail], func(): _finish_build_at_slot(building_id, index))

func _finish_build_at_slot(building_id: String, index: int) -> void:
	if building_id == "coffee_shop":
		_place_coffee(index)
		return
	placements[building_id] = index
	selected_id = ""
	build_mode = false
	if built_once.get(building_id, false):
		states[building_id] = "completed"
		hint.text = "%s已放回原位，不需要再次施工。" % _title(building_id)
		_save_village_state()
		_refresh_all()
		return
	states[building_id] = "constructing"
	construction_end[building_id] = Time.get_unix_time_from_system() + 30.0
	_record_c_construction_start(building_id, index)
	hint.text = "施工開始！目前顯示施工中外觀。"
	_save_village_state()
	_refresh_all()
	_show_message("施工開始", "%s正在施工中。" % _title(building_id))

func _place_coffee(index: int) -> void:
	var legacy := get_parent().get_node_or_null("BuildingSystem")
	if legacy != null:
		legacy.placed_buildings[str(index)] = "coffee_shop"
		legacy._save_buildings()
		legacy._refresh_slots()
	selected_id = ""
	build_mode = false
	_sync_coffee_state()
	hint.text = "咖啡廳已建造，庫存變為 ×0。"
	_refresh_all()

func _confirm_reclaim_coffee() -> void:
	_show_confirm("收回咖啡廳", "要收回咖啡廳嗎？\n收回後庫存會恢復為 ×1。", func(): _reclaim_coffee())

func _reclaim_coffee() -> void:
	var legacy := get_parent().get_node_or_null("BuildingSystem")
	if legacy != null:
		for key in legacy.placed_buildings.keys():
			if legacy.placed_buildings[key] == "coffee_shop":
				legacy.placed_buildings.erase(key)
		legacy._save_buildings()
		legacy._refresh_slots()
	_sync_coffee_state()
	hint.text = "咖啡廳已收回，庫存恢復為 ×1。"
	_refresh_all()

func _confirm_reclaim_building(id: String) -> void:
	var action := "取消施工" if states[id] == "constructing" else "收回建築"
	_show_confirm(action, "要%s嗎？\n%s的數量會恢復為 ×1。" % [action, _title(id)], func(): _reclaim_building(id))

func _reclaim_building(id: String) -> void:
	placements.erase(id)
	construction_end.erase(id)
	states[id] = "available"
	selected_id = ""
	hint.text = "%s已收回，數量恢復為 ×1。" % _title(id)
	_save_village_state()
	_refresh_all()

func _last_constructing_id() -> String:
	for id in states:
		if states[id] == "constructing":
			return id
	return ""

func _refresh_visuals() -> void:
	if visual_root == null:
		return
	for child in visual_root.get_children():
		child.queue_free()
	for id in placements:
		_add_building_visual(id, int(placements[id]))
	# 施工完成時間由 construction_end 與主存檔管理。

func _add_building_visual(id: String, index: int) -> void:
	var root := Node2D.new()
	root.position = SLOT_POSITIONS[index] + Vector2(90, 60)
	root.name = id
	visual_root.add_child(root)
	var image := Sprite2D.new()
	image.texture = _texture_for(id)
	image.scale = Vector2(0.205, 0.205)
	if id == "carrot_farm":
		if farm_state == "sprout":
			image.scale = Vector2(0.16, 0.16)
			image.modulate = Color("#a7c98e")
		elif farm_state == "growing":
			image.scale = Vector2(0.185, 0.185)
			image.modulate = Color("#d6df91")
	root.add_child(image)
	var click := Button.new()
	click.position = Vector2(-90, -60)
	click.size = Vector2(180, 120)
	click.flat = true
	click.tooltip_text = _title(id)
	click.pressed.connect(_open_building.bind(id))
	root.add_child(click)
	var tag := Label.new()
	tag.position = Vector2(-85, 43)
	tag.size = Vector2(170, 40)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 17)
	tag.add_theme_color_override("font_color", Color.WHITE)
	tag.add_theme_color_override("font_shadow_color", Color("#4a3724"))
	tag.add_theme_constant_override("shadow_offset_x", 2)
	tag.add_theme_constant_override("shadow_offset_y", 2)
	tag.text = _construction_label(id) if states[id] == "constructing" else ("農田：" + {"sprout":"嫩芽","growing":"成長中","ready":"可收成"}.get(farm_state, "")) if id == "carrot_farm" else _title(id)
	root.add_child(tag)

func _construction_label(id: String) -> String:
	var remaining := ceili(maxf(0.0, float(construction_end.get(id, 0.0)) - Time.get_unix_time_from_system()))
	return "施工中（%d 秒）" % remaining

func _open_building(id: String) -> void:
	if states[id] == "constructing":
		_show_message("施工中", "%s尚在施工中，完成後就能使用。" % _title(id))
	elif id == "coffee_shop":
		_show_message("咖啡廳", "咖啡廳已併入村莊建築清單。\n目前保留既有建築與位置；後續功能會再接入。")
	elif id == "rest_pavilion":
		_open_rest_popup()
	elif id == "notice_board":
		_open_notice_popup()
	elif id == "carrot_farm":
		_open_farm_popup()

func _open_rest_popup() -> void:
	var text := "Amy 可以在這裡稍作休息。\n\n效果（A 階段假資料）\n心情 +8　體力 +3　親密度 +1\n\n休息 %s" % ("進行中：%.0f 秒" % rest_left if rest_left > 0 else ("冷卻中：%.0f 秒" % rest_cooldown if rest_cooldown > 0 else "可使用"))
	_show_actions("小休息亭", text, "休息 30 秒", func():
		if rest_left > 0 or rest_cooldown > 0:
			_show_message("目前不能休息", "請等待休息或冷卻結束。")
		else:
			rest_left = 30.0
			rest_cooldown = 60.0
			_begin_c_rest_use()
			_save_village_state()
			_show_rest_lock()
			_show_message("開始休息", "Amy 正在小休息亭休息 30 秒。\n正式數值結算會在 B 接入。")
	, "取消", func(): pass)

func _show_rest_lock() -> void:
	# 休息不再鎖住地圖操作。
	pass

func _close_rest_lock() -> void:
	var lock := modal_layer.get_node_or_null("RestLock")
	if lock != null:
		lock.queue_free()

func _finish_rest() -> void:
	var player := get_parent().get_node_or_null("Background/Player")
	if player == null or player.rabbit_data == null:
		return
	player.rabbit_data.mood += 8
	player.rabbit_data.energy += 3
	player.rabbit_data.intimacy += 1
	player.rabbit_status_changed.emit(player.rabbit_data)
	_record_c_rest_complete()
	_close_rest_lock()
	_save_village_state()
	player.save_now()
	_show_message("休息完成", "Amy 休息得很好！\n心情 +8　體力 +3　親密度 +1")

func _refresh_rest_hint() -> void:
	if rest_left > 0.0:
		hint.text = "Amy 正在小休息亭休息：%.0f 秒" % rest_left

func _open_notice_popup() -> void:
	var player := _player()
	if player == null:
		_show_message("村莊公告欄", "公告資料暫時無法讀取。")
		return
	var notice := player.GetTodayNotice()
	if notice == null:
		_show_message("村莊公告欄", "今天的公告暫時無法產生，請稍後再試。")
		return
	var read_state := "已讀" if notice.is_read else "未讀"
	var first_read_text := _format_notice_time(notice.first_read_at) if notice.is_read and notice.first_read_at > 0.0 else "尚未閱讀"
	var body := "📌 今日公告\n\n%s\n\n日期：%s\n狀態：%s\n第一次閱讀：%s" % [
		notice.content,
		notice.date_key,
		read_state,
		first_read_text
	]
	var primary_text := "關閉" if notice.is_read else "知道了"
	var primary_action: Callable = func() -> void: _mark_today_notice_read(notice)
	var history_action := Callable(self, "_open_notice_history")
	_show_actions("村莊公告欄", body, primary_text, primary_action, "公告歷史", history_action)

func _mark_today_notice_read(notice: DailyNoticeRecord) -> void:
	var player := _player()
	if player == null or notice == null or notice.is_read:
		return
	# Prefer the formal C NoticeManager path. A's temporary building state can be
	# ahead of B's BuildingManager, so keep a safe persistence fallback.
	if player.MarkTodayNoticeRead():
		player.save_now()
		return
	notice.is_read = true
	notice.first_read_at = TimeManager.get_now()
	if player.SaveTodayNotice(notice):
		# The formal signal path normally creates this journal. The fallback needs
		# to do it explicitly, while DiaryManager still protects against duplicates.
		player.diary_manager.generate_notice_journal(notice, player.rabbit_data.rabbit_name, player.GetVillageLevel())
		player.save_now()

func _open_notice_history() -> void:
	var player := _player()
	if player == null:
		_show_message("公告歷史", "公告歷史暫時無法讀取。")
		return
	var history: Array[Dictionary] = []
	for raw: Variant in player.GetNoticeHistory():
		if raw is Dictionary:
			history.append(raw.duplicate(true))
	if history.is_empty():
		_show_actions("公告歷史", "目前還沒有公告歷史。", "返回今日公告", func(): _open_notice_popup(), "關閉", func(): pass)
		return
	history.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("generated_at", 0.0)) > float(b.get("generated_at", 0.0))
	)
	var lines: Array[String] = []
	var shown := mini(history.size(), 5)
	for i in shown:
		var raw := history[i]
		var date_key := str(raw.get("date_key", raw.get("notice_date", "")))
		var content := str(raw.get("content", ""))
		var is_read := bool(raw.get("is_read", false))
		var first_read_at := float(raw.get("first_read_at", 0.0))
		var status := "已讀" if is_read else "未讀"
		var first_read := _format_notice_time(first_read_at) if is_read and first_read_at > 0.0 else "—"
		lines.append("%s　[%s]\n%s\n首次閱讀：%s" % [date_key, status, content, first_read])
	var body := "最近 %d 則公告\n\n%s" % [shown, "\n\n".join(lines)]
	_show_actions("公告歷史", body, "返回今日公告", func(): _open_notice_popup(), "關閉", func(): pass)

func _format_notice_time(unix_time: float) -> String:
	if unix_time <= 0.0:
		return "—"
	var d := Time.get_datetime_dict_from_unix_time(int(unix_time))
	return "%04d/%02d/%02d %02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute]

func _slot_id_from_index(index: int) -> String:
	return "Slot%02d" % clampi(index + 1, 1, 9)

func _record_c_village_event(event_id: String) -> void:
	var player := _player()
	if player == null or event_id.is_empty():
		return
	var changed := false
	var entry := player.GenerateVillageEventJournal(event_id)
	if entry != null:
		changed = true
	if player.village_data != null and not player.village_data.completed_village_event_ids.has(event_id):
		player.village_data.completed_village_event_ids.append(event_id)
		player.village_data.progress.completed_village_event_count += 1
		changed = true
	if changed:
		player.rabbit_data.village_data = player.village_data.to_dict()
		player.save_now()

func _backfill_c_village_event_journals() -> void:
	var player := _player()
	if player == null:
		return
	# Existing A-side saves can already have buildings unlocked/completed without the C event journal.
	var event_by_building := {
		"rest_pavilion": "village_rest_pavilion_001",
		"notice_board": "village_notice_board_001",
		"carrot_farm": "village_small_farm_001"
	}
	for building_id: String in event_by_building.keys():
		var state := str(states.get(building_id, "locked"))
		var was_built := bool(built_once.get(building_id, false))
		# Do not create the rest-pavilion event merely because a fresh game starts with it available.
		# Completed/constructing buildings are safe evidence that the unlock event has already happened.
		if was_built or state == "completed" or state == "constructing":
			_record_c_village_event(str(event_by_building[building_id]))

func _ensure_c_construction_id(building_id: String) -> String:
	var existing := str(c_construction_record_ids.get(building_id, ""))
	if not existing.is_empty():
		return existing
	var record_id := "a_construction_%s_%d_%d" % [building_id, int(TimeManager.get_now() * 1000.0), randi_range(1000, 9999)]
	c_construction_record_ids[building_id] = record_id
	return record_id

func _record_c_construction_start(building_id: String, slot_index: int) -> void:
	var player := _player()
	if player == null:
		return
	var record_id := _ensure_c_construction_id(building_id)
	var started_at := TimeManager.get_now()
	c_construction_started_at[building_id] = started_at
	var record := ConstructionRecord.new()
	record.construction_record_id = record_id
	record.building_id = building_id
	record.slot_id = _slot_id_from_index(slot_index)
	record.started_at = started_at
	record.ends_at = float(construction_end.get(building_id, started_at + 30.0))
	player.diary_manager.generate_construction_start_journal(record, player.rabbit_data.rabbit_name, player.GetVillageLevel())
	var history := ConstructionHistoryEntry.new()
	history.construction_record_id = record_id
	history.building_id = building_id
	history.slot_id = record.slot_id
	history.started_at = started_at
	player.AddConstructionHistory(history)
	player.village_history_manager.mark_building_placed(building_id, record.slot_id, started_at)
	player.village_history_manager.mark_building_construction_started(building_id, record.slot_id, started_at)
	player.save_now()

func _record_c_construction_complete(building_id: String) -> void:
	var player := _player()
	if player == null:
		return
	var record_id := _ensure_c_construction_id(building_id)
	var now := TimeManager.get_now()
	var started_at := maxf(0.0, float(c_construction_started_at.get(building_id, now)))
	var slot_index := int(placements.get(building_id, 0))
	# If this patch was applied while a building was already constructing, create the missing start entry first.
	var start_record := ConstructionRecord.new()
	start_record.construction_record_id = record_id
	start_record.building_id = building_id
	start_record.slot_id = _slot_id_from_index(slot_index)
	start_record.started_at = started_at
	start_record.ends_at = now
	player.diary_manager.generate_construction_start_journal(start_record, player.rabbit_data.rabbit_name, player.GetVillageLevel())
	var result := ConstructionResult.new()
	result.construction_record_id = record_id
	result.building_id = building_id
	result.slot_id = start_record.slot_id
	result.started_at = started_at
	result.completed_at = now
	result.is_first_completion = true
	player.GenerateConstructionJournal(result)
	if not player.village_history_manager.update_construction_completed(record_id, now):
		var history := ConstructionHistoryEntry.new()
		history.construction_record_id = record_id
		history.building_id = building_id
		history.slot_id = result.slot_id
		history.started_at = started_at
		history.completed_at = now
		player.AddConstructionHistory(history)
	player.village_history_manager.mark_building_completed(building_id, result.slot_id, now)
	player.save_now()

func _backfill_c_building_journals() -> void:
	var player := _player()
	if player == null:
		return
	var changed := false
	for building_id in ["rest_pavilion", "notice_board", "carrot_farm"]:
		if not bool(built_once.get(building_id, false)):
			continue
		var record_id := _ensure_c_construction_id(building_id)
		var now := TimeManager.get_now()
		var started_at := maxf(0.0, float(c_construction_started_at.get(building_id, now)))
		c_construction_started_at[building_id] = started_at
		var slot_index := int(placements.get(building_id, 0))
		var record := ConstructionRecord.new()
		record.construction_record_id = record_id
		record.building_id = building_id
		record.slot_id = _slot_id_from_index(slot_index)
		record.started_at = started_at
		record.ends_at = now
		var start_entry := player.diary_manager.generate_construction_start_journal(record, player.rabbit_data.rabbit_name, player.GetVillageLevel())
		var result := ConstructionResult.new()
		result.construction_record_id = record_id
		result.building_id = building_id
		result.slot_id = record.slot_id
		result.started_at = started_at
		result.completed_at = now
		result.is_first_completion = true
		var complete_entry := player.GenerateConstructionJournal(result)
		if start_entry != null or complete_entry != null:
			changed = true
		var history := ConstructionHistoryEntry.new()
		history.construction_record_id = record_id
		history.building_id = building_id
		history.slot_id = record.slot_id
		history.started_at = started_at
		history.completed_at = now
		player.AddConstructionHistory(history)
		player.village_history_manager.update_construction_completed(record_id, now)
		player.village_history_manager.mark_building_completed(building_id, record.slot_id, now)
	if changed:
		_save_village_state()

func _begin_c_rest_use() -> void:
	if not c_rest_use_id.is_empty():
		return
	c_rest_started_at = TimeManager.get_now()
	c_rest_use_id = "a_building_use_rest_%d_%d" % [int(c_rest_started_at * 1000.0), randi_range(1000, 9999)]

func _record_c_rest_complete() -> void:
	var player := _player()
	if player == null:
		return
	if c_rest_use_id.is_empty():
		_begin_c_rest_use()
	var now := TimeManager.get_now()
	c_rest_use_count += 1
	var result := BuildingUseResult.new()
	result.building_use_record_id = c_rest_use_id
	result.interaction_record_id = c_rest_use_id
	result.building_id = "rest_pavilion"
	result.started_at = c_rest_started_at if c_rest_started_at > 0.0 else now
	result.completed_at = now
	result.energy_change = 3
	result.mood_change = 8
	result.intimacy_change = 1
	result.use_count = c_rest_use_count
	var has_prior_use := false
	for journal: JournalEntry in player.diary_manager.get_all_journals():
		if journal.journal_type == "building_use" and journal.building_id == "rest_pavilion":
			has_prior_use = true
			break
	result.is_first_use = not has_prior_use
	player.GenerateBuildingUseJournal(result)
	var history := BuildingUseHistoryEntry.new()
	history.building_use_record_id = result.building_use_record_id
	history.building_id = result.building_id
	history.started_at = result.started_at
	history.completed_at = result.completed_at
	history.use_count = result.use_count
	player.AddBuildingUseHistory(history)
	player.village_history_manager.mark_building_used(result.building_id, result.completed_at, result.use_count)
	c_rest_use_id = ""
	c_rest_started_at = 0.0
	player.save_now()

func _open_farm_popup() -> void:
	var status: String = str({"sprout":"剛種下的嫩芽","growing":"正在成長中","ready":"已成熟，可以收成"}.get(farm_state, ""))
	_show_actions("固定胡蘿蔔農田", "農田狀態：%s\n\n%s\n\n目前胡蘿蔔：%d" % [status, "成熟胡蘿蔔閃著橘色光澤。" if farm_state == "ready" else "請等它慢慢長大。", carrots], "收成" if farm_state == "ready" else "知道了", func():
		if farm_state == "ready":
			_record_c_harvest(10)
			carrots += 10
			farm_state = "sprout"
			farm_left = 30.0
			_start_c_farm_cycle_for_next_round()
			_save_village_state()
			_refresh_all()
			_show_village_event("村莊事件：胡蘿蔔收成", "Amy 把剛成熟的胡蘿蔔收進籃子。\n\n獲得胡蘿蔔 ×10！\n收成故事已收進 Amy 的日記。")
	, "關閉", func(): pass)

func _ensure_c_farm_cycle_id() -> String:
	if not c_farm_cycle_id.is_empty():
		return c_farm_cycle_id
	c_farm_cycle_id = "a_farm_%d_%d" % [int(TimeManager.get_now() * 1000.0), randi_range(1000, 9999)]
	return c_farm_cycle_id

func _record_c_harvest(amount: int) -> void:
	var player := _player()
	if player == null:
		return
	var now := TimeManager.get_now()
	var result := HarvestResult.new()
	result.farm_cycle_id = _ensure_c_farm_cycle_id()
	c_harvest_serial += 1
	result.harvest_record_id = "a_harvest_%s_%03d" % [result.farm_cycle_id, c_harvest_serial]
	result.amount = maxi(0, amount)
	result.harvested_at = now
	var has_harvest_journal := false
	for journal: JournalEntry in player.diary_manager.get_all_journals():
		if journal.journal_type == "harvest":
			has_harvest_journal = true
			break
	result.is_first_harvest = not has_harvest_journal
	# Use C's public diary generator; duplicate checks remain inside DiaryManager.
	player.GenerateHarvestJournal(result)
	# Also save the fourth-week harvest/farm/inventory history.
	var harvest_history := HarvestHistoryEntry.new()
	harvest_history.harvest_record_id = result.harvest_record_id
	harvest_history.farm_cycle_id = result.farm_cycle_id
	harvest_history.harvested_at = result.harvested_at
	harvest_history.harvest_amount = result.amount
	harvest_history.is_first_harvest = result.is_first_harvest
	player.AddHarvestHistory(harvest_history)
	player.village_history_manager.mark_farm_cycle_harvested(result.farm_cycle_id, result.harvested_at, result.amount)
	player.village_history_manager.add_carrots(result.amount, result.harvested_at)
	player.save_now()

func _start_c_farm_cycle_for_next_round() -> void:
	var player := _player()
	if player == null:
		return
	var now := TimeManager.get_now()
	c_farm_cycle_id = "a_farm_%d_%d" % [int(now * 1000.0), randi_range(1000, 9999)]
	var cycle := FarmCycleData.new()
	cycle.farm_cycle_id = c_farm_cycle_id
	cycle.started_at = now
	# A's visual farm currently uses two 30-second phases.
	cycle.ready_at = now + 60.0
	player.GenerateFarmGrowthJournal(cycle)
	var farm_history := FarmCycleHistoryEntry.new()
	farm_history.farm_cycle_id = cycle.farm_cycle_id
	farm_history.started_at = cycle.started_at
	farm_history.ready_at = cycle.ready_at
	player.AddFarmCycleHistory(farm_history)

func _show_message(title: String, body: String) -> void:
	_show_actions(title, body, "知道了", func(): pass, "", func(): pass)

func _show_confirm(title: String, body: String, confirmed: Callable) -> void:
	_show_actions(title, body, "確認", confirmed, "取消", func(): pass)

func _show_actions(title: String, body: String, primary: String, primary_action: Callable, secondary: String, secondary_action: Callable) -> void:
	_close_modal()
	var veil := ColorRect.new()
	veil.name = "Week4Modal"
	veil.color = Color(0,0,0,0.52)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.add_child(veil)
	var panel := PanelContainer.new()
	panel.position = Vector2(600, 280)
	panel.size = Vector2(720, 430)
	panel.add_theme_stylebox_override("panel", _panel(Color("#fff8e9"), Color("#9d7447")))
	veil.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	margin.add_child(box)
	var headline := Label.new()
	headline.text = title
	headline.add_theme_font_size_override("font_size", 30)
	headline.add_theme_color_override("font_color", Color("#58402b"))
	box.add_child(headline)
	if title.begins_with("村莊事件"):
		var event_image := TextureRect.new()
		event_image.texture = PAVILION_TEXTURE
		event_image.custom_minimum_size = Vector2(0, 110)
		event_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		event_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		event_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(event_image)
	var message := Label.new()
	message.text = body
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message.add_theme_font_size_override("font_size", 21)
	message.add_theme_color_override("font_color", Color("#4d4337"))
	box.add_child(message)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	if not secondary.is_empty():
		var second := Button.new()
		second.text = secondary
		second.custom_minimum_size = Vector2(170, 55)
		second.pressed.connect(_on_modal_button.bind(veil, secondary_action))
		row.add_child(second)
	var first := Button.new()
	first.text = primary
	first.custom_minimum_size = Vector2(190, 55)
	first.pressed.connect(_on_modal_button.bind(veil, primary_action))
	row.add_child(first)

func _on_modal_button(veil: Control, action: Callable) -> void:
	veil.queue_free()
	action.call_deferred()

func _close_modal() -> void:
	var modal := modal_layer.get_node_or_null("Week4Modal")
	if modal != null:
		modal.queue_free()

func _title(id: String) -> String:
	return {"coffee_shop":"咖啡廳","rest_pavilion":"小休息亭","notice_board":"公告欄","carrot_farm":"固定胡蘿蔔農田"}.get(id, id)

func _state_text(state: String) -> String:
	return {"locked":"🔒 尚未解鎖","available":"可建造","constructing":"施工中","completed":"已完成"}.get(state, state)

func _texture_for(id: String) -> Texture2D:
	return {"coffee_shop":COFFEE_TEXTURE,"rest_pavilion":PAVILION_TEXTURE,"notice_board":BOARD_TEXTURE,"carrot_farm":FARM_TEXTURE}.get(id, PAVILION_TEXTURE)

func _panel(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0,0,0,0.28)
	style.shadow_size = 12
	return style

func _slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0,0.9,0.35,0.24)
	style.border_color = Color("#f6d45f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(26)
	return style
