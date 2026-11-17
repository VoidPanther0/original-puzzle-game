class_name StarsDisplay
extends Control
## Row of 3 vector stars, `earned` filled.

var earned := 0
var star_size := 28.0

func _init(n: int = 0, size_px: float = 28.0) -> void:
	earned = n
	star_size = size_px
	custom_minimum_size = Vector2(star_size * 3.4, star_size * 1.2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_earned(n: int) -> void:
	earned = n
	queue_redraw()

static func star_points(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		var rad := r if i % 2 == 0 else r * 0.45
		pts.append(center + Vector2(cos(ang), sin(ang)) * rad)
	return pts

func _draw() -> void:
	for i in 3:
		var ctr := Vector2(star_size * (0.6 + 1.1 * i), star_size * 0.6)
		var col := Color("ffc83d") if i < earned else Color(0.5, 0.5, 0.6, 0.45)
		draw_colored_polygon(star_points(ctr, star_size * 0.55), col)
