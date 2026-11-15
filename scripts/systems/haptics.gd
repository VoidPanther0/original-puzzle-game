extends Node
## Autoload "Haptics": short vibration pulses on handheld devices,
## respecting the player's vibration setting.


func pulse(duration_ms: int = 20) -> void:
	if not Settings.vibration_enabled:
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)


func light() -> void:
	pulse(12)


func medium() -> void:
	pulse(30)


func heavy() -> void:
	pulse(70)
