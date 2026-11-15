class_name SeasonScreen
extends Control
## Seasonal event: countdown, milestone progress, and reward claims.

signal back_pressed()
signal play_pressed()

var _timer_label: Label
var _progress_bar: ProgressBar
var _milestone_label: Label
var _claim_button: Button
var _status_label: Label

var _event_name: String = "Spring Block Festival"
var _event_end: int = 0
var _score_progress: int = 0
var _milestones: Array[int] = [500, 1500, 3000, 5000, 8000]
var _claimed: Array[bool] = [false, false, false, false, false]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_event_end = Time.get_unix_time_from_system() + 7 * 24 * 3600
	_load_progress()
	var bg := TextureRect.new()
	bg.texture = SettingsScreen._background()
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
	title.text = _event_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Earn score to unlock rewards"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	column.add_child(subtitle)

	var card := PanelContainer.new()
	column.add_child(card)
	var card_margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		card_margin.add_theme_constant_override("margin_" + side, 24)
	card.add_child(card_margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 16)
	card_margin.add_child(rows)

	var timer_row := HBoxContainer.new()
	var timer_title := Label.new()
	timer_title.text = "Ends in"
	timer_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_row.add_child(timer_title)
	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_label.add_theme_color_override("font_color", UiTheme.GOLD)
	timer_row.add_child(_timer_label)
	rows.add_child(timer_row)

	var progress_title := Label.new()
	progress_title.text = "Milestone progress"
	rows.add_child(progress_title)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = float(_milestones[-1])
	_progress_bar.value = float(_score_progress)
	_progress_bar.custom_minimum_size = Vector2(0, 32)
	rows.add_child(_progress_bar)

	_milestone_label = Label.new()
	_milestone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_milestone_label)

	_claim_button = Button.new()
	_claim_button.text = "Claim next reward"
	_claim_button.theme_type_variation = "PrimaryButton"
	_claim_button.custom_minimum_size = Vector2(0, 84)
	_claim_button.pressed.connect(_on_claim_pressed)
	rows.add_child(_claim_button)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 20)
	rows.add_child(_status_label)

	var play := Button.new()
	play.text = "Play to earn"
	play.custom_minimum_size = Vector2(0, 84)
	play.pressed.connect(func() -> void:
		Sfx.play("click")
		play_pressed.emit())
	column.add_child(play)

	var back := Button.new()
	back.text = "Back"
	back.theme_type_variation = "PrimaryButton"
	back.custom_minimum_size = Vector2(0, 92)
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		back_pressed.emit())
	column.add_child(back)

	_refresh()
	set_process(true)
	UiTheme.fade_in(self)


func _process(delta: float) -> void:
	_refresh_timer()


func handle_back() -> void:
	back_pressed.emit()


func add_score(amount: int) -> void:
	_score_progress += amount
	_save_progress()
	_refresh()


func _on_claim_pressed() -> void:
	var idx: int = -1
	for i: int in _milestones.size():
		if not _claimed[i] and _score_progress >= _milestones[i]:
			idx = i
			break
	if idx < 0:
		_status_label.text = "No reward ready yet"
		Sfx.play("click")
		return
	_claimed[idx] = true
	_save_progress()
	_status_label.text = "Claimed milestone %d!" % (idx + 1)
	Sfx.play("click")
	_refresh()


func _refresh() -> void:
	_progress_bar.value = float(_score_progress)
	var next_idx: int = -1
	for i: int in _milestones.size():
		if not _claimed[i]:
			next_idx = i
			break
	if next_idx >= 0:
		_milestone_label.text = "Next: %d pts  (%d / %d)" % [_milestones[next_idx], _score_progress, _milestones[next_idx]]
		_claim_button.disabled = _score_progress < _milestones[next_idx]
	else:
		_milestone_label.text = "All milestones claimed!"
		_claim_button.disabled = true
	_refresh_timer()


func _refresh_timer() -> void:
	var remaining: int = _event_end - int(Time.get_unix_time_from_system())
	if remaining <= 0:
		_timer_label.text = "Ended"
		return
	var days: int = remaining / 86400
	var hours: int = (remaining % 86400) / 3600
	var mins: int = (remaining % 3600) / 60
	_timer_label.text = "%dd %dh %dm" % [days, hours, mins]


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://season.cfg") == OK:
		_score_progress = int(cfg.get_value("season", "score", 0))
		var claimed_str: String = str(cfg.get_value("season", "claimed", ""))
		var parts: PackedStringArray = claimed_str.split(",")
		for i: int in parts.size():
			if i < _claimed.size():
				_claimed[i] = parts[i] == "1"


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("season", "score", _score_progress)
	var claimed_str: String = ""
	for c: bool in _claimed:
		claimed_str += ("1" if c else "0") + ","
	claimed_str = claimed_str.trim_suffix(",")
	cfg.set_value("season", "claimed", claimed_str)
	cfg.save("user://season.cfg")


static func add_score_to_season(amount: int) -> void:
	if amount <= 0:
		return
	var cfg := ConfigFile.new()
	var score: int = 0
	if cfg.load("user://season.cfg") == OK:
		score = int(cfg.get_value("season", "score", 0))
	cfg.set_value("season", "score", score + amount)
	cfg.save("user://season.cfg")


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