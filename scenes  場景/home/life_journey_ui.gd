extends Node

const CHOICES := [
	["encourage_forest", "鼓勵牽繼續親近森林"],
	["maintain_current", "先維持現在這樣"],
	["encourage_lakeside", "帶牽多去湖邊看看"],
	["let_rabbit_decide", "不干涉，讓牽自己決定"]
]
const PRIORITY := {"save_error": 800, "final_growth": 700, "stage_ending": 600, "growth": 500, "building": 400, "life_event": 300, "reward": 200, "discovery": 100}

var player: RabbitCharacter
var hud_layer: CanvasLayer
var modal_layer: CanvasLayer
var launcher: PanelContainer
var resume_window: Control
var ending_window: Control
var status_label: Label
var resume_body: RichTextLabel
var ending_body: RichTextLabel
var direction_hint: Label
var ending_button: Button
var modal_queue: Array[Dictionary] = []
var modal_busy := false
var final_overlay: Node2D
var _last_form := "none"
var _ending_was_available := false


func _ready() -> void:
	player = get_parent().get_node_or_null("Background/Player") as RabbitCharacter
	if player == null:
		push_error("LifeJourneyUI 找不到 Background/Player")
		return
	_create_layers()
	_create_launcher()
	_create_resume()
	_create_ending()
	_create_final_overlay()
	_connect_runtime()
	_refresh_all()


func _process(_delta: float) -> void:
	if player == null:
		return
	var form := _current_form()
	if form != _last_form:
		_last_form = form
		_refresh_appearance()
		if form in ["forest_rabbit", "lakeside_rabbit"]:
			_enqueue("final_growth", "Amy 長大了", _reveal_text(form), Callable())
	var available := _ending_available()
	if available and not _ending_was_available:
		_enqueue("stage_ending", "這裡真的變成一個村子了", "Amy 的第一階段生活回顧已經可以查看。", _open_ending)
	_ending_was_available = available
	_refresh_status()


func _create_layers() -> void:
	hud_layer = CanvasLayer.new(); hud_layer.name = "LifeJourneyHUDLayer"; hud_layer.layer = 32; add_child(hud_layer)
	modal_layer = CanvasLayer.new(); modal_layer.name = "LifeJourneyModalLayer"; modal_layer.layer = 140; add_child(modal_layer)


func _create_launcher() -> void:
	launcher = PanelContainer.new(); launcher.position = Vector2(1570, 555); launcher.size = Vector2(320, 230)
	launcher.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff8e9ee"), Color("#8e704d"), 22, 2, 10)); hud_layer.add_child(launcher)
	var box := UIComponentFactory.margin_vbox(launcher, 18, 10)
	box.add_child(_label("Amy 的生活旅程", 24, Color("#58402b")))
	direction_hint = _label("Amy 正在慢慢找到自己喜歡的生活。", 16, Color("#6d6254")); direction_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; box.add_child(direction_hint)
	var resume := _button("Amy 的生活履歷"); resume.pressed.connect(_open_resume); box.add_child(resume)
	ending_button = _button("第一階段回顧"); ending_button.pressed.connect(_open_ending); box.add_child(ending_button)
	status_label = _label("", 15, Color("#796a58")); status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; box.add_child(status_label)


func _create_resume() -> void:
	resume_window = UIComponentFactory.window_root(modal_layer, "RabbitResume", 0.5)
	var card := UIComponentFactory.card(resume_window, Vector2(360, 95), Vector2(1200, 890))
	var box := UIComponentFactory.margin_vbox(card, 32, 16)
	var header := HBoxContainer.new(); box.add_child(header)
	var title := _label("Amy 的生活履歷", 34, Color("#563d2b")); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	var close := _button("關閉"); close.pressed.connect(resume_window.hide); header.add_child(close)
	resume_body = RichTextLabel.new(); resume_body.bbcode_enabled = true; resume_body.fit_content = false; resume_body.size_flags_vertical = Control.SIZE_EXPAND_FILL; resume_body.add_theme_font_size_override("normal_font_size", 20); resume_body.add_theme_color_override("default_color", Color("#554b40")); box.add_child(resume_body)
	var replay := _button("再次查看第一階段回顧"); replay.pressed.connect(_open_ending); box.add_child(replay)


