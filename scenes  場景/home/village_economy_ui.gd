extends Node

const PRODUCT_ORDER := ["apple", "bread", "berry_juice", "small_snack"]
const PRODUCT_DATA := {
	"apple": {"name": "蘋果", "description": "清脆多汁的紅蘋果。", "price": 6, "stock": 3, "effect": "飢餓 +10　心情 +2"},
	"bread": {"name": "麵包", "description": "剛出爐、帶著溫暖香氣的麵包。", "price": 10, "stock": 2, "effect": "飢餓 +18　體力 +3"},
	"berry_juice": {"name": "莓果汁", "description": "酸甜莓果調成的清爽果汁。", "price": 14, "stock": 2, "effect": "體力 +5　心情 +6"},
	"small_snack": {"name": "小點心", "description": "適合帶去野餐的小份點心。", "price": 8, "stock": 3, "effect": "飢餓 +8　心情 +3"}
}
const RECIPE_ORDER := ["recipe_carrot_sandwich", "recipe_forest_salad", "recipe_berry_toast", "recipe_picnic_snack"]
const RECIPE_DATA := {
	"recipe_carrot_sandwich": {"name": "胡蘿蔔三明治", "result": "carrot_sandwich", "ingredients": {"carrot": 1, "bread": 1}},
	"recipe_forest_salad": {"name": "森林沙拉", "result": "forest_salad", "ingredients": {"leaf": 2, "apple": 1}},
	"recipe_berry_toast": {"name": "莓果吐司", "result": "berry_toast", "ingredients": {"bread": 1, "berry_juice": 1}},
	"recipe_picnic_snack": {"name": "野餐小點", "result": "picnic_snack", "ingredients": {"small_snack": 1, "apple": 1}}
}
const ITEM_NAMES := {
	"carrot": "胡蘿蔔", "leaf": "葉子", "twig": "小樹枝", "small_stone": "小石頭", "driftwood": "漂流木",
	"apple": "蘋果", "bread": "麵包", "berry_juice": "莓果汁", "small_snack": "小點心",
	"carrot_sandwich": "胡蘿蔔三明治", "forest_salad": "森林沙拉", "berry_toast": "莓果吐司", "picnic_snack": "野餐小點"
}
const FOOD_IDS := ["carrot", "apple", "bread", "berry_juice", "small_snack", "carrot_sandwich", "forest_salad", "berry_toast", "picnic_snack"]
const FOOD_EFFECTS := {
	"carrot": "飢餓 +8", "apple": "飢餓 +10　心情 +2", "bread": "飢餓 +18　體力 +3",
	"berry_juice": "體力 +5　心情 +6", "small_snack": "飢餓 +8　心情 +3",
	"carrot_sandwich": "飢餓 +25　體力 +5", "forest_salad": "飢餓 +15　心情 +8",
	"berry_toast": "飢餓 +20　心情 +10", "picnic_snack": "飢餓 +18　體力 +6　心情 +8"
}
const FAILURE_TEXT := {
	"not_enough_coins": "金幣好像不太夠。", "daily_limit_reached": "今天已經買很多了。",
	"product_locked": "這個商品還沒有開放。", "not_available_today": "今天沒有販售這個商品。",
	"not_enough_ingredients": "材料好像不太夠。", "recipe_locked": "還沒有想到這道料理。",
	"daily_limit": "今天已經在野餐區待很久了。", "cooldown": "先休息一下再來吧。"
}
const PREVIEW_PRODUCT_UNLOCKS := {"apple": true, "bread": true, "berry_juice": false, "small_snack": true}
const PREVIEW_RECIPE_UNLOCKS := {"recipe_carrot_sandwich": true, "recipe_forest_salad": true, "recipe_berry_toast": false, "recipe_picnic_snack": false}

