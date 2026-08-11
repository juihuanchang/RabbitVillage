class_name UIStyleFactory
extends RefCounted

## 建立帶邊框與陰影的卡片樣式。
static func card(color: Color, border: Color, radius: int, shadow: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0.08, 0.13, 0.08, 0.28)
	box.shadow_size = shadow
	return box


## 建立一般按鈕樣式。
static func button(color: Color, radius := 14, vertical_margin := 13.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_top = vertical_margin
	box.content_margin_bottom = vertical_margin
	return box


## 建立進度條樣式。
static func bar(color: Color, radius := 7) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box


## 建立可自訂透明度的面板樣式。
static func panel(
	background: Color,
	border: Color,
	radius := 18,
	border_width := 2,
	shadow_size := 0,
	shadow_color := Color(0.08, 0.13, 0.08, 0.28)
) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.shadow_size = shadow_size
	box.shadow_color = shadow_color
	return box
