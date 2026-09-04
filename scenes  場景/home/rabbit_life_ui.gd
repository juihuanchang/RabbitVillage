extends Node

const ITEM_ORDER := ["carrot", "leaf", "twig", "small_stone", "driftwood"]
const ITEM_NAMES := {
	"carrot": "胡蘿蔔", "leaf": "葉子", "twig": "小樹枝",
	"small_stone": "小石頭", "driftwood": "漂流木"
}
const ITEM_CATEGORY := {
	"carrot": "food", "leaf": "material", "twig": "material",
	"small_stone": "material", "driftwood": "material"
}
const ITEM_DESCRIPTIONS := {
	"carrot": "村莊農田收成的新鮮胡蘿蔔。",
	"leaf": "Amy 從森林帶回來的一片葉子。",
	"twig": "Amy 從森林帶回來的小樹枝。",
	"small_stone": "Amy 探索森林時發現的圓潤小石頭。",
	"driftwood": "Amy 在湖畔撿到、被水磨得光滑的漂流木。"
}
const SOURCE_NAMES := {
	"forest_walk": "森林散步", "forest_explore": "森林探索", "fishing": "湖畔釣魚",
	"farm_harvest": "農田收成", "activity_reward": "活動獎勵"
}
const TENDENCY_NAMES := {"none": "尚未形成", "faint": "微弱", "clear": "明顯", "strong": "強烈"}
const LIFE_TITLES := {
	"life_leaf_collection_001": "收集在生活裡的葉子",
	"life_twig_collection_001": "小樹枝堆成的角落",
	"life_stone_collection_001": "口袋裡的小石頭",
	"life_driftwood_collection_001": "湖畔帶回來的漂流木",
	"village_life_expands_001": "村莊的生活變豐富了"
}
const LIFE_BODIES := {
	"life_leaf_collection_001": "Amy 把一路帶回來的葉子排在窗邊。\n每一片，都像一段森林裡的小小日常。",
	"life_twig_collection_001": "小樹枝慢慢累積成了一個溫暖的小角落。\nAmy 好像已經想好要怎麼珍惜它們了。",
	"life_stone_collection_001": "Amy 把小石頭一顆顆放好。\n那些不起眼的發現，也成了生活的一部分。",
	"life_driftwood_collection_001": "漂流木留下了湖水的痕跡。\nAmy 每次看見它們，都會想起安靜的水面。",
	"village_life_expands_001": "餵食、收集與外出的回憶，讓 Amy 的村莊有了更多生活的氣息。"
}

var player: RabbitCharacter
var hud_layer: CanvasLayer
var modal_layer: CanvasLayer
var toolbar: PanelContainer
var coin_label: Label
var needs_label: Label
var inventory_window: Control
var inventory_title: Label
var inventory_list: VBoxContainer
var detail_title: Label
var detail_body: Label
var feed_button: Button
var sprout_mark: Sprite2D
var tendency_window: Control
var tendency_body: Label
var album_window: Control
var album_list: VBoxContainer
var selected_item_id := ""
var _pending_rewards: Dictionary = {}
var modal_queue: Array[Dictionary] = []
var modal_busy := false
var _modal_show_scheduled := false
var _seen_pending_growth := ""
var _seen_pending_life := ""

func _ready() -> void:
	player = get_parent().get_node_or_null("Background/Player") as RabbitCharacter
	if player == null:
		push_error("RabbitLifeUI 找不到 Background/Player")
		return
	_create_layers()
	_create_toolbar()
	_create_growth_mark_visual()
	_create_inventory_window()
	_create_tendency_window()
	_create_album_window()
	_connect_signals()
	_refresh_all()
	call_deferred("_check_pending_events")

func _create_layers() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "RabbitLifeHUDLayer"
	hud_layer.layer = 25
	add_child(hud_layer)
	modal_layer = CanvasLayer.new()
	modal_layer.name = "RabbitLifeModalLayer"
	modal_layer.layer = 90
	add_child(modal_layer)

