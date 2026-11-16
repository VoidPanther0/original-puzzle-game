extends Screen
## Launch sequence: 1) game logo  2) studio name + logo  3) loading screen (real load steps)  4) Home.

enum Phase { LOGO, STUDIO, LOADING }
const LOGO_TIME := 2.0
const STUDIO_TIME := 2.2
const FADE := 0.4
const TIPS := [
	"Clear rows AND columns at once for big combos.",
	"Pieces can't be rotated - plan where each one fits.",
	"Tap a stone block twice to crack and destroy it.",
	"Use the Hammer to rescue a crowded board.",
	"Chain clears in a row to build your combo multiplier.",
	"Come back every day for the Daily Challenge and streak rewards.",
]

var _phase := Phase.LOGO
var _t := 0.0
var _progress := 0.0
var _step := 0
var _steps: Array = []
var _tip := ""
var _done := false
var _info := {}

func build() -> void:
	_info = Logo.app_info()
	_tip = TIPS[randi() % TIPS.size()]
	_steps = [
		["Loading pieces", func(): PieceDB.all()],
		["Loading levels", func(): LevelDB.load_data()],
		["Preparing audio", func(): AudioManager.apply_settings()],
		["Loading progress", func(): GameState.check_achievements()],
		["Almost ready", func(): I18n.t("Play")],
	]
	set_process(true)

