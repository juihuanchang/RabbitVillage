extends Node2D

const SAVE_PATH := "user://buildings.json"
const COFFEE_TEXTURE := preload("res://assets 美術、音效等素材(不放程式)/buildings/coffee_shop.png")
const SLOT_OVERLAY := preload("res://systems/building/building_slot_overlay.gd")
const SLOT_SIZE := Vector2(320, 220)
const SLOT_POSITIONS := [
	Vector2(649, 112), Vector2(1359, 148),
	Vector2(127, 439), Vector2(520, 458), Vector2(811, 439), Vector2(1280, 465),
	Vector2(378, 764), Vector2(860, 758), Vector2(1140, 741)
]

var building_mode := false
var selected_building := ""
var placed_buildings: Dictionary = {}
var slots: Array[Control] = []
var building_layer: CanvasLayer
var toolbar: PanelContainer
var mode_button: Button
var confirm_dialog: ConfirmationDialog
var info_dialog: AcceptDialog
var coffee_button: Button
var pending_slot := -1
var hint_label: Label


func _ready() -> void:
	_create_slots()
	_create_ui()
	_load_buildings()
	_refresh_slots()


func _create_slots() -> void:
	var slots_root := Node2D.new()
	slots_root.name = "BuildingSlots"
	add_child(slots_root)
	for index in SLOT_POSITIONS.size():
		var slot := PanelContainer.new()
		slot.name = "Slot%02d" % (index + 1)
		slot.position = SLOT_POSITIONS[index]
		slot.size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.set_meta("slot_index", index)
		slots_root.add_child(slot)
		slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

		var overlay := SLOT_OVERLAY.new()
		overlay.name = "SlotOverlay"
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(overlay)

		var button := Button.new()
		button.name = "PlaceButton"
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.text = "+"
		button.flat = true
		button.add_theme_font_size_override("font_size", 54)
		button.add_theme_color_override("font_color", Color("#fffdf0"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.pressed.connect(_on_slot_pressed.bind(index))
		slot.add_child(button)
		slots.append(slot)


func _create_ui() -> void:
	building_layer = CanvasLayer.new()
	building_layer.name = "BuildingModeUI"
	building_layer.layer = 20
	add_child(building_layer)

	mode_button = Button.new()
	mode_button.name = "BuildingButton"
	mode_button.text = "🏗  建築"
	mode_button.position = Vector2(1418, 48)
	mode_button.size = Vector2(217, 60)
	mode_button.add_theme_font_size_override("font_size", 20)
	mode_button.pressed.connect(_toggle_building_mode)
	building_layer.add_child(mode_button)

	toolbar = PanelContainer.new()
	toolbar.name = "BuildingToolbar"
	toolbar.position = Vector2(560, 910)
	toolbar.size = Vector2(800, 120)
	toolbar.add_theme_stylebox_override("panel", _panel_style())
	building_layer.add_child(toolbar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	toolbar.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	coffee_button = Button.new()
	coffee_button.text = "☕  咖啡廳 ×1"
	coffee_button.custom_minimum_size = Vector2(210, 76)
	coffee_button.add_theme_font_size_override("font_size", 22)
	coffee_button.pressed.connect(_select_building.bind("coffee_shop"))
	row.add_child(coffee_button)

	hint_label = Label.new()
	hint_label.text = "請選擇要建造的建築"
	hint_label.custom_minimum_size = Vector2(330, 76)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 20)
	hint_label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(hint_label)

	var exit := Button.new()
	exit.text = "退出建築模式"
	exit.custom_minimum_size = Vector2(190, 76)
	exit.pressed.connect(_exit_building_mode)
	row.add_child(exit)

	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "確認建造"
	confirm_dialog.dialog_text = "要在這個位置建造咖啡廳嗎？"
	confirm_dialog.ok_button_text = "確認建造"
	confirm_dialog.cancel_button_text = "取消"
	confirm_dialog.confirmed.connect(_confirm_slot_action)
	building_layer.add_child(confirm_dialog)

	info_dialog = AcceptDialog.new()
	info_dialog.title = "☕ 咖啡廳"
	info_dialog.dialog_text = "咖啡廳\n\n施工準備中……\n第四週開放。"
	info_dialog.ok_button_text = "知道了"
	building_layer.add_child(info_dialog)
	toolbar.hide()


func _toggle_building_mode() -> void:
	if building_mode:
		_exit_building_mode()
	else:
		building_mode = true
		selected_building = ""
		toolbar.show()
		mode_button.text = "✕  結束建築"
		_refresh_slots()


func _exit_building_mode() -> void:
	building_mode = false
	selected_building = ""
	pending_slot = -1
	toolbar.hide()
	mode_button.text = "🏗  建築"
	_refresh_slots()


func _select_building(building_id: String) -> void:
	if _coffee_is_placed():
		hint_label.text = "咖啡廳已放置；點擊建築可以收回"
		return
	selected_building = building_id
	hint_label.text = "咖啡廳已選擇：請點擊一塊高亮草地"
	_refresh_slots()


func _on_slot_pressed(index: int) -> void:
	if not building_mode:
		if placed_buildings.has(str(index)):
			info_dialog.popup_centered(Vector2i(460, 260))
		return
	pending_slot = index
	if placed_buildings.has(str(index)):
		confirm_dialog.title = "收回建築"
		confirm_dialog.dialog_text = "要收回 Slot%02d 的咖啡廳嗎？" % (index + 1)
		confirm_dialog.ok_button_text = "確認收回"
	elif not selected_building.is_empty() and not _coffee_is_placed():
		confirm_dialog.title = "確認建造"
		confirm_dialog.dialog_text = "要在 Slot%02d 建造咖啡廳嗎？" % (index + 1)
		confirm_dialog.ok_button_text = "確認建造"
	else:
		return
	confirm_dialog.popup_centered(Vector2i(500, 230))


func _confirm_slot_action() -> void:
	if pending_slot < 0:
		return
	var key := str(pending_slot)
	if placed_buildings.has(key):
		placed_buildings.erase(key)
		hint_label.text = "咖啡廳已收回，庫存恢復為 ×1"
	else:
		if selected_building.is_empty() or _coffee_is_placed():
			return
		placed_buildings[key] = selected_building
		selected_building = ""
		hint_label.text = "建造完成並已存檔！點擊建築可以收回"
	_save_buildings()
	pending_slot = -1
	_refresh_slots()


func _coffee_is_placed() -> bool:
	return placed_buildings.values().has("coffee_shop")


func _refresh_inventory() -> void:
	var available := not _coffee_is_placed()
	coffee_button.text = "☕  咖啡廳 ×1" if available else "☕  咖啡廳 ×0"
	coffee_button.disabled = not available


func _refresh_slots() -> void:
	_refresh_inventory()
	for index in slots.size():
		var slot := slots[index]
		var occupied := placed_buildings.has(str(index))
		var button := slot.get_node("PlaceButton") as Button
		var overlay := slot.get_node("SlotOverlay")
		overlay.visible = not occupied and building_mode
		overlay.active = not selected_building.is_empty()
		if occupied:
			slot.show()
			button.text = ""
			button.visible = true
			button.disabled = false
			if slot.get_node_or_null("PlacedBuilding") == null:
				_create_building_visual(slot, str(placed_buildings[str(index)]))
			slot.move_child(button, slot.get_child_count() - 1)
		else:
			_clear_building_visual(slot)
			slot.visible = building_mode
			button.text = "+"
			button.visible = building_mode
			button.disabled = selected_building.is_empty() or _coffee_is_placed()


func _create_building_visual(slot: Control, building_id: String) -> void:
	if building_id != "coffee_shop":
		return
	var building := TextureRect.new()
	building.name = "PlacedBuilding"
	building.position = Vector2.ZERO
	building.size = SLOT_SIZE
	building.texture = COFFEE_TEXTURE
	building.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	building.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	building.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(building)


func _clear_building_visual(slot: Control) -> void:
	var old := slot.get_node_or_null("PlacedBuilding")
	if old != null:
		old.queue_free()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff8e8f2")
	style.border_color = Color("#b99459")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 12
	return style


func _save_buildings() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("無法儲存建築資料")
		return
	file.store_string(JSON.stringify({"version": 1, "slots": placed_buildings}, "\t"))
	file.close()


func _load_buildings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(SAVE_PATH)) != OK or not (json.data is Dictionary):
		return
	var raw_slots: Variant = json.data.get("slots", {})
	if raw_slots is Dictionary:
		placed_buildings = raw_slots