func _create_toolbar() -> void:
	toolbar = PanelContainer.new()
	toolbar.position = Vector2(610, 34)
	toolbar.size = Vector2(760, 66)
	toolbar.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff8e9ee"), Color("#b89559"), 20, 2, 8))
	hud_layer.add_child(toolbar)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	toolbar.add_child(row)
	var inventory_button := _button("🎒 背包")
	inventory_button.pressed.connect(_open_inventory)
	row.add_child(inventory_button)
	var tendency_button := _button("🌿 生活傾向")
	tendency_button.pressed.connect(_open_tendency)
	row.add_child(tendency_button)
	var album_button := _button("📖 成長相簿")
	album_button.pressed.connect(_open_album)
	row.add_child(album_button)
	coin_label = Label.new()
	coin_label.custom_minimum_size = Vector2(120, 44)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_label.add_theme_font_size_override("font_size", 21)
	coin_label.add_theme_color_override("font_color", Color("#72542f"))
	row.add_child(coin_label)
	needs_label = Label.new()
	needs_label.position = Vector2(650, 105)
	needs_label.size = Vector2(680, 36)
	needs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	needs_label.add_theme_font_size_override("font_size", 18)
	needs_label.add_theme_color_override("font_color", Color("#40573e"))
	hud_layer.add_child(needs_label)

func _create_growth_mark_visual() -> void:
	sprout_mark = Sprite2D.new()
	sprout_mark.name = "SproutMarkSprite"
	sprout_mark.position = Vector2(22, -106)
	sprout_mark.scale = Vector2(0.055, 0.055)
	sprout_mark.z_index = 3
	var texture_path := "res://assets 美術、音效等素材(不放程式)/characters/sprout_mark.png"
	if ResourceLoader.exists(texture_path):
		sprout_mark.texture = load(texture_path) as Texture2D
	else:
		var placeholder := Polygon2D.new()
		placeholder.name = "SproutPlaceholder"
		placeholder.polygon = PackedVector2Array([Vector2(-90, 20), Vector2(-25, -80), Vector2(0, 15), Vector2(35, -95), Vector2(95, 15), Vector2(0, 80)])
		placeholder.color = Color("#72a957")
		sprout_mark.add_child(placeholder)
	player.add_child(sprout_mark)
	_refresh_growth_appearance()

func _refresh_growth_appearance() -> void:
	if sprout_mark == null or player == null:
		return
	var has_sprout := player.has_growth_mark("sprout_mark")
	sprout_mark.visible = has_sprout and player.visible
	var leaf := player.get_node_or_null("LeafMarkSprite") as CanvasItem
	if leaf != null and has_sprout:
		leaf.hide()

func _create_inventory_window() -> void:
	inventory_window = _window_root("InventoryWindow")
	var card := _card(inventory_window, Vector2(430, 155), Vector2(1060, 730))
	var layout := _margin_vbox(card, 28)
	var header := HBoxContainer.new()
	layout.add_child(header)
	inventory_title = _title("背包 · 食物")
	inventory_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(inventory_title)
	var close := _button("關閉")
	close.pressed.connect(func() -> void: inventory_window.hide())
	header.add_child(close)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	layout.add_child(tabs)
	for spec in [["食物", "food"], ["素材", "material"], ["紀念品", "memory"]]:
		var tab := _button(spec[0])
		tab.pressed.connect(_show_category.bind(spec[1]))
		tabs.add_child(tab)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(430, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 8)
	scroll.add_child(inventory_list)
	var detail := PanelContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#f5ecd7"), Color("#d4bd8d"), 18, 1))
	columns.add_child(detail)
	var detail_layout := _margin_vbox(detail, 24)
	detail_title = _title("選擇一件物品")
	detail_layout.add_child(detail_title)
	detail_body = Label.new()
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_body.add_theme_font_size_override("font_size", 20)
	detail_body.add_theme_color_override("font_color", Color("#51483d"))
	detail_layout.add_child(detail_body)
	feed_button = _button("餵 Amy")
	feed_button.hide()
	feed_button.pressed.connect(_confirm_feed)
	detail_layout.add_child(feed_button)

