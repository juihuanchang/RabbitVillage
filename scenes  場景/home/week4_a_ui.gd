extends Node

const PAVILION_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/rest_pavilion.png")
const BOARD_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/notice_board.png")
const FARM_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/carrot_farm.png")
const COFFEE_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/coffee_shop.png")
const BUILDING_IDS := ["coffee_shop", "rest_pavilion", "notice_board", "carrot_farm"]
const BUILDING_TITLES := {
	"coffee_shop": "咖啡廳",
	"rest_pavilion": "小休息亭",
	"notice_board": "公告欄",
	"carrot_farm": "固定胡蘿蔔農田"
}
const LEGACY_FARM_SPROUT := "sprout"

var states := {
	"coffee_shop": BuildingState.AVAILABLE,
	"rest_pavilion": BuildingState.AVAILABLE,
	"notice_board": BuildingState.LOCKED,
	"carrot_farm": BuildingState.LOCKED
}
var placements: Dictionary = {}
var selected_id := ""
var build_mode := true
var carrots := 0
var rest_left := 0.0
var rest_cooldown := 0.0
var farm_state := FarmState.LOCKED
var farm_left := 0.0
# Legacy construction ids are retained only while importing old A saves.
var c_construction_record_ids: Dictionary = {}
var c_construction_started_at: Dictionary = {}
var construction_end: Dictionary = {}
var built_once: Dictionary = {}
var _last_construction_second := -1
var toolbar: PanelContainer
var carrot_label: Label
var construction_status_label: Label
var hint: Label
var slot_layer: CanvasLayer
var modal_layer: CanvasLayer
var card_buttons: Dictionary = {}
var visual_root: Node2D
var slot_positions: Array[Vector2] = []

func _ready() -> void:
	_load_slot_positions()
	_load_village_state()
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
	if rest_left <= 0.0:
		call_deferred("_show_first_village_event")


func _load_slot_positions() -> void:
	var slot_root := get_parent().get_node_or_null("Week4BuildSlots")
	if slot_root == null:
		push_error("HomePage 缺少 Week4BuildSlots 節點")
		return
	for marker: Node in slot_root.get_children():
		if marker is Marker2D:
			slot_positions.append(marker.position)

func _show_village_event(title := "村莊事件：新的生活開始", story := "Amy 發現村裡多了幾個能停下腳步的地方。\n\n小休息亭已可建造；公告欄與胡蘿蔔農田會隨村莊進度解鎖。") -> void:
	_show_actions(title, story, "去看看", func(): pass, "稍後再看", func(): pass)

func _show_first_village_event() -> void:
	var player := _player()
	if player != null and player.has_journal_for_village_event("village_rest_pavilion_001"):
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
	var formal_player := _player()
	if formal_player != null and formal_player.has_active_construction():
		var formal_record := formal_player.get_active_construction()
		if formal_record != null:
			states[formal_record.building_id] = BuildingState.CONSTRUCTING
			construction_end[formal_record.building_id] = formal_record.ends_at
	for building_id in construction_end.keys():
		if now >= float(construction_end[building_id]):
			# Formal constructions are completed by ConstructionManager. Older A-only
			# saves retain their existing completion path during migration.
			if formal_player != null and formal_player.get_building_state(str(building_id)) == BuildingState.CONSTRUCTING:
				continue
			states[building_id] = BuildingState.COMPLETED; built_once[building_id] = true
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
		construction_status_label.get_parent().visible = remaining_second > 0
		if remaining_second > 0:
			construction_status_label.text = "🏗 施工中：剩餘 %d 秒" % remaining_second
	var player := _player()
	if player != null:
		var previous_rest := rest_left
		rest_left = player.get_rest_pavilion_use_remaining()
		rest_cooldown = player.get_rest_pavilion_cooldown_remaining()
		if previous_rest > 0.0 and rest_left <= 0.0:
			_show_message("休息完成", "Amy 休息得很好！\n心情 +8　體力 +3　親密度 +1")
		_refresh_rest_hint()
	if player != null:
		var previous_farm_state := farm_state
		var previous_carrots := carrots
		farm_left = player.get_farm_remaining_seconds()
		if player.is_farm_ready():
			farm_state = FarmState.READY
		elif player.has_active_growth_cycle():
			farm_state = LEGACY_FARM_SPROUT if farm_left > 30.0 else FarmState.GROWING
		else:
			farm_state = player.get_farm_state()
		carrots = player.get_carrot_amount()
		if previous_farm_state != farm_state:
			_refresh_visuals()
		if previous_carrots != carrots and carrot_label != null:
			carrot_label.text = "🥕 胡蘿蔔：%d" % carrots

