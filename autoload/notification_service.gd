extends Node
## Notification adapter. Real scheduling is Android-only and needs a local-notification / FCM plugin
## (NOTIFICATIONS in docs). On Windows/Web every call is a safe no-op so those builds are unaffected.
## Home-screen widgets need native Android code (AppWidgetProvider) and are NOT implemented here.

var _plugin = null
const PLUGIN_NAME := "LocalNotification"

func _ready() -> void:
	if Platform.is_android and Engine.has_singleton(PLUGIN_NAME):
		_plugin = Engine.get_singleton(PLUGIN_NAME)

func is_supported() -> bool:
	return _plugin != null

func request_permission() -> void:
	if _plugin and _plugin.has_method("request_permission"): _plugin.request_permission()

## Daily-challenge reminder at a local hour; streak reminder in the evening.
func refresh_schedule() -> void:
	if _plugin == null: return
	cancel_all()
	if bool(SaveManager.get_setting("notify_daily", true)):
		_schedule(1, "Daily challenge ready!", "Today's puzzle is waiting.", 24 * 3600)
	if bool(SaveManager.get_setting("notify_streak", true)) and GameState.current_streak() > 0:
		_schedule(2, "Keep your streak alive", "Play today to extend your %d-day streak." % GameState.current_streak(), 20 * 3600)

func _schedule(id: int, title: String, body: String, delay_sec: int) -> void:
	if _plugin and _plugin.has_method("schedule"):
		_plugin.schedule(id, title, body, delay_sec)   # adapt to the chosen plugin's signature

func cancel_all() -> void:
	if _plugin and _plugin.has_method("cancel_all"): _plugin.cancel_all()
