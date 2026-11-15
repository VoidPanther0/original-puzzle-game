class_name MenuScreen
extends Control
## Main menu: title, animated logo, best score, Play / Settings / Quit.

signal play_pressed()
signal settings_pressed()

var _best_label: Label
var _logo: LogoView


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = SettingsScreen._background()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var inset: Vector4 = ScreenInsets.margins(self, 40)
	margin.add_theme_constant_override("margin_left", int(inset.x))
	margin.add_theme_constant_override("margin_top", int(inset.y))
	margin.add_theme_constant_override("margin_right", int(inset.z))
	margin.add_theme_constant_override("margin_bottom", int(inset.w))
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)

	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.size_flags_stretch_ratio = 0.5
	column.add_child(top_spacer)

	_logo = LogoView.new()
	_logo.custom_minimum_size = Vector2(0, 260)
	column.add_child(_logo)

	var title := Label.new()
	title.text = "ORIGINAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 84)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "PUZZLE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 84)
	subtitle.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(subtitle)

	_best_label = Label.new()
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.add_theme_color_override("font_color", UiTheme.GOLD)
	column.add_child(_best_label)

	var middle_spacer := Control.new()
	middle_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(middle_spacer)

	var play := Button.new()
	play.text = "Play"
	play.theme_type_variation = "PrimaryButton"
	play.custom_minimum_size = Vector2(0, 110)
	play.add_theme_font_size_override("font_size", 44)
	play.pressed.connect(func() -> void:
		Sfx.play("click")
		play_pressed.emit())
	column.add_child(play)

	var settings := Button.new()
	settings.text = "Settings"
	settings.custom_minimum_size = Vector2(0, 90)
	settings.pressed.connect(func() -> void:
		Sfx.play("click")
		settings_pressed.emit())
	column.add_child(settings)

	if not OS.has_feature("web"):
		var quit := Button.new()
		quit.text = "Quit"
		quit.custom_minimum_size = Vector2(0, 90)
		quit.pressed.connect(func() -> void: get_tree().quit())
		column.add_child(quit)

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 16)
	column.add_child(bottom_spacer)

	Settings.changed.connect(_refresh)
	_refresh()
	UiTheme.fade_in(self)


func handle_back() -> void:
	if not OS.has_feature("web"):
		get_tree().quit()


func _refresh() -> void:
	_best_label.text = "Best  %d" % Settings.best_score


## A small animated emblem: a 4x4 grid of gems that gently bob.
class LogoView extends Control:
	var _time: float = 0.0
	const PATTERN: Array[String] = [
		"1220",
		"3.45",
		"6.77",
		"1553",
	]

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var cell: float = minf(size.x / 4.4, size.y / 4.4)
		var origin: Vector2 = (size - Vector2(cell, cell) * 4.0) / 2.0
		for y: int in 4:
			for x: int in 4:
				var ch: String = PATTERN[y][x]
				if ch == "." or ch == "0":
					continue
				var bob: float = sin(_time * 2.2 + float(x) * 0.9 + float(y) * 0.6) * cell * 0.05
				var rect := Rect2(origin + Vector2(x, y) * cell + Vector2(0, bob), Vector2(cell, cell)).grow(-cell * 0.05)
				UiTheme.draw_block(self, rect, int(ch))