func _create_tendency_window() -> void:
	tendency_window = _window_root("TendencyWindow")
	var card := _card(tendency_window, Vector2(615, 245), Vector2(690, 470))
	var layout := _margin_vbox(card, 32)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var heading := _title("目前生活傾向")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := _button("關閉")
	close.pressed.connect(func() -> void: tendency_window.hide())
	header.add_child(close)
	var intro := Label.new()
	intro.text = "Amy 的日常正在悄悄長出不同的方向。"
	intro.add_theme_font_size_override("font_size", 20)
	intro.add_theme_color_override("font_color", Color("#5b4a38"))
	layout.add_child(intro)
	tendency_body = Label.new()
	tendency_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tendency_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tendency_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tendency_body.add_theme_font_size_override("font_size", 30)
	tendency_body.add_theme_color_override("font_color", Color("#456345"))
	layout.add_child(tendency_body)

func _create_album_window() -> void:
	album_window = _window_root("AlbumWindow")
	var card := _card(album_window, Vector2(455, 135), Vector2(1010, 770))
	var layout := _margin_vbox(card, 28)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var heading := _title("成長相簿")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := _button("關閉")
	close.pressed.connect(func() -> void: album_window.hide())
	header.add_child(close)
	var hint := Label.new()
	hint.text = "特殊成長回憶會收藏在這裡；一般素材仍留在背包。"
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("#5b4a38"))
	layout.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	album_list = VBoxContainer.new()
	album_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	album_list.add_theme_constant_override("separation", 12)
	scroll.add_child(album_list)

func _connect_signals() -> void:
	player.rabbit_status_changed.connect(func(_rabbit: RabbitData) -> void:
		_refresh_all()
		_refresh_growth_appearance()
	)
	player.inventory_manager.inventory_changed.connect(_on_inventory_changed)
	player.inventory_manager.item_discovered.connect(_on_item_discovered)
	player.currency_manager.currency_changed.connect(func(_old: int, _new: int, _type: String, _id: String) -> void: _refresh_all())
	player.reward_manager.activity_reward_applied.connect(_on_reward_applied)
	player.activity_manager.activity_completed.connect(_on_activity_completed)
	player.farm_manager.farm_ready.connect(_on_farm_ready)
	player.save_manager.save_failed.connect(func(message: String) -> void: _enqueue_modal("存檔錯誤", message, 120))
	player.life_event_manager.life_event_triggered.connect(func(_event: LifeEventData) -> void: _check_pending_events())
	player.growth_manager.growth_event_triggered.connect(func(_event: GrowthEventData) -> void: _check_pending_events())
	player.growth_manager.growth_mark_unlocked.connect(_on_growth_mark_unlocked)
	player.growth_album_manager.entries_changed.connect(_refresh_album)

func _refresh_all() -> void:
	coin_label.text = "🪙 %d" % player.get_coin_amount()
	var hunger_names := {"full": "很飽", "normal": "普通", "low": "有點餓", "critical": "很餓"}
	var energy_names := {"high": "精神很好", "normal": "普通", "low": "有點累", "critical": "非常累"}
	var mood_names := {"happy": "心情很好", "normal": "普通", "low": "有點低落", "critical": "心情不好"}
	needs_label.text = "飢餓：%s　｜　體力：%s　｜　心情：%s" % [
		hunger_names.get(player.rabbit_manager.get_hunger_state(), "普通"),
		energy_names.get(player.rabbit_manager.get_energy_state(), "普通"),
		mood_names.get(player.rabbit_manager.get_mood_state(), "普通")
	]
	_refresh_growth_appearance()
	if inventory_window.visible:
		_show_category(_current_category())
	if tendency_window.visible:
		_refresh_tendency()
	if album_window.visible:
		_refresh_album()

func _open_inventory() -> void:
	_close_windows()
	inventory_window.show()
	_show_category("food")