var player: Node
var layer: CanvasLayer
var modal_layer: CanvasLayer
var hub: PanelContainer
var shop_window: Control
var cooking_window: Control
var food_window: Control
var picnic_window: Control
var collection_window: Control
var shop_list: VBoxContainer
var shop_detail_title: Label
var shop_detail_body: Label
var shop_buy_button: Button
var shop_quantity_label: Label
var shop_coin_label: Label
var cooking_list: VBoxContainer
var recipe_title: Label
var recipe_body: Label
var cook_button: Button
var food_list: VBoxContainer
var food_title: Label
var food_body: Label
var food_use_button: Button
var picnic_body: Label
var picnic_food_list: VBoxContainer
var collection_body: Label
var selected_product := ""
var selected_recipe := ""
var selected_food := ""
var purchase_quantity := 1
var modal_queue: Array[Dictionary] = []
var modal_busy := false
var _show_scheduled := false

func _ready() -> void:
	player = get_parent().get_node_or_null("Background/Player")
	if player == null:
		push_error("VillageEconomyUI 找不到 Background/Player")
		return
	_create_layers()
	_create_hub()
	_create_shop_window()
	_create_cooking_window()
	_create_food_window()
	_create_picnic_window()
	_create_collection_window()
	_connect_runtime_signals()
	_refresh_all()
	call_deferred("_attach_backpack_cooking_button")

func _create_layers() -> void:
	layer = CanvasLayer.new()
	layer.name = "VillageEconomyHUDLayer"
	layer.layer = 27
	add_child(layer)
	modal_layer = CanvasLayer.new()
	modal_layer.name = "VillageEconomyModalLayer"
	modal_layer.layer = 110
	add_child(modal_layer)

