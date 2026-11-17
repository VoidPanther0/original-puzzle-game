class_name Logo
extends Control
## Original procedurally drawn game logo (2x2 glossy blocks + title). `reveal` 0..1 animates it in.
## The control reports the height it needs, so the title never overlaps the next element.

const MAX_BLOCK := 110.0

var reveal := 1.0
var show_title := true

static func app_info() -> Dictionary:
	var f := FileAccess.open("res://config/app.json", FileAccess.READ)
	if f == null: return {}
	var p = JSON.parse_string(f.get_as_text())
	return p if typeof(p) == TYPE_DICTIONARY else {}

func _init(title: bool = true) -> void:
	show_title = title
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 360 if title else 200)

## Size of one block for a given width.
static func block_size(width: float) -> float:
	return minf(maxf(width, 1.0) * 0.2, MAX_BLOCK)

## Height the logo needs for a given width (blocks + title).
static func content_height(width: float, with_title: bool = true) -> float:
	var cs := block_size(width)
	if not with_title: return cs * 2.1
	var fs := clampf(maxf(width, 1.0) * 0.085, 30.0, 60.0)
	return cs * 3.55 + fs * 0.42

func _get_minimum_size() -> Vector2:
	var w := size.x
	if w <= 1.0:
		var vp := get_viewport_rect().size
		w = minf(vp.x, Screen.MAX_WIDTH) - 24.0
	return Vector2(0, content_height(w, show_title))

func set_reveal(v: float) -> void:
	reveal = v
	queue_redraw()

## Draws the block mark centred at `ctr` with block size `cs`.
static func draw_mark(c: CanvasItem, ctr: Vector2, cs: float, k: float = 1.0) -> void:
	var cols := [1, 3, 8, 5]
	for i in 4:
		var off := Vector2(i % 2, i / 2) * cs * 1.08 - Vector2(cs * 0.54, cs * 0.54)
		var s := clampf(k * 1.5 - i * 0.18, 0.0, 1.0)
		var r := Rect2(ctr + off + Vector2(cs, cs) * (1.0 - s) / 2.0, Vector2(cs, cs) * s)
		var sb := UIKit.flat(UIKit.BLOCK_COLORS[cols[i]], int(cs * 0.16), maxi(2, int(cs * 0.07)))
		c.draw_style_box(sb, r)

func _draw() -> void:
	var cs := block_size(size.x)
	var ctr := Vector2(size.x / 2.0, cs * 1.25)
	draw_mark(self, ctr, cs, reveal)
	if show_title:
		var font := ThemeDB.fallback_font
		var title: String = str(app_info().get("game_title", "Block Falling Blast")).to_upper()
		var fs := int(clampf(size.x * 0.085, 30, 60))
		var col := UIKit.c("text")
		col.a = clampf((reveal - 0.4) / 0.6, 0.0, 1.0)
		var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2((size.x - w) / 2.0, cs * 3.55)
		draw_string(font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