func _show_category(category: String) -> void:
	inventory_window.set_meta("category", category)
	inventory_title.text = "背包 · %s" % ({"food": "食物", "material": "素材", "memory": "紀念品"}[category])
	for child in inventory_list.get_children():
		child.queue_free()
	selected_item_id = ""
	detail_title.text = "選擇一件物品"
	detail_body.text = "點選左側物品查看詳細資料。"
	feed_button.hide()
	if category == "memory":
		var note := Label.new()
		note.text = "特殊成長回憶請到成長相簿查看。"
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_font_size_override("font_size", 20)
		note.add_theme_color_override("font_color", Color("#5b4a38"))
		inventory_list.add_child(note)
		return
	for item_id in ITEM_ORDER:
		if ITEM_CATEGORY[item_id] != category:
			continue
		var discovered := player.inventory_manager.is_item_discovered(item_id)
		var amount := player.get_item_amount(item_id)
		var button := _button(("%s　×%d" % [ITEM_NAMES[item_id], amount]) if discovered else "？？？　尚未發現")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_item.bind(item_id))
		inventory_list.add_child(button)

func _select_item(item_id: String) -> void:
	selected_item_id = item_id
	var discovered := player.inventory_manager.is_item_discovered(item_id)
	feed_button.visible = item_id == "carrot" and discovered
	if not discovered:
		detail_title.text = "？？？"
		detail_body.text = "還沒有發現。"
		return
	var entry := _entry(item_id)
	detail_title.text = ITEM_NAMES[item_id]
	var first_source := _first_source_text(item_id)
	detail_body.text = "持有：%d\n\n%s\n\n第一次取得：\n%s\n\n累積取得：%d" % [
		entry.amount, ITEM_DESCRIPTIONS[item_id], first_source, entry.total_obtained
	]
	if item_id == "carrot":
		detail_body.text += "\n\n效果：飢餓 +8"

func _confirm_feed() -> void:
	var amount := player.get_item_amount("carrot")
	var rabbit := player.get_rabbit_data()
	if amount <= 0:
		_enqueue_modal("現在沒有胡蘿蔔", "現在沒有胡蘿蔔。")
		return
	if rabbit.hunger >= 95:
		_enqueue_modal("Amy 現在還不餓", "Amy 現在還不餓。")
		return
	UIModalPresenter.show_actions(modal_layer, "餵 Amy 吃胡蘿蔔", "胡蘿蔔\n\n持有：%d\n效果：飢餓 +8" % amount, "餵 Amy", _feed_carrot, "取消", func(): pass)

func _feed_carrot() -> void:
	var result := player.eat_carrot()
	if result == null:
		_enqueue_modal("現在不能餵食", "Amy 可能正在外出、休息，或有重要事件等待確認。")
		return
	_refresh_all()
	if inventory_window.visible:
		_show_category("food")
		_select_item("carrot")
	_enqueue_modal("Amy 吃了一根胡蘿蔔", "Amy 吃了一根胡蘿蔔。\n\n飢餓　%d → %d" % [result.hunger_before, result.hunger_after])

func _open_tendency() -> void:
	_close_windows()
	tendency_window.show()
	_refresh_tendency()

func _refresh_tendency() -> void:
	var forest: String = str(TENDENCY_NAMES.get(player.get_growth_tendency("forest"), "尚未形成"))
	var lakeside: String = str(TENDENCY_NAMES.get(player.get_growth_tendency("lakeside"), "尚未形成"))
	tendency_body.text = "🌲 森林：%s\n\n💧 湖畔：%s" % [forest, lakeside]

func _open_album() -> void:
	_close_windows()
	album_window.show()
	_refresh_album()

func _refresh_album() -> void:
	if album_list == null:
		return
	for child in album_list.get_children():
		child.queue_free()
	var entries := player.get_growth_album_entries()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "Amy 的成長回憶還在等待發生。"
		empty.add_theme_font_size_override("font_size", 21)
		empty.add_theme_color_override("font_color", Color("#536248"))
		album_list.add_child(empty)
		return
	for entry: GrowthAlbumEntry in entries:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fffaf0"), Color("#d7c49a"), 16, 1))
		album_list.add_child(panel)
		var box := _margin_vbox(panel, 18)
		var title := Label.new()
		title.text = _album_title(entry)
		title.add_theme_font_size_override("font_size", 24)
		title.add_theme_color_override("font_color", Color("#466148"))
		box.add_child(title)
		var body := Label.new()
		body.text = entry.description
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 18)
		body.add_theme_color_override("font_color", Color("#51483d"))
		box.add_child(body)

