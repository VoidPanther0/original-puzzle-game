class_name SettingsScreen
extends Control
## Sound, volume, vibration, hint and best-score reset. Every control changes
## the Settings autoload, which saves immediately.

signal back_pressed()

var _confirm_reset: bool = false
var _reset_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = _background()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var inset: Vector4 = ScreenInsets.margins(self, 32)
	margin.add_theme_constant_override("margin_left", int(inset.x))
	margin.add_theme_constant_override("margin_top", int(inset.y))
	margin.add_theme_constant_override("margin_right", int(inset.z))
	margin.add_theme_constant_override("margin_bottom", int(inset.w))
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 22)
	scroll.add_child(column)

	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 60)
	column.add_child(title)

	var card := PanelContainer.new()
	column.add_child(card)
	var card_margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		card_margin.add_theme_constant_override("margin_" + side, 24)
	card.add_child(card_margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 20)
	card_margin.add_child(rows)

	rows.add_child(_toggle("Sound effects", Settings.sound_enabled, Settings.set_sound_enabled))

	var volume_label := Label.new()
	volume_label.text = "Volume"
	rows.add_child(volume_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Settings.volume
	slider.custom_minimum_size = Vector2(0, 48)
	slider.value_changed.connect(func(v: float) -> void: Settings.set_volume(v))
	slider.drag_ended.connect(func(_changed: bool) -> void: Sfx.play("click"))
	rows.add_child(slider)

	rows.add_child(_toggle("Vibration", Settings.vibration_enabled, func(v: bool) -> void:
		Settings.set_vibration_enabled(v)
		Haptics.medium()))
	rows.add_child(_toggle("Placement preview", Settings.ghost_preview, Settings.set_ghost_preview))

	_reset_button = Button.new()
	_reset_button.theme_type_variation = "DangerButton"
	_reset_button.custom_minimum_size = Vector2(0, 84)
	_reset_button.pressed.connect(_on_reset_pressed)
	column.add_child(_reset_button)
	_refresh_reset_text()

	var back := Button.new()
	back.text = "Back"
	back.theme_type_variation = "PrimaryButton"
	back.custom_minimum_size = Vector2(0, 92)
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		back_pressed.emit())
	column.add_child(back)

	UiTheme.fade_in(self)


func handle_back() -> void:
	back_pressed.emit()


func _toggle(text: String, initial: bool, setter: Callable) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.button_pressed = initial
	toggle.custom_minimum_size = Vector2(0, 64)
	toggle.toggled.connect(func(on: bool) -> void:
		setter.call(on)
		Sfx.play("click"))
	return toggle


func _on_reset_pressed() -> void:
	if _confirm_reset:
		Settings.reset_best_score()
		_confirm_reset = false
		Sfx.play("click")
	else:
		_confirm_reset = true
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			_confirm_reset = false
			if is_instance_valid(_reset_button):
				_refresh_reset_text())
	_refresh_reset_text()


func _refresh_reset_text() -> void:
	if _confirm_reset:
		_reset_button.text = "Tap again to erase best score"
	else:
		_reset_button.text = "Reset best score (%d)" % Settings.best_score


static func _background() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, UiTheme.BG_TOP)
	gradient.set_color(1, UiTheme.BG_BOTTOM)
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 256
	return tex