func _player() -> RabbitCharacter:
	return get_parent().get_node_or_null("Background/Player") as RabbitCharacter

func _load_village_state() -> void:
	var player := _player()
	if player == null or player.rabbit_data == null:
		return
	var saved: Dictionary = player.village_data.legacy_a_snapshot
	if not saved.is_empty():
		var imported := LegacySaveMigrator.import_week4_snapshot(player, saved)
		states = imported.states
		placements = imported.placements
		carrots = imported.carrots
		farm_state = imported.farm_state
		farm_left = imported.farm_left
		rest_left = imported.rest_left
		rest_cooldown = imported.rest_cooldown
		construction_end = imported.construction_end
		built_once = imported.built_once
		c_construction_record_ids = imported.c_construction_record_ids
		c_construction_started_at = imported.c_construction_started_at
	_sync_formal_buildings_to_view()

func _sync_formal_buildings_to_view() -> void:
	# B is authoritative for building quantity, placement and construction state.
	# The legacy snapshot remains available during the staged migration.
	var player := _player()
	if player == null or player.village_data == null:
		return
	for id in BUILDING_IDS:
		var formal_state := player.get_building_state(id)
		if formal_state == "invalid":
			continue
		states[id] = formal_state
		var raw_record: Dictionary = player.village_data.building_records.get(id, {})
		if raw_record.is_empty():
			placements.erase(id)
		else:
			var slot_id := str(raw_record.get("slot_id", ""))
			if slot_id.begins_with("Slot") and slot_id.length() >= 6:
				placements[id] = clampi(int(slot_id.trim_prefix("Slot")) - 1, 0, 8)
		if bool(player.village_data.building_interactions.get("completed_once:" + id, false)) or formal_state == BuildingState.COMPLETED:
			built_once[id] = true
	if player.has_active_construction():
		var active := player.get_active_construction()
		if active != null:
			construction_end[active.building_id] = active.ends_at

func _save_village_state() -> void:
	var player := _player()
	if player == null or player.rabbit_data == null:
		return
	# Old A snapshots are read above for migration, but new saves use formal B/C data only.
	player.village_data.legacy_a_snapshot = {}
	player.rabbit_data.village_data = player.village_data.to_dict()
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
	toolbar.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff9e9ee"), Color("#9b7650"), 22, 3, 12, Color(0, 0, 0, 0.28)))
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
	for id in BUILDING_IDS:
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
		_clear_build_slots()
	_refresh_all()

func _clear_build_slots() -> void:
	for child in slot_layer.get_children():
		if child.name.begins_with("BuildSlot"):
			child.hide()
			child.queue_free()

func _create_carrot_counter() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(48, 120)
	panel.size = Vector2(190, 55)
	panel.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff9e9e8"), Color("#b48b4f"), 22, 3, 12, Color(0, 0, 0, 0.28)))
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
	panel.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff8e9ee"), Color("#b48b4f"), 22, 3, 12, Color(0, 0, 0, 0.28)))
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
	states.notice_board = BuildingState.AVAILABLE
	states.carrot_farm = BuildingState.AVAILABLE
	hint.text = "測試用：公告欄與胡蘿蔔農田已解鎖。"
	_record_c_village_event("village_notice_board_001")
	_record_c_village_event("village_small_farm_001")
	_save_village_state()
	_refresh_all()

func _select_building(id: String) -> void:
	if states[id] == BuildingState.LOCKED:
		_show_message("尚未解鎖", "這棟建築會在後續村莊進度解鎖。\n現在先用「測試：解鎖全部」查看 A 的介面。")
		return
	if id == "coffee_shop" and states[id] == BuildingState.COMPLETED:
		_confirm_reclaim_coffee()
		return
	if states[id] == BuildingState.COMPLETED or states[id] == BuildingState.CONSTRUCTING:
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
		if state == BuildingState.LOCKED:
			b.modulate = Color("#a9a39a")
		else:
			b.modulate = Color.WHITE
	_refresh_slots()
	_refresh_visuals()

func _building_card_text(id: String, state: String) -> String:
	if state == BuildingState.LOCKED:
		return "%s\n🔒 尚未解鎖" % _title(id)
	if state == BuildingState.CONSTRUCTING:
		return "%s ×0\n施工中・點擊取消" % _title(id)
	if state == BuildingState.COMPLETED:
		return "%s ×0\n點擊收回" % _title(id)
	return "%s ×1\n可建造" % _title(id)