func _create_ending() -> void:
	ending_window = UIComponentFactory.window_root(modal_layer, "StageOneEnding", 0.72)
	var card := UIComponentFactory.card(ending_window, Vector2(260, 55), Vector2(1400, 970))
	var box := UIComponentFactory.margin_vbox(card, 38, 18)
	box.add_child(_label("這裡真的變成一個村子了", 38, Color("#563d2b")))
	ending_body = RichTextLabel.new(); ending_body.bbcode_enabled = true; ending_body.size_flags_vertical = Control.SIZE_EXPAND_FILL; ending_body.add_theme_font_size_override("normal_font_size", 21); ending_body.add_theme_color_override("default_color", Color("#554b40")); box.add_child(ending_body)
	var back := _button("回到村莊"); back.pressed.connect(_complete_ending); box.add_child(back)


func _create_final_overlay() -> void:
	final_overlay = Node2D.new(); final_overlay.name = "FinalBranchLayer"; player.add_child(final_overlay); _refresh_appearance()


func _refresh_appearance() -> void:
	if final_overlay == null: return
	for child: Node in final_overlay.get_children(): child.queue_free()
	var form := _current_form()
	if form == "forest_rabbit":
		_add_mark(PackedVector2Array([Vector2(-31,-76),Vector2(-10,-112),Vector2(0,-78),Vector2(18,-118),Vector2(35,-75),Vector2(0,-55)]), Color("#4f8b52"))
		_add_mark(PackedVector2Array([Vector2(-42,35),Vector2(-24,12),Vector2(-5,37),Vector2(-24,53)]), Color("#e9a8b7"))
	elif form == "lakeside_rabbit":
		_add_mark(PackedVector2Array([Vector2(-52,-71),Vector2(52,-71),Vector2(34,-91),Vector2(-34,-91)]), Color("#d7b46d"))
		_add_mark(PackedVector2Array([Vector2(-45,34),Vector2(-20,23),Vector2(0,34),Vector2(20,23),Vector2(45,34),Vector2(20,45),Vector2(0,34),Vector2(-20,45)]), Color("#6eb4bd99"))


func _add_mark(points: PackedVector2Array, color: Color) -> void:
	var mark := Polygon2D.new(); mark.polygon = points; mark.color = color; final_overlay.add_child(mark)


func _open_resume() -> void:
	resume_body.text = _resume_text(); resume_window.show()


func _open_ending() -> void:
	if not _ending_available() and not _ending_seen():
		_enqueue("life_event", "回顧還在繼續寫", "陪 Amy 繼續生活，完成村莊第一階段後就能查看。", Callable()); return
	ending_body.text = _ending_text(); ending_window.show()


func _complete_ending() -> void:
	if player.has_method("complete_stage1_ending") and not _ending_seen(): player.call("complete_stage1_ending")
	ending_window.hide(); _refresh_all()


func _show_direction_event(branch := "forest") -> void:
	var title := "Amy 最近好像越來越喜歡%s了" % ("森林" if branch == "forest" else "湖邊")
	var body := "這不是結局，也不會立即改變 Amy。\n你想怎麼回應牽？"
	_show_choice_modal(title, body)


func _show_choice_modal(title: String, body: String) -> void:
	UIModalPresenter.close(modal_layer)
	var veil := ColorRect.new(); veil.name = UIModalPresenter.MODAL_NODE_NAME; veil.color = Color(0,0,0,0.58); veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal_layer.add_child(veil)
	var card := UIComponentFactory.card(veil, Vector2(510,180), Vector2(900,720)); var box := UIComponentFactory.margin_vbox(card, 34, 14)
	box.add_child(_label(title, 30, Color("#563d2b"))); var intro := _label(body, 19, Color("#625547")); intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; box.add_child(intro)
	for option: Array in CHOICES:
		var button := _button(str(option[1])); button.pressed.connect(_confirm_choice.bind(str(option[0]), str(option[1]), veil)); box.add_child(button)
	var later := _button("稍後再想"); later.pressed.connect(veil.queue_free); box.add_child(later)


func _confirm_choice(choice_id: String, choice_text: String, veil: Control) -> void:
	veil.queue_free()
	UIModalPresenter.show_actions(modal_layer, "確認成長方向", "你選擇了：\n%s\n\n確認後 Amy 仍會按自己的生活經歷慢慢成長。" % choice_text, "確認", func() -> void: _submit_choice(choice_id), "返回", func() -> void: _show_direction_event(_dominant_branch()))


func _submit_choice(choice_id: String) -> void:
	if player.has_method("submit_growth_direction_choice"):
		var result: Variant = player.call("submit_growth_direction_choice", choice_id)
		if _result_ok(result): _enqueue("life_event", "Amy 好像在想些事情", "牽不會立即改變，生活會繼續自然地往前。", Callable())
	_refresh_all()


