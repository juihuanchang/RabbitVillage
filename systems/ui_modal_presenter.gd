class_name UIModalPresenter
extends RefCounted

const MODAL_NODE_NAME := "SharedModal"


## 建立共用訊息、確認與雙按鈕視窗。
static func show_actions(
	layer: CanvasLayer,
	title: String,
	body: String,
	primary: String,
	primary_action: Callable,
	secondary: String,
	secondary_action: Callable,
	event_texture: Texture2D = null
) -> void:
	close(layer)
	var veil := ColorRect.new()
	veil.name = MODAL_NODE_NAME
	veil.color = Color(0, 0, 0, 0.52)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(veil)

	var panel := PanelContainer.new()
	panel.position = Vector2(600, 280)
	panel.size = Vector2(720, 430)
	panel.add_theme_stylebox_override(
		"panel",
		UIStyleFactory.panel(Color("#fff8e9"), Color("#9d7447"), 22, 3, 12, Color(0, 0, 0, 0.28))
	)
	veil.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	margin.add_child(content)

	var headline := Label.new()
	headline.text = title
	headline.add_theme_font_size_override("font_size", 30)
	headline.add_theme_color_override("font_color", Color("#58402b"))
	content.add_child(headline)

	if title.begins_with("村莊事件") and event_texture != null:
		var event_image := TextureRect.new()
		event_image.texture = event_texture
		event_image.custom_minimum_size = Vector2(0, 110)
		event_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		event_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		event_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(event_image)

	var message := Label.new()
	message.text = body
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message.add_theme_font_size_override("font_size", 21)
	message.add_theme_color_override("font_color", Color("#4d4337"))
	content.add_child(message)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 14)
	content.add_child(actions)
	if not secondary.is_empty():
		actions.add_child(_create_action_button(veil, secondary, secondary_action, Vector2(170, 55)))
	actions.add_child(_create_action_button(veil, primary, primary_action, Vector2(190, 55)))


static func close(layer: CanvasLayer) -> void:
	var modal := layer.get_node_or_null(MODAL_NODE_NAME)
	if modal != null:
		modal.queue_free()


static func _create_action_button(veil: Control, text: String, action: Callable, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.pressed.connect(func() -> void:
		veil.queue_free()
		action.call_deferred()
	)
	return button