func _occupied_slot_indices() -> Array[int]:
	var occupied: Array[int] = []
	for index in placements.values():
		occupied.append(int(index))
	return occupied

func _refresh_slots() -> void:
	for child in slot_layer.get_children():
		if child.name.begins_with("BuildSlot"):
			child.queue_free()
	if not build_mode or selected_id.is_empty():
		return
	var occupied := _occupied_slot_indices()
	for index in slot_positions.size():
		if occupied.has(index):
			continue
		var b := Button.new()
		b.name = "BuildSlot%d" % index
		b.text = "+" if not selected_id.is_empty() else ""
		b.position = slot_positions[index]
		b.size = Vector2(180, 120)
		b.flat = true
		b.add_theme_font_size_override("font_size", 52)
		b.add_theme_color_override("font_color", Color("#fff9c9"))
		b.add_theme_stylebox_override("normal", UIStyleFactory.panel(Color(1.0, 0.9, 0.35, 0.24), Color("#f6d45f"), 26, 3))
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
	var player := _player()
	if player == null:
		return
	player.building_manager.unlock_building(building_id)
	var placed := player.place_building(building_id, _slot_id_from_index(index))
	if not bool(placed.get("ok", false)):
		hint.text = str(placed.get("reason", "Unable to place building"))
		return
	if not built_once.get(building_id, false):
		var started := player.start_construction(building_id)
		if not bool(started.get("ok", false)):
			player.reclaim_building(building_id)
			hint.text = str(started.get("reason", "Unable to start construction"))
			return
		construction_end[building_id] = player.get_construction_end_time()
	placements[building_id] = index
	selected_id = ""
	build_mode = false
	_refresh_slots()
	if built_once.get(building_id, false):
		states[building_id] = BuildingState.COMPLETED
		hint.text = "%s已放回原位，不需要再次施工。" % _title(building_id)
		_save_village_state()
		_refresh_all()
		return
	states[building_id] = BuildingState.CONSTRUCTING
	hint.text = "施工開始！目前顯示施工中外觀。"
	_save_village_state()
	_refresh_all()
	_show_message("施工開始", "%s正在施工中。" % _title(building_id))

func _place_coffee(index: int) -> void:
	var player := _player()
	if player == null:
		return
	var result := player.place_building("coffee_shop", _slot_id_from_index(index))
	if not bool(result.get("ok", false)):
		hint.text = str(result.get("reason", "無法放置咖啡廳"))
		return
	placements["coffee_shop"] = index
	states.coffee_shop = BuildingState.COMPLETED
	selected_id = ""
	build_mode = false
	hint.text = "咖啡廳已建造，庫存變為 ×0。"
	_save_village_state()
	_refresh_all()

func _confirm_reclaim_coffee() -> void:
	_show_confirm("收回咖啡廳", "要收回咖啡廳嗎？\n收回後庫存會恢復為 ×1。", func(): _reclaim_coffee())

func _reclaim_coffee() -> void:
	var player := _player()
	if player == null:
		return
	var result := player.reclaim_building("coffee_shop")
	if not bool(result.get("ok", false)):
		hint.text = str(result.get("reason", "無法收回咖啡廳"))
		return
	placements.erase("coffee_shop")
	states.coffee_shop = BuildingState.AVAILABLE
	hint.text = "咖啡廳已收回，庫存恢復為 ×1。"
	_save_village_state()
	_refresh_all()

func _confirm_reclaim_building(id: String) -> void:
	var action := "取消施工" if states[id] == BuildingState.CONSTRUCTING else "收回建築"
	_show_confirm(action, "要%s嗎？\n%s的數量會恢復為 ×1。" % [action, _title(id)], func(): _reclaim_building(id))

func _reclaim_building(id: String) -> void:
	var player := _player()
	if player == null:
		return
	var result: Dictionary
	if states[id] == BuildingState.CONSTRUCTING:
		result = player.cancel_construction()
	else:
		result = player.reclaim_building(id)
	if not bool(result.get("ok", false)):
		hint.text = str(result.get("reason", "Unable to reclaim building"))
		return
	placements.erase(id)
	construction_end.erase(id)
	states[id] = BuildingState.AVAILABLE
	selected_id = ""
	hint.text = "%s已收回，數量恢復為 ×1。" % _title(id)
	_save_village_state()
	_refresh_all()

func _refresh_visuals() -> void:
	if visual_root == null:
		return
	for child in visual_root.get_children():
		child.queue_free()
	for id in placements:
		_add_building_visual(id, int(placements[id]))
	# 施工完成時間由 construction_end 與主存檔管理。