func _on_inventory_changed(_item_id: String, _old: int, _new: int, _source_type: String, _source_id: String) -> void:
	_refresh_all()

func _on_item_discovered(item_id: String, _source_type: String, _source_id: String, _at: float) -> void:
	_enqueue_modal("發現新物品！", "%s\n\n已放進背包。" % ITEM_NAMES.get(item_id, item_id), 80)

func _on_reward_applied(result: RewardResult) -> void:
	if result != null:
		_pending_rewards[result.activity_record_id] = result

func _on_activity_completed(active: ActiveActivityData) -> void:
	if active == null or active.activity == null:
		return
	var result := _pending_rewards.get(active.activity_record_id) as RewardResult
	if result == null:
		return
	_pending_rewards.erase(active.activity_record_id)
	var lines: Array[String] = ["Amy 回來了！", "", "%s完成" % active.activity.activity_name]
	var changes: Dictionary = active.get_stat_changes()
	for spec in [["forest_experience", "森林經歷"], ["fishing_experience", "湖畔經歷"], ["mood", "心情"], ["energy", "體力"], ["hunger", "飢餓"], ["intimacy", "親密度"]]:
		var value := int(changes.get(spec[0], 0))
		if value != 0:
			lines.append("%s %s" % [spec[1], _signed(value)])
	lines.append("")
	lines.append("金幣 %s" % _signed(result.coin_reward))
	if not result.item_rewards.is_empty():
		lines.append("")
		lines.append("獲得：")
		for item_id: String in result.item_rewards:
			lines.append("%s ×%d" % [ITEM_NAMES.get(item_id, item_id), int(result.item_rewards[item_id])])
	_enqueue_modal("活動獎勵", "\n".join(lines), 70)

func _on_farm_ready(_cycle: FarmCycleData) -> void:
	_enqueue_modal("農田成熟了", "胡蘿蔔已經成熟，可以到固定胡蘿蔔農田收成。", 40)

func _signed(value: int) -> String:
	return "+%d" % value if value >= 0 else str(value)

func _check_pending_events() -> void:
	if player.has_pending_growth_event():
		var event := player.get_pending_growth_event()
		if event != null and event.event_id != _seen_pending_growth:
			_seen_pending_growth = event.event_id
			if event.event_id == "growth_sprout_mark_001":
				_enqueue_modal("好像真的長出來了", "Amy 耳邊的小葉子旁，冒出了一點新的嫩綠。\n\n這次，好像真的長出來了。", 100, _confirm_growth.bind(event.event_id))
			elif event.event_id == "growth_lake_interest_001":
				_enqueue_modal("最近總是在看水面", "Amy 最近到了湖畔，總會安靜地看著水面。\n\n這份喜歡，正慢慢成為牠生活的一部分。", 95, _confirm_growth.bind(event.event_id))
	if player.has_pending_life_event():
		var life := player.get_pending_life_event()
		if life != null and life.event_id != _seen_pending_life:
			_seen_pending_life = life.event_id
			_enqueue_modal(LIFE_TITLES.get(life.event_id, "生活裡的新發現"), LIFE_BODIES.get(life.event_id, "Amy 的生活裡，多了一段值得記住的回憶。"), 60, _confirm_life.bind(life.event_id))

func _confirm_growth(event_id: String) -> void:
	player.confirm_growth_event(event_id)
	_seen_pending_growth = ""
	_release_legacy_growth_modal()
	_refresh_all()
	_check_pending_events()

func _release_legacy_growth_modal() -> void:
	var activity_ui := get_parent().get_node_or_null("HomeActivityUI")
	if activity_ui == null:
		return
	activity_ui.set("interaction_locked", false)
	var legacy_popup: Variant = activity_ui.get("growth_popup")
	if legacy_popup is CanvasItem:
		legacy_popup.hide()

