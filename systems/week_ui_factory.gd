class_name WeekUIFactory
extends RefCounted


static func window_root(modal_layer: CanvasLayer, node_name: String, shade_alpha: float) -> Control:
	var root := ColorRect.new()
	root.name = node_name
	root.color = Color(0, 0, 0, shade_alpha)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.hide()
	modal_layer.add_child(root)
	return root


static func card(parent: Control, position: Vector2, size: Vector2) -> PanelContainer:
	var result := PanelContainer.new()
	result.position = position
	result.size = size
	result.add_theme_stylebox_override("panel", UIStyleFactory.panel(Color("#fff8e9"), Color("#9d7447"), 24, 3, 14))
	parent.add_child(result)
	return result


static func margin_vbox(parent: Control, margin_size: int, separation: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, margin_size)
	parent.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	margin.add_child(box)
	return box


static func has_external_modal(host: Node, modal_layer: CanvasLayer) -> bool:
	var scene := host.get_tree().current_scene
	if scene == null:
		return false
	for node: Node in scene.find_children(UIModalPresenter.MODAL_NODE_NAME, "Control", true, false):
		if node.get_parent() != modal_layer:
			return true
	return false