func _add_building_visual(id: String, index: int) -> void:
	if index < 0 or index >= slot_positions.size():
		return
	var root := Node2D.new()
	root.position = slot_positions[index] + Vector2(90, 60)
	root.name = id
	visual_root.add_child(root)
	var image := Sprite2D.new()
	image.texture = _texture_for(id)
	# 咖啡廳原圖是 320×220，其他建築是 1254×1254；分開縮放才能維持相近的地圖尺寸。
	image.scale = Vector2(0.8, 0.8) if id == "coffee_shop" else Vector2(0.205, 0.205)
	if id == "carrot_farm":
		if farm_state == LEGACY_FARM_SPROUT:
			image.scale = Vector2(0.16, 0.16)
			image.modulate = Color("#a7c98e")
		elif farm_state == FarmState.GROWING:
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
	tag.text = _construction_label(id) if states[id] == BuildingState.CONSTRUCTING else ("農田：" + {LEGACY_FARM_SPROUT:"嫩芽",FarmState.GROWING:"成長中",FarmState.READY:"可收成"}.get(farm_state, "")) if id == "carrot_farm" else _title(id)
	root.add_child(tag)

func _construction_label(id: String) -> String:
	var remaining := ceili(maxf(0.0, float(construction_end.get(id, 0.0)) - Time.get_unix_time_from_system()))
	return "施工中（%d 秒）" % remaining

func _open_building(id: String) -> void:
	if states[id] == BuildingState.CONSTRUCTING:
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
	var text := "Amy 可以在這裡稍作休息。\n\n效果\n心情 +8　體力 +3　親密度 +1\n\n休息 %s" % ("進行中：%.0f 秒" % rest_left if rest_left > 0 else ("冷卻中：%.0f 秒" % rest_cooldown if rest_cooldown > 0 else "可使用"))
	_show_actions("小休息亭", text, "休息 30 秒", func():
		var player := _player()
		if player == null:
			return
		var result := player.start_rest_pavilion_use()
		if not bool(result.get("ok", false)):
			_show_message("目前不能休息", "請等待休息或冷卻結束。")
		else:
			rest_left = player.get_rest_pavilion_use_remaining()
			rest_cooldown = player.get_rest_pavilion_cooldown_remaining()
			_show_message("開始休息", "Amy 正在小休息亭休息 30 秒。")
	, "取消", func(): pass)

func _refresh_rest_hint() -> void:
	if rest_left > 0.0:
		hint.text = "Amy 正在小休息亭休息：%.0f 秒" % rest_left

func _open_notice_popup() -> void:
	var player := _player()
	if player == null:
		_show_message("村莊公告欄", "公告資料暫時無法讀取。")
		return
	var notice := player.get_today_notice()
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
	if player.mark_today_notice_read():
		player.save_now()
		return
	_show_message("無法標記公告", "公告欄尚未完成，或今天的公告已經讀過。")

func _open_notice_history() -> void:
	var player := _player()
	if player == null:
		_show_message("公告歷史", "公告歷史暫時無法讀取。")
		return
	var history: Array[Dictionary] = []
	for raw: Variant in player.get_notice_history():
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
	var d := TimeManager.get_local_datetime(unix_time)
	return "%04d/%02d/%02d %02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute]

func _slot_id_from_index(index: int) -> String:
	return "Slot%02d" % clampi(index + 1, 1, 9)

func _record_c_village_event(event_id: String) -> void:
	var player := _player()
	if player == null or event_id.is_empty():
		return
	var changed := false
	var entry := player.generate_village_event_journal(event_id)
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
		var state := str(states.get(building_id, BuildingState.LOCKED))
		var was_built := bool(built_once.get(building_id, false))
		# Do not create the rest-pavilion event merely because a fresh game starts with it available.
		# Completed/constructing buildings are safe evidence that the unlock event has already happened.
		if was_built or state == BuildingState.COMPLETED or state == BuildingState.CONSTRUCTING:
			_record_c_village_event(str(event_by_building[building_id]))

func _ensure_c_construction_id(building_id: String) -> String:
	var existing := str(c_construction_record_ids.get(building_id, ""))
	if not existing.is_empty():
		return existing
	var player := _player()
	if player != null and player.village_data != null:
		for raw: Variant in player.village_data.construction_records:
			if raw is Dictionary and str(raw.get("building_id", "")) == building_id:
				var formal_id := str(raw.get("construction_record_id", ""))
				if not formal_id.is_empty():
					c_construction_record_ids[building_id] = formal_id
					return formal_id
	var record_id := "legacy_construction_%s" % building_id
	c_construction_record_ids[building_id] = record_id
	return record_id

