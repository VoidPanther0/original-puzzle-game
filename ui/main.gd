extends Control
## Screen manager: navigation, transitions, toasts, themed animated background, Android back button.

const SCREENS := {
	"splash": "res://ui/screens/splash.gd", "home": "res://ui/screens/home.gd",
	"game": "res://ui/screens/game.gd", "adventure": "res://ui/screens/adventure.gd",
	"levels": "res://ui/screens/levels.gd", "level_complete": "res://ui/screens/level_complete.gd",
	"daily": "res://ui/screens/daily.gd", "season": "res://ui/screens/season.gd",
	"events": "res://ui/screens/events.gd", "shop": "res://ui/screens/shop.gd",
	"inventory": "res://ui/screens/inventory.gd", "leaderboard": "res://ui/screens/leaderboard.gd",
	"profile": "res://ui/screens/profile.gd", "settings": "res://ui/screens/settings.gd",
	"language": "res://ui/screens/language.gd",
	"privacy": "res://ui/screens/privacy.gd", "terms": "res://ui/screens/terms.gd",
	"support": "res://ui/screens/support.gd", "achievements": "res://ui/screens/achievements.gd",
}

var current: Screen
var current_name := ""
var _holder: Control
var _toast: Label
var _bg: Control
var _busy := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_fonts()
	_bg = Background.new()
	add_child(_bg)
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_holder)
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_stylebox_override("normal", UIKit.style(Color(0, 0, 0, 0.8), 22))
	_toast.add_theme_color_override("font_color", Color.WHITE)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position.y = -160
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)
	get_tree().root.size_changed.connect(_fix_toast)
	get_tree().set_auto_accept_quit(false)
	apply_display_settings()
	AudioManager.apply_settings()
	if SaveManager.recovered:
		call_deferred("toast", "Save file was damaged - restored a backup")
	go("splash", {}, false)

## The main font has no Devanagari / Arabic glyphs, so those two are added as fallbacks.
## Without them the Hindi and Arabic translations would show as empty boxes.
func _setup_fonts() -> void:
	var base := ThemeDB.fallback_font
	if base == null: return
	var fallbacks: Array[Font] = []
	for n in ["NotoSansDevanagari-SemiBold", "NotoSansArabic-SemiBold"]:
		var path := "res://assets/fonts/%s.ttf" % n
		if not ResourceLoader.exists(path): continue
		var f: Font = load(path)
		if f != null: fallbacks.append(f)
	if not fallbacks.is_empty():
		base.fallbacks = fallbacks

func apply_display_settings() -> void:
	if Platform.is_desktop and not Platform.is_web:
		if bool(SaveManager.get_setting("fullscreen", false)):
			Platform.set_fullscreen(true)
		else:
			Platform.fit_window()      # start inside the screen; player may maximise / fullscreen

func _fix_toast() -> void:
	_toast.position.x = (size.x - _toast.size.x) / 2.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.save_now()
		get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_back()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F11 and Platform.is_desktop:
		var on := not bool(SaveManager.get_setting("fullscreen", false))
		SaveManager.set_setting("fullscreen", on)
		Platform.set_fullscreen(on)
		if not on: Platform.fit_window()

func _back() -> void:
	if current and not _busy: current.on_back()

## Switches screen. Not a coroutine: the fade-out is a tween whose `finished` signal does the swap,
## so callers can use it from any button handler without `await`.
func go(name: String, args: Dictionary = {}, animate: bool = true) -> void:
	if _busy or not SCREENS.has(name): return
	_busy = true
	if current != null and animate:
		var tw := create_tween()
		tw.tween_property(current, "modulate:a", 0.0, 0.12)
		tw.finished.connect(_swap.bind(name, args, animate))
	else:
		_swap(name, args, animate)

func _swap(name: String, args: Dictionary, animate: bool) -> void:
	if current != null:
		current.queue_free()
		current = null
	var scr: Screen = load(SCREENS[name]).new()
	scr.main = self
	scr.args = args
	current_name = name
	current = scr
	_holder.add_child(scr)
	if animate:
		scr.modulate.a = 0.0
		create_tween().tween_property(scr, "modulate:a", 1.0, 0.16)
	_busy = false

func toast(msg: String) -> void:
	_toast.text = "  " + I18n.t(msg) + "  "
	_toast.reset_size()
	_fix_toast()
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.8)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)

## Re-applies the theme to the current screen after a theme change.
func retheme() -> void:
	_bg.queue_redraw()
	if current: go(current_name, current.args, false)


class Background extends Control:
	var _t := 0.0
	func _init() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _acc := 0.0
	func _process(delta: float) -> void:
		_t += delta * 0.15
		_acc += delta
		if _acc >= 0.05:      # ~20 fps is plenty for slow-drifting blobs; saves battery / GPU
			_acc = 0.0
			queue_redraw()
	func _draw() -> void:
		var top := UIKit.c("bg_top")
		var bot := UIKit.c("bg_bottom")
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
			PackedColorArray([top, top, bot, bot]))
		var tint := Color(1, 1, 1, 0.05) if UIKit.is_dark() else Color(0.5, 0.4, 1, 0.07)
		for i in 7:
			var a := _t + i * 1.7
			var p := Vector2(size.x * (0.5 + 0.45 * sin(a * 0.7 + i)), size.y * (0.5 + 0.48 * cos(a * 0.5 + i * 2.0)))
			draw_circle(p, 60.0 + 40.0 * ((i * 37) % 5), tint)