func _confirm_life(event_id: String) -> void:
	player.confirm_life_event(event_id)
	_seen_pending_life = ""
	_check_pending_events()

func _on_growth_mark_unlocked(mark: GrowthMarkData, _event: GrowthEventData) -> void:
	if mark.id == "sprout_mark":
		_enqueue_modal("嫩芽", "Amy 的森林成長印記變成了嫩芽。\n角色外觀已切換為嫩芽階段。", 90)
	elif mark.id == "lake_interest":
		_enqueue_modal("最近總是在看水面", "這段湖畔傾向已收藏進成長相簿。\nAmy 的外觀暫時維持原樣。", 85)
	_refresh_album()

func _enqueue_modal(title: String, body: String, priority := 50, action: Callable = Callable()) -> void:
	modal_queue.append({"title": title, "body": body, "priority": priority, "action": action})
	modal_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.priority) > int(b.priority))
	if not _modal_show_scheduled:
		_modal_show_scheduled = true
		call_deferred("_show_next_modal")

func _show_next_modal() -> void:
	_modal_show_scheduled = false
	if modal_busy or modal_queue.is_empty():
		return
	if _has_external_modal():
		get_tree().create_timer(0.2).timeout.connect(_show_next_modal, CONNECT_ONE_SHOT)
		return
	modal_busy = true
	var data := modal_queue.pop_front() as Dictionary
	UIModalPresenter.show_actions(modal_layer, str(data.title), str(data.body), "確認", func() -> void:
		var action: Callable = data.action
		if action.is_valid():
			action.call()
		modal_busy = false
		call_deferred("_show_next_modal")
	, "", func(): pass)

func _has_external_modal() -> bool:
	return UIComponentFactory.has_external_modal(self, modal_layer)

func _close_windows() -> void:
	inventory_window.hide()
	tendency_window.hide()
	album_window.hide()

func _current_category() -> String:
	return str(inventory_window.get_meta("category", "food"))

func _entry(item_id: String) -> InventoryEntry:
	for entry: InventoryEntry in player.inventory_manager.get_all_items():
		if entry.item_id == item_id:
			return entry
	return InventoryEntry.new()

func _first_source_text(item_id: String) -> String:
	var collection := player.save_manager.get_item_collection_manager().get_collection_entry(item_id)
	if collection == null:
		return "尚未記錄"
	match collection.first_source_type:
		"farm_harvest", "week4_migration":
			return "農田收成"
		"activity_reward":
			for history: RewardHistoryEntry in player.save_manager.get_resource_history_manager().get_reward_history_entries():
				if history.reward_record_id == collection.first_source_id:
					return str({"forest_walk": "森林散步", "forest_explore": "森林探索", "fishing": "湖畔釣魚", "home_rest": "在家休息"}.get(history.activity_id, "活動獎勵"))
			return "活動獎勵"
		_:
			return str(SOURCE_NAMES.get(collection.first_source_type, "第一次帶回村莊"))

func _album_title(entry: GrowthAlbumEntry) -> String:
	if entry.growth_mark_id == "sprout_mark":
		return "🌱 嫩芽"
	if entry.growth_mark_id == "lake_interest":
		return "💧 最近總是在看水面"
	return entry.title

func _window_root(node_name: String) -> Control:
	return UIComponentFactory.window_root(modal_layer, node_name, 0.48)

func _card(parent: Control, position: Vector2, size: Vector2) -> PanelContainer:
	return UIComponentFactory.card(parent, position, size)

func _margin_vbox(parent: Control, margin_size: int) -> VBoxContainer:
	return UIComponentFactory.margin_vbox(parent, margin_size, 16)

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130, 44)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", UIStyleFactory.button(Color("#fffaf0"), 13, 10))
	button.add_theme_stylebox_override("hover", UIStyleFactory.button(Color("#f1dfbd"), 13, 10))
	button.add_theme_color_override("font_color", Color("#4c5f42"))
	return button

func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 29)
	label.add_theme_color_override("font_color", Color("#58402b"))
	return label
