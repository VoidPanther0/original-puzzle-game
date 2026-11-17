extends Screen
## Settings: sound (music / effects / vibration in one horizontal area), language,
## notifications, privacy and data. Appearance and display options are gone for now.

func build() -> void:
	begin_page("Settings", false)
	_add_sound_area()
	add_heading("Language")
	add_button(I18n.t("Language: %s") % I18n.LANGUAGES.get(I18n.current(), "English"), func(): main.go("language"), "secondary")
	add_heading("Notifications")
	if NotificationService.is_supported():
		_toggle("Daily challenge reminder", "notify_daily", func(_o): NotificationService.refresh_schedule())
		_toggle("Streak reminder", "notify_streak", func(_o): NotificationService.refresh_schedule())
	else:
		add_text(I18n.t("Push and reminder notifications are available in the Android app only."), 22, "text_dim")
	add_heading("Privacy")
	add_button(I18n.t("Ad personalisation: %s") % ("ON" if AdsService.has_consent() else "OFF"), func():
		AdsService.set_consent(not AdsService.has_consent())
		refresh(), "secondary")
	add_button("Privacy Policy", func(): main.go("privacy"), "secondary")
	add_button("Terms and Conditions", func(): main.go("terms"), "secondary")
	add_button("Support and Feedback", func(): main.go("support"), "secondary")
	add_heading("Data")
	add_button("Reset all progress", func():
		dialog("Reset progress?", "This deletes coins, levels, boosters and scores on this device. It cannot be undone.", [
			["Reset", func(): SaveManager.reset_all(); toast("Progress reset"); refresh(), "danger"],
			["Cancel", Callable(), "secondary"]]), "danger")
	var app := _app_info()
	add_text("Version %s  -  %s" % [app.get("version", "0.1.0"), Platform.name_id()], 20, "text_dim", HORIZONTAL_ALIGNMENT_CENTER, false)

## Music, sound effects and vibration - one area, laid out horizontally.
func _add_sound_area() -> void:
	var sb := UIKit.style(UIKit.c("panel"), 28)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 14
	sb.content_margin_bottom = 20
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", sb)
	list.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	card.add_child(v)
	v.add_child(UIKit.label("Sound Settings", 32, "accent"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(row)
	row.add_child(_sound_item("Music", "music"))
	row.add_child(_sound_item("Sound Effects", "sfx"))
	row.add_child(_sound_item("Vibration", "haptics"))

func _sound_item(title: String, key: String) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	var l := UIKit.label(title, 21, "text", HORIZONTAL_ALIGNMENT_CENTER)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(l)
	var sw := Switch.new()
	sw.on = bool(SaveManager.get_setting(key, true))
	sw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sw.toggled.connect(func(on):
		SaveManager.set_setting(key, on)
		AudioManager.apply_settings())
	v.add_child(sw)
	return v

func _toggle(label: String, key: String, extra: Callable = Callable()) -> void:
	var cb := CheckButton.new()
	cb.text = "  " + I18n.t(label)
	cb.button_pressed = bool(SaveManager.get_setting(key, true if key != "fullscreen" else false))
	cb.add_theme_font_size_override("font_size", 28)
	cb.add_theme_color_override("font_color", UIKit.c("text"))
	cb.custom_minimum_size = Vector2(0, 64)
	cb.toggled.connect(func(on):
		SaveManager.set_setting(key, on)
		if extra.is_valid(): extra.call(on))
	list.add_child(cb)

static func _app_info() -> Dictionary:
	var f := FileAccess.open("res://config/app.json", FileAccess.READ)
	if f == null: return {}
	var p = JSON.parse_string(f.get_as_text())
	return p if typeof(p) == TYPE_DICTIONARY else {}