func _has_construction_journal_for_building(building_id: String) -> bool:
	var player := _player()
	if player == null:
		return false
	for journal: JournalEntry in player.diary_manager.get_all_journals():
		if journal.building_id == building_id and journal.journal_type in ["construction", "building_complete"]:
			return true
	return false

func _backfill_c_building_journals() -> void:
	var player := _player()
	if player == null:
		return
	var changed := false
	for building_id in ["rest_pavilion", "notice_board", "carrot_farm"]:
		if not bool(built_once.get(building_id, false)):
			continue
		if _has_construction_journal_for_building(building_id):
			continue
		var record_id := _ensure_c_construction_id(building_id)
		var now := TimeManager.get_now()
		var started_at := maxf(0.0, float(c_construction_started_at.get(building_id, now)))
		c_construction_started_at[building_id] = started_at
		var slot_index := int(placements.get(building_id, 0))
		player.adopt_completed_building(building_id, _slot_id_from_index(slot_index))
		if building_id == "carrot_farm": player.start_first_growth_cycle()
		var record := ConstructionRecord.new()
		record.construction_record_id = record_id
		record.building_id = building_id
		record.slot_id = _slot_id_from_index(slot_index)
		record.started_at = started_at
		record.ends_at = now
		var start_entry := player.diary_manager.generate_construction_start_journal(record, player.rabbit_data.rabbit_name, player.get_village_level())
		var result := ConstructionResult.new()
		result.construction_record_id = record_id
		result.building_id = building_id
		result.slot_id = record.slot_id
		result.started_at = started_at
		result.completed_at = now
		result.is_first_completion = true
		var complete_entry := player.generate_construction_journal(result)
		if start_entry != null or complete_entry != null:
			changed = true
		var history := ConstructionHistoryEntry.new()
		history.construction_record_id = record_id
		history.building_id = building_id
		history.slot_id = record.slot_id
		history.started_at = started_at
		history.completed_at = now
		player.add_construction_history(history)
		player.village_history_manager.update_construction_completed(record_id, now)
		player.village_history_manager.mark_building_completed(building_id, record.slot_id, now)
	if changed:
		_save_village_state()

func _open_farm_popup() -> void:
	var status: String = str({LEGACY_FARM_SPROUT:"剛種下的嫩芽",FarmState.GROWING:"正在成長中",FarmState.READY:"已成熟，可以收成"}.get(farm_state, ""))
	_show_actions("固定胡蘿蔔農田", "農田狀態：%s\n\n%s\n\n目前胡蘿蔔：%d" % [status, "成熟胡蘿蔔閃著橘色光澤。" if farm_state == FarmState.READY else "請等它慢慢長大。", carrots], "收成" if farm_state == FarmState.READY else "知道了", func():
		if farm_state == FarmState.READY:
			var player := _player()
			var result := player.harvest_carrots() if player != null else null
			if result != null:
				carrots = player.get_carrot_amount(); farm_state = LEGACY_FARM_SPROUT; farm_left = player.get_farm_remaining_seconds()
				_refresh_all()
				_show_village_event("村莊事件：胡蘿蔔收成", "Amy 把剛成熟的胡蘿蔔收進籃子。\n\n獲得胡蘿蔔 ×10！\n收成故事已收進 Amy 的日記。")
			else:
				_show_message("目前不能收成", "農田尚未成熟，請稍後再試。")
	, "關閉", func(): pass)

func _show_message(title: String, body: String) -> void:
	_show_actions(title, body, "知道了", func(): pass, "", func(): pass)

func _show_confirm(title: String, body: String, confirmed: Callable) -> void:
	_show_actions(title, body, "確認", confirmed, "取消", func(): pass)

func _show_actions(title: String, body: String, primary: String, primary_action: Callable, secondary: String, secondary_action: Callable) -> void:
	UIModalPresenter.show_actions(modal_layer, title, body, primary, primary_action, secondary, secondary_action, PAVILION_TEXTURE)

func _close_modal() -> void:
	UIModalPresenter.close(modal_layer)

func _title(id: String) -> String:
	return BUILDING_TITLES.get(id, id)

func _texture_for(id: String) -> Texture2D:
	match id:
		"coffee_shop": return COFFEE_TEXTURE
		"notice_board": return BOARD_TEXTURE
		"carrot_farm": return FARM_TEXTURE
		_: return PAVILION_TEXTURE