func _connect_runtime() -> void:
	_connect_if_present(player.activity_manager, "activity_completed", _on_activity_completed)
	_connect_if_present(player, "growth_direction_event_available", func(branch: Variant = "forest") -> void: _show_direction_event(str(branch)))
	_connect_if_present(player, "final_growth_completed", func(result: Variant) -> void: _enqueue("final_growth", "Amy 長大了", _reveal_text(str(_value(result,"final_form",_current_form()))), Callable()))
	_connect_if_present(player, "stage1_ending_available", func(_result: Variant = null) -> void: _enqueue("stage_ending", "村莊第一階段完成", "這裡已經有生活的樣子了。", _open_ending))


func _refresh_all() -> void:
	_last_form = _current_form(); _ending_was_available = _ending_available(); _refresh_appearance(); _refresh_status()
	if _can_show_direction(): direction_hint.text = _direction_hint_text()


func _on_activity_completed(active: ActiveActivityData) -> void:
	if active == null or active.activity == null:
		return
	var context := str(active.activity.location_id)
	if context == "lake": context = "lakeside"
	direction_hint.text = _branch_reaction(context)


func _refresh_status() -> void:
	if status_label == null: return
	if _final_pending(): status_label.text = "Amy 好像在想些事情。\n今天也可以照常生活。"
	elif _current_form() != "none": status_label.text = "目前型態：%s" % _form_name(_current_form())
	else: status_label.text = "Amy 還沒有急著決定自己最喜歡哪裡。"
	ending_button.disabled = not _ending_available() and not _ending_seen()


func _resume_text() -> String:
	var profile: Variant = player.call("get_rabbit_life_summary") if player.has_method("get_rabbit_life_summary") else {}
	return "[font_size=28][b]%s[/b][/font_size]\n\n入住日期　%s\n目前型態　%s\n個性　%s\n最常去　%s\n最常吃　%s\n最常做　%s\n\n[b]成長足跡[/b]\n%s\n\n[b]第一次[/b]\n森林　%s\n釣魚　%s\n成長印記　%s\n第一棟建築　%s\n\n[b]重要回憶[/b]\n%s" % [_profile(profile,"name","Amy"),_profile(profile,"move_in_date","還在記錄"),_form_name(_profile(profile,"current_form",_current_form())),_profile(profile,"personality","溫和地生活著"),_profile(profile,"favorite_location","尚未統計"),_profile(profile,"favorite_food","尚未統計"),_profile(profile,"most_used_activity","尚未統計"),_growth_timeline(),_profile(profile,"first_forest","尚未記錄"),_profile(profile,"first_fishing","尚未記錄"),_profile(profile,"first_growth_mark","尚未記錄"),_profile(profile,"first_building","尚未記錄"),_memories(profile)]


func _ending_text() -> String:
	var data: Variant = player.call("get_stage1_ending_result") if player.has_method("get_stage1_ending_result") else {}
	var timeline: Variant = _value(data,"timeline",[]); var memories: Variant = _value(data,"important_memories",[])
	return "[center]剛來到這裡的時候，村子裡還什麼都沒有。[/center]\n\n[b]生活足跡[/b]\n%s\n\n[b]Amy 的成長[/b]\n%s\n\n[b]村莊的變化[/b]\n農田、小店、料理與咖啡廳，都成了每天的一部分。\n\n[b]日記與相簿回憶[/b]\n%s\n\n[center][font_size=30]Amy 的生活才剛剛開始。[/font_size][/center]" % [_lines(timeline,"這些第一次都已經收進生活履歷。"),_form_name(str(_value(data,"current_form",_current_form()))),_lines(memories,"已有的日記與成長相簿記住了這段時間。")]


func _can_show_direction() -> bool: return player.has_method("can_show_growth_direction_event") and bool(player.call("can_show_growth_direction_event"))
func _final_pending() -> bool: return bool(player.call("is_final_growth_pending")) if player.has_method("is_final_growth_pending") else false
func _ending_available() -> bool: return bool(player.call("can_trigger_stage1_ending")) if player.has_method("can_trigger_stage1_ending") else false
func _ending_seen() -> bool: return bool(player.call("has_completed_stage1_ending")) if player.has_method("has_completed_stage1_ending") else false
func _current_form() -> String: return str(player.call("get_current_final_form")) if player != null and player.has_method("get_current_final_form") else "none"
func _dominant_branch() -> String: return str(player.call("get_dominant_tendency")) if player.has_method("get_dominant_tendency") else "forest"
func _direction_hint_text() -> String: return "Amy 最近回家後，總會把%s帶回來的小東西排得整整齊齊。" % ("湖邊" if _dominant_branch() == "lakeside" else "森林")
func _branch_reaction(context: String) -> String:
	var form := _current_form()
	if player.has_method("get_branch_reaction_context"):
		var supplied: Variant = player.call("get_branch_reaction_context", context)
		if not str(supplied).is_empty(): return str(supplied)
	if form == "forest_rabbit": return {"home":"Amy 把森林收藏整齊地放回家中。","forest":"Amy 聽見葉子與小鳥的聲音，顯得很自在。","lakeside":"Amy 帶著森林的氣息來看水面。","cafe":"Amy 挑了能看見綠意的位置。","picnic":"Amy 用葉子把野餐的小角落裝飾好。"}.get(context,"葉子輕輕跟著 Amy 晃動。")
	if form == "lakeside_rabbit": return {"home":"Amy 又看了一會兒水杯裡的倒影。","forest":"Amy 帶著湖邊的平靜來到森林。","lakeside":"Amy 整理著收集來的漂亮小石頭。","cafe":"Amy 安靜看著杯中的波紋。","picnic":"Amy 選了能吹到涼風的位置。"}.get(context,"水波般的印記在 Amy 身上輕輕閃著。")
	return "Amy 今天也在慢慢找到自己喜歡的生活。"
