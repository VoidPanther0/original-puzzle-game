class_name CurrencyBar
extends Control
## Coins + gems. Every currency sits in its own pill with a soft tint and a bold number,
## so the values read clearly even on the small phone layout.

const ICON := 42.0
const PILL_H := 50.0

func _init() -> void:
	custom_minimum_size = Vector2(300, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	GameState.changed.connect(queue_redraw)

func _draw() -> void:
	var x := _pill(0.0, "coins", UIKit.c("accent"))
	x = _pill(x + 10.0, "gems", Color("5ad1ff"))
	custom_minimum_size.x = x

## One currency pill. Returns the x position right after it.
func _pill(x: float, kind: String, tint: Color) -> float:
	var font := ThemeDB.fallback_font
	var value := str(GameState.currency(kind))
	var fs := 29
	var tw := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pad := 11.0
	var w := pad + ICON + 5.0 + tw + pad
	var r := Rect2(Vector2(x, (size.y - PILL_H) * 0.5), Vector2(w, PILL_H))
	draw_style_box(UIKit.style(Color(tint.r, tint.g, tint.b, 0.16), 25, Color(tint.r, tint.g, tint.b, 0.5), 2), r)
	var iy := r.position.y + (PILL_H - ICON) * 0.5
	var ix := x + pad
	if kind == "coins":
		var coin_t := UIKit.tex("coin")
		if coin_t != null:
			draw_texture_rect(coin_t, Rect2(ix, iy, 40, 42), false)
		else:
			draw_circle(Vector2(ix + 20, iy + 21), 19, Color("ffc83d"))
			draw_circle(Vector2(ix + 20, iy + 21), 13, Color("ffe08a"))
	else:
		var gem_t := UIKit.tex("gem_icon")
		if gem_t != null:
			draw_texture_rect(gem_t, Rect2(ix, iy - 1, 42, 42), false)
		else:
			var c := Vector2(ix + 21, iy + 21)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -20), c + Vector2(19, 0), c + Vector2(0, 20), c + Vector2(-19, 0)]), Color("4fd1ff"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -20), c + Vector2(19, 0), c + Vector2(0, 2), c + Vector2(-19, 0)]), Color("a5ecff"))
	var tx := x + pad + ICON + 5.0
	var ty := r.position.y + PILL_H * 0.5 + fs * 0.36
	var col := UIKit.c("text")
	draw_string_outline(font, Vector2(tx, ty), value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.55))
	draw_string(font, Vector2(tx, ty), value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	return x + w
