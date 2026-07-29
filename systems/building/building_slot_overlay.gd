extends Control

var active := false:
	set(value):
		active = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.98, 0.72, 0.25 if active else 0.15)
	fill.set_corner_radius_all(27)
	draw_style_box(fill, rect)

	_draw_dashed_rounded_border(rect, 27.0, Color(1.0, 1.0, 0.96, 1.0 if active else 0.88))


func _draw_dashed_rounded_border(rect: Rect2, radius: float, color: Color) -> void:
	var left := rect.position.x
	var top := rect.position.y
	var right := rect.end.x
	var bottom := rect.end.y
	draw_dashed_line(Vector2(left + radius, top), Vector2(right - radius, top), color, 3.0, 12.0, true)
	draw_dashed_line(Vector2(right, top + radius), Vector2(right, bottom - radius), color, 3.0, 12.0, true)
	draw_dashed_line(Vector2(right - radius, bottom), Vector2(left + radius, bottom), color, 3.0, 12.0, true)
	draw_dashed_line(Vector2(left, bottom - radius), Vector2(left, top + radius), color, 3.0, 12.0, true)
	var centers := [
		Vector2(right - radius, top + radius), Vector2(right - radius, bottom - radius),
		Vector2(left + radius, bottom - radius), Vector2(left + radius, top + radius)
	]
	var starts := [-PI / 2.0, 0.0, PI / 2.0, PI]
	for corner in 4:
		for step in 12:
			if step % 2 == 0:
				var from_angle: float = starts[corner] + (PI / 2.0) * float(step) / 12.0
				var to_angle: float = starts[corner] + (PI / 2.0) * float(step + 1) / 12.0
				draw_line(centers[corner] + Vector2(cos(from_angle), sin(from_angle)) * radius, centers[corner] + Vector2(cos(to_angle), sin(to_angle)) * radius, color, 3.0, true)
