class_name UIKit
extends RefCounted
## Theme colours + factory helpers for consistent, code-built UI (no external art needed).

const BLOCK_COLORS := [
	Color("00000000"),
	Color("e5484d"), Color("f0883a"), Color("f2c14e"), Color("4caf7a"),
	Color("2bb3a8"), Color("4a90e2"), Color("7a6ff0"), Color("e56fa3"),
	Color("6b7280"),  # 9 = stone (level pre-filled)
]

static func is_dark() -> bool:
	return str(SaveManager.get_setting("theme", "dark")) == "dark"

static func c(name: String) -> Color:
	var dark := is_dark()
	match name:
		"bg_top": return Color("14171f") if dark else Color("f4efe6")
		"bg_bottom": return Color("14171f") if dark else Color("f4efe6")
		"panel": return Color("1f2430") if dark else Color("ffffff")
		"panel_solid": return Color("1f2430") if dark else Color("ffffff")
		"text": return Color("eef0f4") if dark else Color("22252d")
		"text_dim": return Color("9aa1b0") if dark else Color("6b7080")
		"accent": return Color("ff7a59")
		"primary": return Color("2bb3a8")
		"secondary": return Color("2d3443") if dark else Color("e3ddd0")
		"danger": return Color("e5484d")
		"good": return Color("4caf7a")
		"cell": return Color("262c3a") if dark else Color("ece6da")
		"board": return Color("1a1e29") if dark else Color("e8e1d3")
	return Color.MAGENTA

static func style(color: Color, radius: int = 24, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_w)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

## Flat "chunky" box: solid fill with a darker bottom edge (no outline glow).
static func flat(color: Color, radius: int = 14, lip: int = 5) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.border_width_bottom = lip
	sb.border_color = color.darkened(0.3)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8 + lip
	return sb

static func button(text: String, kind: String = "primary", min_size: Vector2 = Vector2(0, 76)) -> Button:
	var b := Button.new()
	b.text = I18n.t(text)
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 28)
	var base: Color = c(kind) if kind in ["primary", "secondary", "danger", "good", "accent"] else c("secondary")
	var txt: Color = Color("1d1208") if kind == "accent" else Color.WHITE
	if kind == "secondary": txt = c("text")
	b.add_theme_stylebox_override("normal", flat(base))
	b.add_theme_stylebox_override("hover", flat(base.lightened(0.1)))
	b.add_theme_stylebox_override("pressed", flat(base.darkened(0.12), 14, 1))
	b.add_theme_stylebox_override("disabled", flat(base.darkened(0.35) if is_dark() else base.lightened(0.45)))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, txt)
	b.add_theme_color_override("font_disabled_color", Color(txt.r, txt.g, txt.b, 0.4))
	b.pressed.connect(func(): AudioManager.play("click"))
	return b

## Square button that shows a code-drawn icon (back, pause, close...).
static func icon_button(icon_name: String, size: Vector2 = Vector2(68, 68), kind: String = "secondary") -> Button:
	var b := button("", kind, size)
	var ic := Icons.IconRect.new(icon_name, c("text") if kind == "secondary" else Color.WHITE)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	ic.offset_bottom -= 3
	b.add_child(ic)
	return b

static func label(text: String, size: int = 28, color_name: String = "text", align: int = HORIZONTAL_ALIGNMENT_LEFT, translate: bool = true) -> Label:
	var l := Label.new()
	l.text = I18n.t(text) if translate else text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c(color_name))
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## Back button used in every page header.
static func back_button(min_size: Vector2 = Vector2(74, 64)) -> Button:
	return icon_button("back", Vector2(68, 64))

static func panel(color: Color = Color(0, 0, 0, 0), radius: int = 28) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(color if color.a > 0.0 else c("panel"), mini(radius, 18)))
	return p

static func spacer(h: int = 12) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s