func _growth_timeline() -> String:
	var steps: Array[String] = []
	if player.has_method("get_unlocked_growth_marks"):
		for mark: Variant in player.call("get_unlocked_growth_marks"):
			var id := str(_value(mark,"id",""))
			var title: String = str({"leaf_mark":"Leaf","sprout_mark":"Sprout","forest_stage3":"Forest Tendency","lake_interest":"Lakeside Interest","lakeside_stage2":"Lakeside Tendency"}.get(id,""))
			if not str(title).is_empty(): steps.append(str(title))
	if _current_form() != "none": steps.append(_form_name(_current_form()))
	return " → ".join(steps) if not steps.is_empty() else "Amy 的成長足跡還在累積。"
func _reveal_text(form: String) -> String: return "長期的生活在 Amy 身上留下了痕跡。\n\nAmy 成為了%s。\n這不是結束，她仍然可以去任何地方生活。" % _form_name(form)
func _form_name(form: String) -> String: return str({"forest_rabbit":"Forest Rabbit","lakeside_rabbit":"Lakeside Rabbit","none":"現在的 Amy","forest_final":"Forest Rabbit","lakeside_final":"Lakeside Rabbit"}.get(form, form))
func _profile(profile: Variant, key: String, fallback: String) -> String:
	var value: Variant = _value(profile, key, fallback)
	return fallback if str(value).is_empty() else str(value)
func _memories(profile: Variant) -> String: return _lines(_value(profile,"important_memories",[]),"重要的生活事件還在累積。")
func _lines(value: Variant, fallback: String) -> String:
	if value is Array and not value.is_empty():
		var out: Array[String] = []
		for item: Variant in value:
			out.append("• %s" % str(item))
		return "\n".join(out)
	return fallback
func _result_ok(result: Variant) -> bool: return bool(result.get("ok",result.get("success",false))) if result is Dictionary else result != null and result != false
func _value(source: Variant, key: String, fallback: Variant) -> Variant: return source.get(key,fallback) if source is Dictionary else source.get(key) if source is Object and key in source else fallback


func _enqueue(kind: String, title: String, body: String, action: Callable) -> void:
	modal_queue.append({"priority":int(PRIORITY.get(kind,0)),"title":title,"body":body,"action":action}); modal_queue.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return int(a.priority)>int(b.priority)); if not modal_busy: call_deferred("_show_next")
func _show_next() -> void:
	if modal_busy or modal_queue.is_empty(): return
	modal_busy=true; var item: Dictionary=modal_queue.pop_front(); var action: Callable=item.action
	UIModalPresenter.show_actions(modal_layer,str(item.title),str(item.body),"查看" if action.is_valid() else "知道了",func()->void: if action.is_valid(): action.call(); modal_busy=false; call_deferred("_show_next"),"稍後" if action.is_valid() else "",func()->void: modal_busy=false; call_deferred("_show_next"))
func _connect_if_present(target: Object, signal_name: String, callable: Callable) -> void:
	if target != null and target.has_signal(signal_name) and not target.is_connected(signal_name,callable): target.connect(signal_name,callable)
func _label(text: String, size: int, color: Color) -> Label: var result:=Label.new(); result.text=text; result.add_theme_font_size_override("font_size",size); result.add_theme_color_override("font_color",color); return result
func _button(text: String) -> Button: var result:=Button.new(); result.text=text; result.custom_minimum_size=Vector2(0,48); result.add_theme_font_size_override("font_size",18); result.add_theme_stylebox_override("normal",UIStyleFactory.button(Color("#fffdf7"))); return result