func _create_hub() -> void:
	hub = PanelContainer.new()
	hub.position = Vector2(1570, 605)
	hub.size = Vector2(320, 435)
	hub.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff8e9ee"), Color("#a97946"), 22, 2, 10))
	layer.add_child(hub)
	var box := _margin_vbox(hub, 18)
	var title := _label("村莊生活", 24, Color("#59402c"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var shop := _button("🏪  村莊小店")
	shop.pressed.connect(_open_shop)
	box.add_child(shop)
	var cooking := _button("🍳  料理")
	cooking.pressed.connect(_open_cooking)
	box.add_child(cooking)
	var food := _button("🍎  食物")
	food.pressed.connect(_open_food)
	box.add_child(food)
	var picnic := _button("🧺  野餐區")
	picnic.pressed.connect(_open_picnic)
	box.add_child(picnic)
	var collection := _button("📒  生活收藏")
	collection.pressed.connect(_open_collection)
	box.add_child(collection)

func _create_shop_window() -> void:
	shop_window = _window_root("ShopWindow")
	var card := _card(shop_window, Vector2(305, 105), Vector2(1310, 860))
	var layout := _margin_vbox(card, 28)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := _label("村莊小店", 34, Color("#5b3f2a"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	shop_coin_label = _label("🪙 0", 24, Color("#7b572f"))
	header.add_child(shop_coin_label)
	header.add_child(_close_button(shop_window))
	var subtitle := _label("今日商品　·　每天會換一些新的東西", 20, Color("#665442"))
	layout.add_child(subtitle)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 0)
	columns.add_child(scroll)
	shop_list = VBoxContainer.new()
	shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list.add_theme_constant_override("separation", 10)
	scroll.add_child(shop_list)
	var detail := PanelContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#f5ecd7"), Color("#d1b784"), 18, 1))
	columns.add_child(detail)
	var detail_box := _margin_vbox(detail, 24)
	shop_detail_title = _label("選擇今日商品", 28, Color("#59402c"))
	detail_box.add_child(shop_detail_title)
	shop_detail_body = _label("點選左側商品查看價格與效果。", 20, Color("#51483d"))
	shop_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(shop_detail_body)
	var quantity := HBoxContainer.new()
	quantity.alignment = BoxContainer.ALIGNMENT_CENTER
	quantity.add_theme_constant_override("separation", 12)
	detail_box.add_child(quantity)
	var minus := _button("−")
	minus.custom_minimum_size = Vector2(60, 46)
	minus.pressed.connect(func() -> void: _change_quantity(-1))
	quantity.add_child(minus)
	shop_quantity_label = _label("1", 24, Color("#59402c"))
	shop_quantity_label.custom_minimum_size = Vector2(70, 46)
	shop_quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity.add_child(shop_quantity_label)
	var plus := _button("＋")
	plus.custom_minimum_size = Vector2(60, 46)
	plus.pressed.connect(func() -> void: _change_quantity(1))
	quantity.add_child(plus)
	shop_buy_button = _button("購買")
	shop_buy_button.disabled = true
	shop_buy_button.pressed.connect(_confirm_purchase)
	detail_box.add_child(shop_buy_button)

func _create_cooking_window() -> void:
	cooking_window = _window_root("CookingWindow")
	var card := _card(cooking_window, Vector2(345, 115), Vector2(1230, 840))
	var layout := _margin_vbox(card, 28)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := _label("料理", 34, Color("#5b3f2a"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_close_button(cooking_window))
	var subtitle := _label("用背包裡的食材，替 Amy 準備簡單料理。", 20, Color("#665442"))
	layout.add_child(subtitle)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 0)
	columns.add_child(scroll)
	cooking_list = VBoxContainer.new()
	cooking_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cooking_list.add_theme_constant_override("separation", 10)
	scroll.add_child(cooking_list)
	var detail := PanelContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#f5ecd7"), Color("#d1b784"), 18, 1))
	columns.add_child(detail)
	var detail_box := _margin_vbox(detail, 24)
	recipe_title = _label("選擇一道料理", 28, Color("#59402c"))
	detail_box.add_child(recipe_title)
	recipe_body = _label("尚未選擇食譜。", 20, Color("#51483d"))
	recipe_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(recipe_body)
	cook_button = _button("製作")
	cook_button.disabled = true
	cook_button.pressed.connect(_cook_selected)
	detail_box.add_child(cook_button)

func _create_picnic_window() -> void:
	picnic_window = _window_root("PicnicWindow")
	var card := _card(picnic_window, Vector2(455, 120), Vector2(1010, 820))
	var layout := _margin_vbox(card, 30)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := _label("野餐區", 34, Color("#435c37"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_close_button(picnic_window))
	picnic_body = _label("Amy 想在這裡做什麼？", 22, Color("#51483d"))
	picnic_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(picnic_body)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)
	for spec in [["休息一下", "picnic_rest"], ["吃點東西", "picnic_eat"], ["看看周圍", "picnic_relax"]]:
		var button := _button(spec[0])
		button.pressed.connect(_start_picnic_activity.bind(spec[1]))
		actions.add_child(button)
	var picnic_food_heading := _label("可帶去野餐的食物", 23, Color("#435c37"))
	layout.add_child(picnic_food_heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	picnic_food_list = VBoxContainer.new()
	picnic_food_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picnic_food_list.add_theme_constant_override("separation", 8)
	scroll.add_child(picnic_food_list)

func _create_food_window() -> void:
	food_window = _window_root("FoodWindow")
	var card := _card(food_window, Vector2(430, 130), Vector2(1060, 800))
	var layout := _margin_vbox(card, 28)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var heading := _label("食物", 34, Color("#5b3f2a"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	header.add_child(_close_button(food_window))
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 22)
	layout.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(430, 0)
	columns.add_child(scroll)
	food_list = VBoxContainer.new()
	food_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	food_list.add_theme_constant_override("separation", 8)
	scroll.add_child(food_list)
	var detail := PanelContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#f5ecd7"), Color("#d1b784"), 18, 1))
	columns.add_child(detail)
	var detail_box := _margin_vbox(detail, 24)
	food_title = _label("選擇食物", 28, Color("#59402c"))
	detail_box.add_child(food_title)
	food_body = _label("目前收集到的食物都會顯示在這裡。", 20, Color("#51483d"))
	food_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	food_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(food_body)
	food_use_button = _button("給 Amy 吃")
	food_use_button.disabled = true
	food_use_button.pressed.connect(_use_selected_food)
	detail_box.add_child(food_use_button)

func _create_collection_window() -> void:
	collection_window = _window_root("LifeCollectionWindow")
	var card := _card(collection_window, Vector2(540, 190), Vector2(840, 660))
	var layout := _margin_vbox(card, 30)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := _label("生活收藏", 32, Color("#5b3f2a"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_close_button(collection_window))
	collection_body = _label("", 21, Color("#51483d"))
	collection_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	collection_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(collection_body)

func _open_shop() -> void:
	_close_windows()
	shop_window.show()
	_refresh_shop()

func _refresh_shop() -> void:
	shop_coin_label.text = "目前金幣　🪙 %d" % _coin_amount()
	_clear(shop_list)
	var today_products := _today_product_ids()
	if today_products.is_empty():
		var empty := _label("好像還沒有開始營業。", 21, Color("#665442"))
		shop_list.add_child(empty)
		return
	for product_id in today_products:
		var unlocked := _is_product_unlocked(product_id)
		var data: Dictionary = PRODUCT_DATA[product_id]
		var remaining := _daily_remaining(product_id)
		var text := "？？？\n好像還沒有進貨。" if not unlocked else "%s　　🪙 %d\n%s" % [data.name, _unit_price(product_id), "今日售完" if remaining <= 0 else "剩餘 %d" % remaining]
		var button := _button(text)
		button.custom_minimum_size = Vector2(470, 76)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not unlocked or remaining <= 0
		button.pressed.connect(_select_product.bind(product_id))
		shop_list.add_child(button)

func _select_product(product_id: String) -> void:
	selected_product = product_id
	purchase_quantity = 1
	_update_product_detail()

func _change_quantity(delta: int) -> void:
	purchase_quantity = clampi(purchase_quantity + delta, 1, 3)
	_update_product_detail()

func _update_product_detail() -> void:
	if selected_product.is_empty():
		return
	var data: Dictionary = PRODUCT_DATA[selected_product]
	var unit := _unit_price(selected_product)
	var total := unit * purchase_quantity
	var coin := _coin_amount()
	shop_detail_title.text = str(data.name)
	shop_detail_body.text = "%s\n\n持有：%d\n今日剩餘：%d\n\n效果：\n%s\n\n單價：🪙 %d\n總價：🪙 %d\n\n目前 Coin：%d\n購買後：%d" % [data.description, _item_amount(selected_product), _daily_remaining(selected_product), data.effect, unit, total, coin, coin - total]
	shop_quantity_label.text = str(purchase_quantity)
	shop_buy_button.text = "購買 %s ×%d" % [data.name, purchase_quantity]
	shop_buy_button.disabled = _daily_remaining(selected_product) < purchase_quantity

func _confirm_purchase() -> void:
	if selected_product.is_empty():
		return
	var data: Dictionary = PRODUCT_DATA[selected_product]
	var total := _unit_price(selected_product) * purchase_quantity
	_enqueue_modal("確認購買", "要購買：\n\n%s ×%d\n\n總共需要：\n🪙 %d" % [data.name, purchase_quantity, total], 55, _purchase_selected)

func _purchase_selected() -> void:
	var manager := _manager("shop_manager")
	if manager == null or not manager.has_method("purchase"):
		_enqueue_modal("商店尚未開放", "目前無法完成交易，請稍後再試。", 80)
		return
	var coin_before := _coin_amount()
	var result: Variant = manager.call("purchase", selected_product, purchase_quantity)
	if not _result_success(result):
		_enqueue_modal("沒有買到", FAILURE_TEXT.get(_result_reason(result), "現在沒有辦法購買。"), 80)
		return
	var product_name: String = str(PRODUCT_DATA[selected_product].name)
	_enqueue_modal("買到了！", "%s ×%d\n\n🪙 %d → %d" % [product_name, purchase_quantity, coin_before, _coin_amount()], 65)
	_refresh_shop()

func _open_cooking() -> void:
	_close_windows()
	cooking_window.show()
	_refresh_cooking()

func _refresh_cooking() -> void:
	_clear(cooking_list)
	for recipe_id in RECIPE_ORDER:
		var unlocked := _is_recipe_unlocked(recipe_id)
		var data: Dictionary = RECIPE_DATA[recipe_id]
		var text := "？？？\n還沒有想到這道料理。" if not unlocked else str(data.name)
		var button := _button(text)
		button.custom_minimum_size = Vector2(450, 68)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not unlocked
		button.pressed.connect(_select_recipe.bind(recipe_id))
		cooking_list.add_child(button)

func _select_recipe(recipe_id: String) -> void:
	selected_recipe = recipe_id
	var data: Dictionary = RECIPE_DATA[recipe_id]
	var lines: Array[String] = ["需要：", ""]
	for item_id: String in data.ingredients:
		lines.append("%s　%d / %d" % [ITEM_NAMES.get(item_id, item_id), _item_amount(item_id), int(data.ingredients[item_id])])
	lines.append("")
	lines.append("完成後：")
	lines.append("%s ×1" % ITEM_NAMES.get(data.result, data.result))
	recipe_title.text = str(data.name)
	recipe_body.text = "\n".join(lines)
	cook_button.disabled = false

func _cook_selected() -> void:
	if selected_recipe.is_empty():
		return
	var manager := _manager("cooking_manager")
	if manager == null or not manager.has_method("cook"):
		_enqueue_modal("料理尚未開放", "目前無法製作料理，請稍後再試。", 80)
		return
	if manager.has_method("can_cook"):
		var check: Variant = manager.call("can_cook", selected_recipe)
		if not _result_success(check):
			_enqueue_modal("還不能製作", FAILURE_TEXT.get(_result_reason(check), "材料好像不太夠。"), 80)
			return
	var result: Variant = manager.call("cook", selected_recipe)
	if not _result_success(result):
		_enqueue_modal("沒有完成", FAILURE_TEXT.get(_result_reason(result), "材料好像不太夠。"), 80)
		return
	var recipe: Dictionary = RECIPE_DATA[selected_recipe]
	var first := bool(_value(result, "is_first_cook", _value(result, "is_first_discovery", false)))
	var body := "%s ×1" % ITEM_NAMES.get(recipe.result, recipe.result)
	if first:
		body += "\n\n發現新料理！"
	_enqueue_modal("做好了！", body, 70)
	_refresh_cooking()

func _open_picnic() -> void:
	_close_windows()
	picnic_window.show()
	_refresh_picnic_foods()

func _open_food() -> void:
	_close_windows()
	food_window.show()
	_refresh_foods()

func _refresh_foods() -> void:
	_clear(food_list)
	for food_id in FOOD_IDS:
		var amount := _item_amount(food_id)
		var button := _button("%s　×%d" % [ITEM_NAMES.get(food_id, food_id), amount])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = amount <= 0
		button.pressed.connect(_select_food.bind(food_id))
		food_list.add_child(button)

func _select_food(food_id: String) -> void:
	selected_food = food_id
	food_title.text = str(ITEM_NAMES.get(food_id, food_id))
	food_body.text = "持有：%d\n\n效果：\n%s" % [_item_amount(food_id), FOOD_EFFECTS.get(food_id, "由 FoodManager 提供效果")]
	food_use_button.disabled = _item_amount(food_id) <= 0

func _use_selected_food() -> void:
	if selected_food.is_empty():
		return
	var manager := _manager("food_manager")
	var result: Variant
	if manager != null and manager.has_method("use_food"):
		result = manager.call("use_food", selected_food)
	elif selected_food == "carrot" and player.has_method("eat_carrot"):
		result = player.call("eat_carrot")
	else:
		_enqueue_modal("現在無法食用", "這項食物目前尚不能使用。", 80)
		return
	if result == null or not _result_success(result):
		_enqueue_modal("現在不能吃", FAILURE_TEXT.get(_result_reason(result), "現在使用這份食物不會產生效果。"), 80)
		return
	var lines: Array[String] = ["Amy 吃了%s。" % ITEM_NAMES.get(selected_food, selected_food)]
	for stat_id in ["hunger", "energy", "mood"]:
		var before_value: Variant = _value(result, "%s_before" % stat_id, null)
		var after_value: Variant = _value(result, "%s_after" % stat_id, null)
		if before_value != null and after_value != null and int(before_value) != int(after_value):
			lines.append("\n%s\n%d → %d" % [_stat_name(stat_id), int(before_value), int(after_value)])
	_enqueue_modal("享用食物", "\n".join(lines), 65)
	_refresh_foods()

func _refresh_picnic_foods() -> void:
	_clear(picnic_food_list)
	for food_id in FOOD_IDS:
		var amount := _item_amount(food_id)
		var button := _button("%s　×%d" % [ITEM_NAMES.get(food_id, food_id), amount])
		button.disabled = amount <= 0
		button.pressed.connect(_picnic_eat.bind(food_id))
		picnic_food_list.add_child(button)

func _start_picnic_activity(activity_id: String) -> void:
	if activity_id == "picnic_eat":
		picnic_body.text = "請從下方選擇 Amy 想吃的食物。"
		return
	_run_picnic(activity_id, "")

func _picnic_eat(food_id: String) -> void:
	_run_picnic("picnic_eat", food_id)

func _run_picnic(activity_id: String, food_id: String) -> void:
	var manager := _manager("life_location_manager")
	if manager == null:
		_enqueue_modal("野餐活動尚未開放", "目前無法開始這項野餐活動。", 80)
		return
	var result: Variant
	if manager.has_method("perform_activity"):
		result = manager.call("perform_activity", "picnic_area", activity_id, food_id)
	elif manager.has_method("start_activity"):
		result = manager.call("start_activity", "picnic_area", activity_id, food_id)
	else:
		_enqueue_modal("尚未接入", "LifeLocationManager 尚未提供活動 API。", 80)
		return
	if not _result_success(result):
		_enqueue_modal("現在不能進行", FAILURE_TEXT.get(_result_reason(result), "Amy 現在不適合進行這個活動。"), 80)
		return
	var story := str(_value(result, "story", _value(result, "description", "Amy 在野餐區度過了一段悠閒時光。")))
	var changes: Dictionary = _value(result, "stat_changes", {}) as Dictionary
	for stat_id: String in changes:
		story += "\n%s %s" % [_stat_name(stat_id), _signed(int(changes[stat_id]))]
	_enqueue_modal("野餐時光", story, 65)
	_refresh_picnic_foods()

func _open_collection() -> void:
	_close_windows()
	collection_window.show()
	_refresh_collection()

func _refresh_collection() -> void:
	var lines: Array[String] = ["商店發現", ""]
	var discovered := 0
	for product_id in PRODUCT_ORDER:
		var found := _item_amount(product_id) > 0 or _is_product_discovered(product_id)
		if found:
			discovered += 1
		lines.append("%s　　%s" % [PRODUCT_DATA[product_id].name if found else "？？？", "已發現" if found else "未發現"])
	lines.append("")
	lines.append("購買次數：%d" % _stat("purchase_count"))
	lines.append("累積花費：%d" % _stat("total_spent"))
	lines.append("發現商品：%d / %d" % [discovered, PRODUCT_ORDER.size()])
	lines.append("")
	lines.append("料理發現")
	for recipe_id in RECIPE_ORDER:
		var found := _is_recipe_discovered(recipe_id)
		lines.append("%s　　%s" % [RECIPE_DATA[recipe_id].name if found else "？？？", "已發現" if found else "未發現"])
	collection_body.text = "\n".join(lines)

func _connect_runtime_signals() -> void:
	_connect_if_present(_manager("shop_manager"), "purchase_completed", func(result: Variant) -> void: _on_purchase_signal(result))
	_connect_if_present(_manager("daily_shop_manager"), "daily_shop_refreshed", func(_offer: Variant = null) -> void: _enqueue_modal("今日小店", "今天的小店換了一些東西。", 45))
	_connect_if_present(_manager("shop_manager"), "product_unlocked", func(_product: Variant) -> void: _enqueue_modal("小店的新東西", "小店好像進了新的東西。", 70))
	_connect_if_present(_manager("cooking_manager"), "cooking_completed", func(_result: Variant) -> void: _refresh_all())
	_connect_if_present(_manager("cooking_manager"), "recipe_discovered", func(recipe: Variant) -> void: _enqueue_modal("第一次做出了！", str(_value(recipe, "display_name", "發現新料理！")), 75))
	_connect_if_present(_manager("life_location_manager"), "life_location_activity_completed", func(_result: Variant) -> void: _refresh_all())
	var life := _manager("life_event_manager")
	_connect_if_present(life, "life_event_triggered", func(event: Variant) -> void: _show_week6_event(event))

func _on_purchase_signal(_result: Variant) -> void:
	_refresh_all()

func _show_week6_event(event: Variant) -> void:
	var event_id := str(_value(event, "event_id", ""))
	var titles := {
		"shop_first_purchase_001": "第一次在村莊小店買東西", "shop_regular_customer_001": "最近常常來小店",
		"shop_big_spender_001": "村莊裡的生活消費", "shop_daily_browser_001": "每天都想看看今天賣什麼",
		"shop_all_foods_discovered_001": "小店的食物都認識了", "cooking_first_dish_001": "第一次做飯",
		"cooking_variety_001": "最近好像很會準備吃的了", "picnic_first_visit_001": "第一次來到野餐區",
		"picnic_slow_day_001": "今天什麼都沒有趕", "village_daily_life_001": "日子好像真的過起來了"
	}
	if titles.has(event_id):
		_enqueue_modal(str(titles[event_id]), "Amy 的村莊生活又多了一段值得記住的日常。", 90)

func _refresh_all() -> void:
	if shop_window != null and shop_window.visible:
		_refresh_shop()
	if cooking_window != null and cooking_window.visible:
		_refresh_cooking()
	if picnic_window != null and picnic_window.visible:
		_refresh_picnic_foods()
	if food_window != null and food_window.visible:
		_refresh_foods()
	if collection_window != null and collection_window.visible:
		_refresh_collection()

func _attach_backpack_cooking_button() -> void:
	var life_ui := get_parent().get_node_or_null("RabbitLifeUI")
	if life_ui == null:
		return
	var root: Variant = life_ui.get("inventory_window")
	if not (root is Control):
		return
	if root.get_node_or_null("CookingShortcut") != null:
		return
	var shortcut := _button("🍳  料理")
	shortcut.name = "CookingShortcut"
	shortcut.position = Vector2(1225, 175)
	shortcut.size = Vector2(150, 48)
	shortcut.pressed.connect(_open_cooking)
	root.add_child(shortcut)

func _manager(property_name: String) -> Node:
	if player == null:
		return null
	for property: Dictionary in player.get_property_list():
		if str(property.get("name", "")) == property_name:
			return player.get(property_name) as Node
	return null

func _coin_amount() -> int:
	return int(player.call("get_coin_amount")) if player.has_method("get_coin_amount") else 0

func _item_amount(item_id: String) -> int:
	return int(player.call("get_item_amount", item_id)) if player.has_method("get_item_amount") else 0

func _is_product_unlocked(product_id: String) -> bool:
	var manager := _manager("shop_manager")
	return bool(manager.call("is_product_unlocked", product_id)) if manager != null and manager.has_method("is_product_unlocked") else bool(PREVIEW_PRODUCT_UNLOCKS.get(product_id, false))

func _daily_remaining(product_id: String) -> int:
	var manager := _manager("shop_manager")
	return int(manager.call("get_daily_remaining", product_id)) if manager != null and manager.has_method("get_daily_remaining") else int(PRODUCT_DATA[product_id].stock)

func _unit_price(product_id: String) -> int:
	var manager := _manager("shop_manager")
	return int(manager.call("get_purchase_price", product_id, 1)) if manager != null and manager.has_method("get_purchase_price") else int(PRODUCT_DATA[product_id].price)

func _today_product_ids() -> Array[String]:
	var result: Array[String] = []
	var manager := _manager("daily_shop_manager")
	if manager != null and manager.has_method("get_daily_offers"):
		var offers: Variant = manager.call("get_daily_offers")
		if offers is Array:
			for offer: Variant in offers:
				var product_id := str(_value(offer, "product_id", _value(offer, "item_id", "")))
				if PRODUCT_DATA.has(product_id) and not result.has(product_id):
					result.append(product_id)
		return result
	result.assign(PRODUCT_ORDER)
	return result

func _is_product_discovered(product_id: String) -> bool:
	var manager := _manager("shop_manager")
	return bool(manager.call("is_product_discovered", product_id)) if manager != null and manager.has_method("is_product_discovered") else _item_amount(product_id) > 0

func _is_recipe_unlocked(recipe_id: String) -> bool:
	var manager := _manager("cooking_manager")
	if manager != null and manager.has_method("get_recipe"):
		var recipe: Variant = manager.call("get_recipe", recipe_id)
		return bool(_value(recipe, "is_unlocked", _value(recipe, "unlocked", false)))
	return bool(PREVIEW_RECIPE_UNLOCKS.get(recipe_id, false))

func _is_recipe_discovered(recipe_id: String) -> bool:
	var manager := _manager("cooking_manager")
	return bool(manager.call("is_recipe_discovered", recipe_id)) if manager != null and manager.has_method("is_recipe_discovered") else false

func _stat(stat_id: String) -> int:
	var manager := _manager("shop_manager")
	if manager != null:
		var method := "get_%s" % stat_id
		if manager.has_method(method):
			return int(manager.call(method))
	return 0

func _result_success(result: Variant) -> bool:
	return bool(_value(result, "success", _value(result, "ok", result != null)))

func _result_reason(result: Variant) -> String:
	return str(_value(result, "reason", ""))

func _value(source: Variant, key: String, fallback: Variant = null) -> Variant:
	if source is Dictionary:
		return source.get(key, fallback)
	if source is Object:
		for property: Dictionary in source.get_property_list():
			if str(property.get("name", "")) == key:
				return source.get(key)
	return fallback

func _connect_if_present(manager: Node, signal_name: String, callback: Callable) -> void:
	if manager != null and manager.has_signal(signal_name) and not manager.is_connected(signal_name, callback):
		manager.connect(signal_name, callback)

func _stat_name(stat_id: String) -> String:
	return {"hunger": "飢餓", "energy": "體力", "mood": "心情", "intimacy": "親密度"}.get(stat_id, stat_id)

func _signed(value: int) -> String:
	return "+%d" % value if value >= 0 else str(value)

func _enqueue_modal(title: String, body: String, priority := 50, action: Callable = Callable()) -> void:
	modal_queue.append({"title": title, "body": body, "priority": priority, "action": action})
	modal_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.priority) > int(b.priority))
	if not _show_scheduled:
		_show_scheduled = true
		call_deferred("_show_next_modal")

func _show_next_modal() -> void:
	_show_scheduled = false
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
	, "取消" if (data.action as Callable).is_valid() else "", func() -> void:
		modal_busy = false
		call_deferred("_show_next_modal")
	)

func _has_external_modal() -> bool:
	return WeekUIFactory.has_external_modal(self, modal_layer)

func _close_windows() -> void:
	for window in [shop_window, cooking_window, food_window, picnic_window, collection_window]:
		window.hide()

func _clear(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _window_root(node_name: String) -> Control:
	return WeekUIFactory.window_root(modal_layer, node_name, 0.5)

func _card(parent: Control, position: Vector2, size: Vector2) -> PanelContainer:
	return WeekUIFactory.card(parent, position, size)

func _margin_vbox(parent: Control, margin_size: int) -> VBoxContainer:
	return WeekUIFactory.margin_vbox(parent, margin_size, 14)

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 48)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", UIStyleFactory.button(Color("#fffaf0"), 13, 10))
	button.add_theme_stylebox_override("hover", UIStyleFactory.button(Color("#efdcb6"), 13, 10))
	button.add_theme_stylebox_override("disabled", UIStyleFactory.button(Color("#ded7c7"), 13, 10))
	button.add_theme_color_override("font_color", Color("#40573e"))
	button.add_theme_color_override("font_disabled_color", Color("#81796e"))
	return button

func _close_button(window: Control) -> Button:
	var button := _button("關閉")
	button.custom_minimum_size = Vector2(100, 46)
	button.pressed.connect(func() -> void: window.hide())
	return button

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
