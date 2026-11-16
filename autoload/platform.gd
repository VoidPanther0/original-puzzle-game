extends Node
## Platform adapter: ONE place that knows which OS/export target we are on.
## Gameplay code never calls OS.* directly; it asks Platform.

var is_android := false
var is_web := false
var is_windows := false
var is_desktop := false
var is_mobile := false

func _ready() -> void:
	is_android = OS.has_feature("android")
	is_web = OS.has_feature("web")
	is_windows = OS.has_feature("windows")
	is_desktop = OS.has_feature("pc")
	is_mobile = OS.has_feature("mobile") or is_android

func name_id() -> String:
	if is_android: return "android"
	if is_web: return "web"
	if is_windows: return "windows"
	return "other"

## Native mobile SDKs (ads, billing, push) exist only on Android.
func supports_native_sdks() -> bool:
	return is_android

func vibrate(ms: int = 20) -> void:
	if is_android and bool(SaveManager.get_setting("haptics", true)):
		Input.vibrate_handheld(ms)

func set_fullscreen(on: bool) -> void:
	if not is_desktop or is_web: return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

## Resizes the window but never lets it exceed the usable desktop area (taskbar excluded), and
## keeps the title bar (minimize / maximize / close) fully on screen.
func set_window_size(size: Vector2i) -> void:
	if not is_desktop or is_web: return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var deco := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	var max_size := Vector2i(int(area.size.x * 0.96) - deco.x, int(area.size.y * 0.96) - deco.y)
	var s := Vector2i(mini(size.x, max_size.x), mini(size.y, max_size.y))
	DisplayServer.window_set_min_size(Vector2i(320, 480))
	DisplayServer.window_set_size(s)
	var total := s + deco
	var pos := area.position + (area.size - total) / 2
	# deco.y includes the title bar, which sits ABOVE the client area: keep it inside the screen
	DisplayServer.window_set_position(Vector2i(maxi(area.position.x, pos.x), maxi(area.position.y, pos.y) + deco.y / 2))

## Portrait 9:16 window that always fits the screen (default start-up size on desktop).
func fit_window() -> void:
	if not is_desktop or is_web: return
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var h := mini(1280, int(area.size.y * 0.86))
	set_window_size(Vector2i(int(h * 9.0 / 16.0), h))

func open_url(url: String) -> void:
	OS.shell_open(url)

func quit_game() -> void:
	if is_web: return
	get_tree().quit()
