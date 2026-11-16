extends Node
## In-app purchase abstraction.
##  * Android: Google Play Billing through a Godot plugin singleton (adapter functions at the bottom,
##    UNTESTED - needs the plugin + a Play Console product setup, see BILLING_SETUP.md).
##    A purchase is only granted AFTER the backend verifies the purchase token (rewards function,
##    action "verify_purchase"). No backend / no verification => no grant.
##  * Test mode (config/billing.json "test_mode": true) grants instantly, but ONLY in debug builds
##    (OS.is_debug_build()). Release builds never simulate a successful purchase.
##  * Windows / Web: real-money purchases are unavailable (is_available() == false).

signal purchase_finished(product: String, ok: bool, message: String)

var cfg := {"test_mode": true, "android": {}, "products": {}}
var _plugin = null

func _ready() -> void:
	var f := FileAccess.open("res://config/billing.json", FileAccess.READ)
	if f:
		var p = JSON.parse_string(f.get_as_text())
		if typeof(p) == TYPE_DICTIONARY: cfg.merge(p, true)
	if Platform.is_android:
		var name := str(cfg.android.get("plugin_singleton", ""))
		if name != "" and Engine.has_singleton(name):
			_plugin = Engine.get_singleton(name)

func test_mode_active() -> bool:
	return bool(cfg.test_mode) and OS.is_debug_build()

func is_available() -> bool:
	return test_mode_active() or (_plugin != null and BackendService.is_configured())

func unavailable_reason() -> String:
	if Platform.is_web or Platform.is_windows: return "Purchases are only available in the Android app."
	if _plugin == null: return "Billing plugin not installed in this build."
	if not BackendService.is_configured(): return "Purchase verification backend not configured."
	return ""

## Awaitable: `var ok: bool = await BillingService.purchase(item)`. `item` is a meta.json shop entry.
func purchase(item: Dictionary) -> bool:
	var product := str(item.get("product", ""))
	if not is_available():
		purchase_finished.emit(product, false, unavailable_reason())
		return false
	if test_mode_active():
		_grant(item, "test")
		purchase_finished.emit(product, true, "Test purchase (debug build only)")
		return true
	var token: String = await _android_purchase(product)
	if token == "":
		purchase_finished.emit(product, false, "Purchase cancelled or failed.")
		return false
	var res: Dictionary = await BackendService.verify_purchase(product, token)
	if not res.get("ok", false):
		purchase_finished.emit(product, false, "Purchase could not be verified.")
		return false
	_grant(item, token)
	_android_acknowledge(product, token, str(cfg.products.get(product, "consumable")) == "consumable")
	purchase_finished.emit(product, true, "Purchase complete.")
	return true

func _grant(item: Dictionary, token: String) -> void:
	GameState.apply_reward(item.give)
	var h: Array = SaveManager.data.purchases.history
	h.append({"product": item.get("product", ""), "token_hash": token.sha256_text().substr(0, 12), "t": int(Time.get_unix_time_from_system())})
	SaveManager.mark_dirty()

## Restores non-consumables (remove-ads) on Android.
func restore() -> void:
	pass  # Plugin-specific: query owned purchases, verify each via backend, then re-grant non-consumables.

# ---- Android adapters (plugin-specific) ---------------------------------------------------------
func _android_purchase(product: String) -> String:
	if _plugin == null: return ""
	if _plugin.has_method("purchase"): _plugin.purchase([product])
	if _plugin.has_signal("purchases_updated"):
		var r = await _plugin.purchases_updated
		if r is Array and r.size() > 0 and r[0] is Dictionary:
			return str(r[0].get("purchase_token", ""))
	return ""

func _android_acknowledge(product: String, token: String, consumable: bool) -> void:
	if _plugin == null: return
	if consumable and _plugin.has_method("consume_purchase"): _plugin.consume_purchase(token)
	elif _plugin.has_method("acknowledge_purchase"): _plugin.acknowledge_purchase(token)
