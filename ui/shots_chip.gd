class_name ShotsChip
extends Control
## Shows the remaining shots in the game: a stone block is cracked by the first shot and
## destroyed by the second one. The icon is drawn by hand (no extra art needed).

var shots := 0

func _init() -> void:
	custom_minimum_size = Vector2(132, 52)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_shots(n: int) -> void:
	if n == shots: return
	shots = n
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var bg := Color(0, 0, 0, 0.32)
	var edge := UIKit.c("accent").darkened(0.25)
	draw_style_box(UIKit.style(bg, 26, edge, 2), Rect2(Vector2.ZERO, size))
	var ctr := Vector2(30, size.y * 0.5)
	# crosshair
	var col := UIKit.c("accent")
	draw_arc(ctr, 13.0, 0.0, TAU, 28, col, 3.0, true)
	draw_line(ctr + Vector2(-20, 0), ctr + Vector2(-15, 0), col, 3.0, true)
	draw_line(ctr + Vector2(15, 0), ctr + Vector2(20, 0), col, 3.0, true)
	draw_line(ctr + Vector2(0, -20), ctr + Vector2(0, -15), col, 3.0, true)
	draw_line(ctr + Vector2(0, 15), ctr + Vector2(0, 20), col, 3.0, true)
	draw_circle(ctr, 3.0, col)
	var txt := "x%d" % shots
	var tcol := UIKit.c("text") if shots > 0 else UIKit.c("text_dim")
	draw_string_outline(font, Vector2(54, size.y * 0.5 + 11), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 5, Color(0, 0, 0, 0.6))
	draw_string(font, Vector2(54, size.y * 0.5 + 11), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, tcol)
