class_name Icons
extends RefCounted
## Simple geometric icons drawn with code (no image files). `draw` paints icon `name` into `r`.

static func draw(c: CanvasItem, name: String, r: Rect2, col: Color) -> void:
	var m := minf(r.size.x, r.size.y)
	var o := r.get_center() - Vector2(m, m) / 2.0
	var u := m / 10.0                       # 10x10 design grid
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * u
	var w := maxf(1.5, u * 1.4)
	match name:
		"pause":
			c.draw_rect(Rect2(p.call(2.5, 2), Vector2(2.2, 6) * u), col)
			c.draw_rect(Rect2(p.call(5.3, 2), Vector2(2.2, 6) * u), col)
		"back":
			c.draw_polyline(PackedVector2Array([p.call(6.5, 1.5), p.call(3, 5), p.call(6.5, 8.5)]), col, w, true)
		"close":
			c.draw_line(p.call(2, 2), p.call(8, 8), col, w, true)
			c.draw_line(p.call(8, 2), p.call(2, 8), col, w, true)
		"check":
			c.draw_polyline(PackedVector2Array([p.call(1.5, 5.5), p.call(4, 8), p.call(8.5, 2.5)]), col, w, true)
		"lock":
			c.draw_rect(Rect2(p.call(2, 4.5), Vector2(6, 4.5) * u), col)
			c.draw_arc(p.call(5, 4.5), 2.2 * u, PI, TAU, 16, col, w * 0.8, true)
		"hammer":
			c.draw_line(p.call(2.5, 8), p.call(6, 4.5), col, w, true)
			c.draw_rect(Rect2(p.call(4.6, 1.5), Vector2(4.4, 3) * u), col)
		"refresh":
			c.draw_arc(p.call(5, 5), 3.3 * u, -0.4, 4.4, 20, col, w * 0.85, true)
			c.draw_colored_polygon(PackedVector2Array([p.call(8.6, 1.4), p.call(8.9, 5), p.call(5.4, 3.6)]), col)
		"shuffle":
			c.draw_polyline(PackedVector2Array([p.call(1, 3), p.call(4, 3), p.call(6, 7), p.call(8.4, 7)]), col, w * 0.8, true)
			c.draw_polyline(PackedVector2Array([p.call(1, 7), p.call(4, 7), p.call(6, 3), p.call(8.4, 3)]), col, w * 0.8, true)
			c.draw_colored_polygon(PackedVector2Array([p.call(9.6, 3), p.call(7.8, 1.6), p.call(7.8, 4.4)]), col)
			c.draw_colored_polygon(PackedVector2Array([p.call(9.6, 7), p.call(7.8, 5.6), p.call(7.8, 8.4)]), col)
		"coin":
			c.draw_circle(r.get_center(), m * 0.46, col)
			c.draw_circle(r.get_center(), m * 0.28, col.darkened(0.18))
		"gem":
			var pts := PackedVector2Array([p.call(5, 0.8), p.call(9.2, 4), p.call(5, 9.4), p.call(0.8, 4)])
			c.draw_colored_polygon(pts, col)
			c.draw_colored_polygon(PackedVector2Array([p.call(5, 0.8), p.call(9.2, 4), p.call(0.8, 4)]), col.lightened(0.3))
		"star":
			c.draw_colored_polygon(star_points(r.get_center(), m * 0.5), col)

static func star_points(center: Vector2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(center + Vector2(cos(a), sin(a)) * (rad if i % 2 == 0 else rad * 0.45))
	return pts

## Control that shows one icon; add it as a child of a button (it ignores the mouse).
class IconRect extends Control:
	var icon_name := ""
	var color := Color.WHITE
	func _init(n: String = "", col: Color = Color.WHITE) -> void:
		icon_name = n
		color = col
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		Icons.draw(self, icon_name, Rect2(Vector2.ZERO, size), color)
