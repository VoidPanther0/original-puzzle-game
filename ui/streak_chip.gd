class_name StreakChip
extends Control
## "Day streak" pill with a hand drawn flame. Sits under the logo on Home.

var days := 0
var best := 0

func _init() -> void:
	custom_minimum_size = Vector2(250, 66)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_days(d: int, b: int) -> void:
	if d == days and b == best: return
	days = d
	best = b
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var warm := UIKit.c("accent")
	var bg := Color(warm.r, warm.g * 0.55, warm.b * 0.35, 0.35)
	draw_style_box(UIKit.style(bg, 33, warm.darkened(0.25), 2), Rect2(Vector2.ZERO, size))
	_flame(Vector2(34, size.y * 0.5), 40.0)
	var txt := I18n.t("Streak")
	var col := UIKit.c("text")
	draw_string_outline(font, Vector2(64, size.y * 0.5 - 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 5, Color(0, 0, 0, 0.55))
	draw_string(font, Vector2(64, size.y * 0.5 - 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)
	var val := "%d" % days
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var vcol := warm if days > 0 else UIKit.c("text_dim")
	draw_string_outline(font, Vector2(74 + w, size.y * 0.5 - 4), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 5, Color(0, 0, 0, 0.55))
	draw_string(font, Vector2(74 + w, size.y * 0.5 - 4), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, vcol)
	if best > 0:
		var bt := "best %d" % best
		draw_string(font, Vector2(64, size.y * 0.5 + 22), bt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.c("text_dim"))

## Simple flame: outer orange body + inner bright core.
func _flame(ctr: Vector2, h: float) -> void:
	var w := h * 0.66
	var outer := PackedVector2Array([
		ctr + Vector2(0, -h * 0.58),
		ctr + Vector2(w * 0.40, -h * 0.12),
		ctr + Vector2(w * 0.46, h * 0.22),
		ctr + Vector2(w * 0.20, h * 0.50),
		ctr + Vector2(-w * 0.20, h * 0.50),
		ctr + Vector2(-w * 0.46, h * 0.22),
		ctr + Vector2(-w * 0.40, -h * 0.12),
	])
	draw_colored_polygon(outer, Color("ff7a2f"))
	var core := PackedVector2Array()
	for p in outer: core.append(ctr + (p - ctr) * 0.55 + Vector2(0, h * 0.12))
	draw_colored_polygon(core, Color("ffd166"))
