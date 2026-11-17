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
	var x := _pill(0.0, "coins", Color("f2c14e"))
	x = _pill(x + 10.0, "gems", Color("4fb4e8"))
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
	draw_style_box(UIKit.style(UIKit.c("panel"), 14), r)
	var iy := r.position.y + (PILL_H - ICON) * 0.5
	var ix := x + pad
	Icons.draw(self, "coin" if kind == "coins" else "gem", Rect2(ix, iy, ICON, ICON), tint)
	var tx := x + pad + ICON + 5.0
	var ty := r.position.y + PILL_H * 0.5 + fs * 0.36
	var col := UIKit.c("text")
	draw_string(font, Vector2(tx, ty), value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	return x + w