func on_back() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	# tap/click/key skips the logo + studio cards (never the loading step)
	if _phase != Phase.LOADING and (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
		_t = 0.0
		_phase = Phase.STUDIO if _phase == Phase.LOGO else Phase.LOADING

func _process(delta: float) -> void:
	_t += delta
	match _phase:
		Phase.LOGO:
			if _t > LOGO_TIME:
				_t = 0.0
				_phase = Phase.STUDIO
		Phase.STUDIO:
			if _t > STUDIO_TIME:
				_t = 0.0
				_phase = Phase.LOADING
		Phase.LOADING:
			_load_tick()
	queue_redraw()

func _load_tick() -> void:
	# one real loading step per ~0.25 s so the bar is honest but never flashes by
	if _step < _steps.size() and _t > 0.25 * (_step + 1) - 0.1:
		_steps[_step][1].call()
		_step += 1
	_progress = move_toward(_progress, float(_step) / _steps.size(), delta_clamp())
	if _step >= _steps.size() and _progress >= 0.999 and not _done and _t > 1.6:
		_done = true
		main.go("home")

func delta_clamp() -> float:
	return get_process_delta_time() * 0.9

func _fade(t: float, total: float) -> float:
	return clampf(minf(t / FADE, (total - t) / FADE), 0.0, 1.0)

# ---- text helpers ----------------------------------------------------------------------------
## Width of a string when the letters are spaced out.
func _spaced_width(font: Font, text: String, fs: int, spacing: float) -> float:
	var w := 0.0
	for ch in text:
		w += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + spacing
	return maxf(0.0, w - spacing)

## Draws text with extra letter spacing. Returns the width that was used.
func _spaced(font: Font, text: String, x: float, y: float, fs: int, spacing: float, col: Color) -> float:
	var cx := x
	for ch in text:
		draw_string(font, Vector2(cx, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		cx += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + spacing
	return maxf(0.0, cx - spacing - x)

# ---- phases ----------------------------------------------------------------------------------
func _draw() -> void:
	var font := ThemeDB.fallback_font
	var txt := UIKit.c("text")
	match _phase:
		Phase.LOGO:
			var a := _fade(_t, LOGO_TIME)
			var cs := minf(minf(size.x, size.y) * 0.2, 130.0)
			var ctr := size / 2.0 - Vector2(0, cs * 0.5)
			Logo.draw_mark(self, ctr, cs, clampf(_t / 0.7, 0.0, 1.0))
			var title := str(_info.get("game_title", "Block Falling Blast")).to_upper()
			var fs := int(clampf(size.x * 0.075, 28, 62))
			var w := _spaced_width(font, title, fs, fs * 0.06)
			var c := txt
			c.a = a * clampf((_t - 0.4) / 0.5, 0.0, 1.0)
			var y := ctr.y + cs * 2.1
			draw_string_outline(font, Vector2((size.x - w) / 2.0, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 9, Color(0, 0, 0, c.a * 0.55))
			_spaced(font, title, (size.x - w) / 2.0, y, fs, fs * 0.06, c)
		Phase.STUDIO:
			_draw_studio(font, _fade(_t, STUDIO_TIME))
		Phase.LOADING:
			_draw_loading(font, clampf(_t / 0.3, 0.0, 1.0))

## Studio card: mark, tagline, studio name with a gradient underline.
func _draw_studio(font: Font, a: float) -> void:
	var accent := UIKit.c("accent")
	var ctr := Vector2(size.x * 0.5, size.y * 0.42)
	# mark: rounded frame + diamond
	var box := Rect2(ctr - Vector2(58, 58), Vector2(116, 116))
	var frame := UIKit.style(Color(1, 1, 1, 0.07), 30, Color(accent.r, accent.g, accent.b, 0.85), 3)
	frame.bg_color.a *= a
	frame.border_color.a *= a
	draw_style_box(frame, box)
	var col := accent
	col.a = a
	draw_colored_polygon(PackedVector2Array([ctr + Vector2(0, -28), ctr + Vector2(28, 0), ctr + Vector2(0, 28), ctr + Vector2(-28, 0)]), col)
	var tag := str(_info.get("studio_tagline", "Presents")).to_upper()
	var tfs := 24
	var tcol := UIKit.c("text_dim")
	tcol.a = a * 0.9
	var tw := _spaced_width(font, tag, tfs, tfs * 0.35)
	_spaced(font, tag, (size.x - tw) * 0.5, ctr.y + 96, tfs, tfs * 0.35, tcol)
	# studio name
	var name := str(_info.get("studio_name", "Your Studio Name")).to_upper()
	var fs := int(clampf(size.x * 0.062, 24, 48))
	var ncol := UIKit.c("text")
	ncol.a = a
	var w := _spaced_width(font, name, fs, fs * 0.12)
	var ny := ctr.y + 152
	draw_string_outline(font, Vector2((size.x - w) * 0.5, ny), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color(0, 0, 0, a * 0.5))
	_spaced(font, name, (size.x - w) * 0.5, ny, fs, fs * 0.12, ncol)
	# underline: a short gradient bar
	var bw := w * 0.8
	var bx := (size.x - bw) * 0.5
	var by := ny + 18.0
	var steps := 28
	for i in steps:
		var f := float(i) / float(steps - 1)
		var c2 := accent.lerp(Color("7c5cff"), f)
		c2.a = a * (1.0 - absf(f - 0.5) * 1.2)
		draw_rect(Rect2(bx + bw * f, by, bw / float(steps) + 1.0, 5.0), c2)

## Loading screen: logo, step name, rounded progress bar and a tip.
func _draw_loading(font: Font, a: float) -> void:
	var accent := UIKit.c("accent")
	var cs := minf(minf(size.x, size.y) * 0.11, 76.0)
	Logo.draw_mark(self, Vector2(size.x * 0.5, size.y * 0.26), cs, 1.0)
	# step name
	var step_label := "Loading..."
	if _step < _steps.size(): step_label = str(_steps[_step][0])
	var fs := 30
	var scol := UIKit.c("text")
	scol.a = a
	var sw := font.get_string_size(step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2((size.x - sw) * 0.5, size.y * 0.42), step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, scol)
	# bar
	var bw := minf(size.x * 0.72, 540.0)
	var bar := Rect2(Vector2((size.x - bw) * 0.5, size.y * 0.47), Vector2(bw, 20))
	draw_style_box(UIKit.style(Color(0, 0, 0, 0.4), 10), bar)
	if _progress > 0.0:
		var fill := Rect2(bar.position, Vector2(maxf(20.0, bw * _progress), bar.size.y))
		draw_style_box(UIKit.style(accent, 10), fill)
		# soft top highlight (a clean bar, no moving blob)
		draw_rect(Rect2(fill.position + Vector2(6, 3), Vector2(maxf(0.0, fill.size.x - 12), 4)), Color(1, 1, 1, 0.35 * a))
	# percentage
	var pct := "%d%%" % int(_progress * 100.0)
	var pcol := accent
	pcol.a = a
	var pw := font.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	draw_string_outline(font, Vector2((size.x - pw) * 0.5, bar.position.y + 66), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 7, Color(0, 0, 0, a * 0.5))
	draw_string(font, Vector2((size.x - pw) * 0.5, bar.position.y + 66), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, pcol)
	# tip
	var tipw := font.get_string_size(_tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var tc := UIKit.c("text_dim")
	tc.a *= a
	draw_string(font, Vector2(maxf(12.0, (size.x - tipw) * 0.5), size.y * 0.9), _tip, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 22, tc)
