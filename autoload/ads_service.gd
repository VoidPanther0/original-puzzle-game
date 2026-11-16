extends Node
## Ad abstraction (banner / interstitial / rewarded).
##  * Android: talks to a Godot Android AdMob-style plugin singleton IF it is installed. The exact
##    plugin method names differ between plugins, so the calls live in the three _android_* functions
##    below; adapt them to the plugin you pick (see ADS_SETUP.md). They are UNTESTED here because no
##    plugin/ad-unit IDs were available.
##  * Test mode (config/ads.json "test_mode": true): shows a clearly labelled TEST AD overlay and grants
##    rewards, so flows can be exercised on any platform.
##  * Windows / Web / Android-without-plugin in production: ads are unavailable; UI hides ad buttons.
## Ads are never shown during core gameplay: interstitials only at game over / level end.

signal availability_changed

var cfg := {"test_mode": true, "android": {}, "interstitial_min_interval_sec": 180, "interstitial_min_games_between": 3}
var _plugin = null
var _last_interstitial := -99999.0
var _games_since := 0
var _overlay: CanvasLayer

func _ready() -> void:
	var f := FileAccess.open("res://config/ads.json", FileAccess.READ)
	if f:
		var p = JSON.parse_string(f.get_as_text())
		if typeof(p) == TYPE_DICTIONARY: cfg.merge(p, true)
	if Platform.is_android:
		var name := str(cfg.android.get("plugin_singleton", ""))
		if name != "" and Engine.has_singleton(name):
			_plugin = Engine.get_singleton(name)

func has_consent() -> bool:
	return str(SaveManager.get_setting("consent", "unknown")) == "granted"

func consent_known() -> bool:
	return str(SaveManager.get_setting("consent", "unknown")) != "unknown"

func set_consent(granted: bool) -> void:
	SaveManager.set_setting("consent", "granted" if granted else "denied")
	availability_changed.emit()

## True if a real or test rewarded ad can be shown right now.
func rewarded_available() -> bool:
	if cfg.test_mode: return true
	return _plugin != null and Platform.is_android and has_consent()

func interstitial_available() -> bool:
	if GameState.ads_removed(): return false
	if cfg.test_mode: return true
	return _plugin != null and Platform.is_android and has_consent()

func banner_available() -> bool:
	return not GameState.ads_removed() and (cfg.test_mode or (_plugin != null and has_consent()))

## Awaitable: `var ok: bool = await AdsService.show_rewarded("continue")`. Returns true if rewarded.
func show_rewarded(placement: String) -> bool:
	if not rewarded_available(): return false
	if cfg.test_mode: return await _test_overlay("TEST REWARDED AD", 2.5)
	return await _android_rewarded(placement)

## Awaitable; frequency-capped and skipped for ad-free users. Never call mid-game.
func maybe_show_interstitial() -> bool:
	_games_since += 1
	if not interstitial_available(): return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_interstitial < float(cfg.interstitial_min_interval_sec): return false
	if _games_since < int(cfg.interstitial_min_games_between): return false
	_last_interstitial = now
	_games_since = 0
	if cfg.test_mode: return await _test_overlay("TEST INTERSTITIAL", 1.5)
	return await _android_interstitial()

func show_banner() -> void:
	if banner_available() and _plugin and not cfg.test_mode: _android_banner(true)

func hide_banner() -> void:
	if _plugin: _android_banner(false)

# ---- Android adapters (plugin-specific; adapt to the chosen plugin) ---------------------------
func _android_rewarded(placement: String) -> bool:
	if _plugin == null: return false
	# Example for plugins exposing load_rewarded()/show_rewarded() + a "rewarded_earned" signal.
	if _plugin.has_method("load_rewarded"): _plugin.load_rewarded(str(cfg.android.rewarded_unit))
	if _plugin.has_method("show_rewarded"): _plugin.show_rewarded()
	if _plugin.has_signal("rewarded_earned"):
		await _plugin.rewarded_earned
		return true
	return false

func _android_interstitial() -> bool:
	if _plugin == null: return false
	if _plugin.has_method("load_interstitial"): _plugin.load_interstitial(str(cfg.android.interstitial_unit))
	if _plugin.has_method("show_interstitial"):
		_plugin.show_interstitial()
		return true
	return false

func _android_banner(show: bool) -> void:
	if _plugin == null: return
	if show and _plugin.has_method("load_banner"): _plugin.load_banner(str(cfg.android.banner_unit))
	elif not show and _plugin.has_method("hide_banner"): _plugin.hide_banner()

# ---- test overlay -----------------------------------------------------------------------------
func _test_overlay(title: String, secs: float) -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	_overlay = CanvasLayer.new()
	_overlay.layer = 100
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(bg)
	var l := Label.new()
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 36)
	_overlay.add_child(l)
	get_tree().root.add_child(_overlay)
	var t := secs
	while t > 0.0:
		l.text = "%s\n(simulated - no real ad)\n\n%d" % [title, ceili(t)]
		await get_tree().create_timer(0.25).timeout
		t -= 0.25
	_overlay.queue_free()
	return true
