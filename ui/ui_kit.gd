class_name UIKit
extends RefCounted
## Theme colours + factory helpers for consistent, code-built UI (no external art needed).

const BLOCK_COLORS := [
	Color("00000000"),
	Color("ff6b6b"), Color("ffa94d"), Color("ffd43b"), Color("51cf66"),
	Color("20c997"), Color("4dabf7"), Color("748ffc"), Color("f06595"),
	Color("868e96"),  # 9 = stone (level pre-filled)
]

const ART := "res://assets/ui/"
static var _tex_cache := {}

## Cached art texture from assets/ui (sliced from the reference sprite sheet); null if missing.
static func tex(name: String) -> Texture2D:
	if _tex_cache.has(name): return _tex_cache[name]
	var path := ART + name + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[name] = t
	return t

## 9-slice pill button skin (art is pre-scaled to 76 px tall; only the caps stay fixed).
static func art_style(name: String, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var t := tex(name)
	if t == null: return null
	var s := StyleBoxTexture.new()
	s.texture = t
	s.texture_margin_left = 36
	s.texture_margin_right = 36
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 8
	s.content_margin_bottom = 12
	s.modulate_color = tint
	return s

## Square art button (pause etc.): blank blue/purple/red/green tile with `text` on top.
static func square_button(text: String, art: String = "sq_blue", size: Vector2 = Vector2(76, 76)) -> Button:
	var b := button(text, "secondary", size)
	var t := tex(art)
	if t == null: return b
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxTexture.new()
		sb.texture = t
		sb.texture_margin_left = 26
		sb.texture_margin_right = 26
		sb.texture_margin_top = 26
		sb.texture_margin_bottom = 26
		sb.modulate_color = {"normal": Color.WHITE, "hover": Color(1.12, 1.12, 1.12), "pressed": Color(0.8, 0.8, 0.85), "disabled": Color(0.5, 0.5, 0.55, 0.8)}[st]
		b.add_theme_stylebox_override(st, sb)
	return b

## Swaps a CheckButton's switch for the ON/OFF art (no-op if the art is missing).
static func skin_toggle(cb: CheckButton) -> void:
	var on := tex("toggle_on")
	var off := tex("toggle_off")
	if on == null or off == null: return
	for k in ["checked", "checked_mirrored"]: cb.add_theme_icon_override(k, on)
	for k in ["unchecked", "unchecked_mirrored"]: cb.add_theme_icon_override(k, off)
	for k in ["checked_disabled", "checked_disabled_mirrored"]: cb.add_theme_icon_override(k, on)
	for k in ["unchecked_disabled", "unchecked_disabled_mirrored"]: cb.add_theme_icon_override(k, off)

static func is_dark() -> bool:
	return str(SaveManager.get_setting("theme", "dark")) == "dark"

static func c(name: String) -> Color:
	var dark := is_dark()
	match name:
		"bg_top": return Color("1b1740") if dark else Color("dfe9ff")
		"bg_bottom": return Color("3d2b86") if dark else Color("fbe7ff")
		"panel": return Color(1, 1, 1, 0.09) if dark else Color(1, 1, 1, 0.75)
		"panel_solid": return Color("2a2566") if dark else Color("ffffff")
		"text": return Color("ffffff") if dark else Color("2b2a4a")
		"text_dim": return Color(1, 1, 1, 0.65) if dark else Color(0.17, 0.16, 0.29, 0.65)
		"accent": return Color("ffb84d")
		"primary": return Color("7c5cff")
		"secondary": return Color("3a3f80") if dark else Color("c9d4ff")
		"danger": return Color("ff5d73")
		"good": return Color("3ddc97")
		"cell": return Color(1, 1, 1, 0.08) if dark else Color(0.15, 0.1, 0.4, 0.09)
		"board": return Color(0.05, 0.04, 0.18, 0.55) if dark else Color(1, 1, 1, 0.7)
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

static func button(text: String, kind: String = "primary", min_size: Vector2 = Vector2(0, 76)) -> Button:
	var b := Button.new()
	b.text = I18n.t(text)
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 28)
	var base: Color = c(kind) if kind in ["primary", "secondary", "danger", "good", "accent"] else c("secondary")
	var txt: Color = Color("2b1b00") if kind == "accent" else Color.WHITE
	if kind == "secondary" and not is_dark(): txt = c("text")
	b.add_theme_stylebox_override("normal", style(base, 28, base.lightened(0.25), 2))
	b.add_theme_stylebox_override("hover", style(base.lightened(0.12), 28, base.lightened(0.35), 2))
	b.add_theme_stylebox_override("pressed", style(base.darkened(0.2), 28))
	b.add_theme_stylebox_override("disabled", style(base.darkened(0.4) if is_dark() else base.lightened(0.4), 28))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, txt)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	var art := {"primary": "btn_purple", "secondary": "btn_blue", "accent": "btn_blue_gold", "danger": "btn_red", "good": "btn_green"}.get(kind, "") as String
	if art != "" and tex(art) != null:
		b.add_theme_stylebox_override("normal", art_style(art))
		b.add_theme_stylebox_override("hover", art_style(art, Color(1.12, 1.12, 1.12)))
		b.add_theme_stylebox_override("pressed", art_style(art, Color(0.8, 0.8, 0.85)))
		b.add_theme_stylebox_override("disabled", art_style(art, Color(0.5, 0.5, 0.55, 0.8)))
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.3, 0.8))
		b.add_theme_constant_override("outline_size", 6)
	b.pressed.connect(func(): AudioManager.play("click"))
	return b

static func label(text: String, size: int = 28, color_name: String = "text", align: int = HORIZONTAL_ALIGNMENT_LEFT, translate: bool = true) -> Label:
	var l := Label.new()
	l.text = I18n.t(text) if translate else text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c(color_name))
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## Round "<" back button used in every page header.
static func back_button(min_size: Vector2 = Vector2(74, 64)) -> Button:
	var b := Button.new()
	b.text = "<"
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 38)
	var base := c("secondary")
	b.add_theme_stylebox_override("normal", style(base, 22, base.lightened(0.25), 2))
	b.add_theme_stylebox_override("hover", style(base.lightened(0.12), 22, base.lightened(0.35), 2))
	b.add_theme_stylebox_override("pressed", style(base.darkened(0.2), 22))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, c("text"))
	b.pressed.connect(func(): AudioManager.play("click"))
	return b

static func panel(color: Color = Color(0, 0, 0, 0), radius: int = 28) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(color if color.a > 0.0 else c("panel"), radius))
	return p

static func spacer(h: int = 12) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s
