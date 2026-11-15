class_name UiTheme
extends RefCounted
## Visual identity for Block Fall: deep indigo night, glowing teal accent,
## and seven "gem" block colours. Everything is drawn in code, so the game
## needs no image assets.

const BG_TOP: Color = Color(0.105, 0.088, 0.250)
const BG_BOTTOM: Color = Color(0.055, 0.045, 0.140)
const PANEL: Color = Color(0.150, 0.125, 0.330)
const PANEL_LIGHT: Color = Color(0.215, 0.185, 0.450)
const CELL_EMPTY: Color = Color(0.095, 0.080, 0.215)
const ACCENT: Color = Color(0.208, 0.878, 0.760)
const ACCENT_DARK: Color = Color(0.100, 0.640, 0.560)
const TEXT: Color = Color(0.945, 0.935, 1.000)
const TEXT_DIM: Color = Color(0.620, 0.595, 0.800)
const DANGER: Color = Color(1.000, 0.365, 0.478)
const GOLD: Color = Color(1.000, 0.820, 0.400)

static var _block_colors: Array[Color] = [
	Color(0.960, 0.345, 0.420),  # 1 coral
	Color(1.000, 0.640, 0.200),  # 2 amber
	Color(0.980, 0.850, 0.250),  # 3 sun
	Color(0.330, 0.850, 0.470),  # 4 mint
	Color(0.220, 0.720, 0.980),  # 5 sky
	Color(0.560, 0.450, 1.000),  # 6 violet
	Color(0.940, 0.420, 0.850),  # 7 orchid
]
static var _block_styles: Dictionary = {}
static var _flat_cache: Dictionary = {}


static func block_color(id: int) -> Color:
	return _block_colors[clampi(id - 1, 0, _block_colors.size() - 1)]


## Draws one gem-like block into `rect` on any CanvasItem.
static func draw_block(item: CanvasItem, rect: Rect2, color_id: int) -> void:
	var sb: StyleBoxFlat = _block_styles.get(color_id)
	if sb == null:
		sb = StyleBoxFlat.new()
		var base: Color = block_color(color_id)
		sb.bg_color = base
		sb.border_color = base.darkened(0.35)
		_block_styles[color_id] = sb
	var radius: int = int(rect.size.x * 0.22)
	sb.set_corner_radius_all(radius)
	sb.border_width_bottom = maxi(2, int(rect.size.y * 0.09))
	item.draw_style_box(sb, rect)
	var gloss := Rect2(
		rect.position + rect.size * Vector2(0.16, 0.12),
		rect.size * Vector2(0.68, 0.22))
	item.draw_rect(gloss, Color(1, 1, 1, 0.24))


## Draws a flat rounded rectangle (panels, empty cells).
static func draw_round_rect(item: CanvasItem, rect: Rect2, color: Color, radius: float) -> void:
	var sb: StyleBoxFlat = _flat_cache.get(color)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = color
		_flat_cache[color] = sb
	sb.set_corner_radius_all(int(radius))
	item.draw_style_box(sb, rect)


static func _box(color: Color, radius: int, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	return sb


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 30

	theme.set_color("font_color", "Label", TEXT)

	# Buttons
	theme.set_stylebox("normal", "Button", _box(PANEL_LIGHT, 22))
	theme.set_stylebox("hover", "Button", _box(PANEL_LIGHT.lightened(0.08), 22))
	theme.set_stylebox("pressed", "Button", _box(PANEL.darkened(0.15), 22))
	theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), 22, ACCENT, 3))
	theme.set_stylebox("disabled", "Button", _box(PANEL.darkened(0.1), 22))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", TEXT)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM)
	theme.set_font_size("font_size", "Button", 32)

	# Primary button variation
	theme.set_type_variation("PrimaryButton", "Button")
	theme.set_stylebox("normal", "PrimaryButton", _box(ACCENT, 22))
	theme.set_stylebox("hover", "PrimaryButton", _box(ACCENT.lightened(0.12), 22))
	theme.set_stylebox("pressed", "PrimaryButton", _box(ACCENT_DARK, 22))
	theme.set_stylebox("focus", "PrimaryButton", _box(Color(0, 0, 0, 0), 22, TEXT, 3))
	theme.set_color("font_color", "PrimaryButton", Color(0.04, 0.10, 0.12))
	theme.set_color("font_hover_color", "PrimaryButton", Color(0.04, 0.10, 0.12))
	theme.set_color("font_pressed_color", "PrimaryButton", Color(0.04, 0.10, 0.12))
	theme.set_color("font_focus_color", "PrimaryButton", Color(0.04, 0.10, 0.12))

	# Danger button variation
	theme.set_type_variation("DangerButton", "Button")
	theme.set_stylebox("normal", "DangerButton", _box(DANGER.darkened(0.35), 22))
	theme.set_stylebox("hover", "DangerButton", _box(DANGER.darkened(0.25), 22))
	theme.set_stylebox("pressed", "DangerButton", _box(DANGER.darkened(0.5), 22))

	# Check buttons used for toggles
	theme.set_font_size("font_size", "CheckButton", 30)
	theme.set_color("font_color", "CheckButton", TEXT)
	theme.set_color("font_hover_color", "CheckButton", TEXT)
	theme.set_color("font_pressed_color", "CheckButton", TEXT)
	theme.set_color("font_focus_color", "CheckButton", TEXT)
	theme.set_constant("h_separation", "CheckButton", 16)
	theme.set_stylebox("normal", "CheckButton", _box(Color(0, 0, 0, 0), 14))
	theme.set_stylebox("hover", "CheckButton", _box(Color(1, 1, 1, 0.04), 14))
	theme.set_stylebox("pressed", "CheckButton", _box(Color(0, 0, 0, 0), 14))
	theme.set_stylebox("focus", "CheckButton", _box(Color(0, 0, 0, 0), 14, ACCENT, 2))

	# Slider
	var track := StyleBoxFlat.new()
	track.bg_color = CELL_EMPTY
	track.set_corner_radius_all(8)
	track.content_margin_top = 8
	track.content_margin_bottom = 8
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.set_corner_radius_all(8)
	fill.content_margin_top = 8
	fill.content_margin_bottom = 8
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill)

	# Panels
	theme.set_stylebox("panel", "PanelContainer", _box(PANEL, 32, PANEL_LIGHT, 3))
	return theme


## Fades `node` in. Handy when swapping screens.
static func fade_in(node: CanvasItem, seconds: float = 0.2) -> void:
	node.modulate.a = 0.0
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, seconds)
