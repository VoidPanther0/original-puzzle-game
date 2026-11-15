class_name FeedbackScreen
extends Control
## In-app feedback / support form. Stores submissions locally and shows a
## confirmation; a real build would POST to a backend.

signal back_pressed()

var _name_edit: LineEdit
var _email_edit: LineEdit
var _message_edit: TextEdit
var _status: Label


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
	column.add_theme_constant_override("separation", 18)
	scroll.add_child(column)

	var title := Label.new()
	title.text = "Feedback & Support"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Tell us what's broken or what you'd like added."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	column.add_child(subtitle)

	var card := PanelContainer.new()
	column.add_child(card)
	var card_margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		card_margin.add_theme_constant_override("margin_" + side, 24)
	card.add_child(card_margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 14)
	card_margin.add_child(rows)

	var name_label := Label.new()
	name_label.text = "Name (optional)"
	rows.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Your name"
	_name_edit.custom_minimum_size = Vector2(0, 56)
	rows.add_child(_name_edit)

	var email_label := Label.new()
	email_label.text = "Email (optional)"
	rows.add_child(email_label)
	_email_edit = LineEdit.new()
	_email_edit.placeholder_text = "you@example.com"
	_email_edit.custom_minimum_size = Vector2(0, 56)
	rows.add_child(_email_edit)

	var msg_label := Label.new()
	msg_label.text = "Message"
	rows.add_child(msg_label)
	_message_edit = TextEdit.new()
	_message_edit.placeholder_text = "Describe the issue or suggestion..."
	_message_edit.custom_minimum_size = Vector2(0, 160)
	_message_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	rows.add_child(_message_edit)

	var submit := Button.new()
	submit.text = "Submit"
	submit.theme_type_variation = "PrimaryButton"
	submit.custom_minimum_size = Vector2(0, 84)
	submit.pressed.connect(_on_submit_pressed)
	column.add_child(submit)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 20)
	column.add_child(_status)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 92)
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		back_pressed.emit())
	column.add_child(back)

	UiTheme.fade_in(self)


func handle_back() -> void:
	back_pressed.emit()


func _on_submit_pressed() -> void:
	var msg: String = _message_edit.text.strip_edges()
	if msg.is_empty():
		_status.text = "Please write a message first."
		_status.add_theme_color_override("font_color", UiTheme.DANGER)
		Sfx.play("invalid")
		return
	var cfg := ConfigFile.new()
	var count: int = 0
	if cfg.load("user://feedback.cfg") == OK:
		count = int(cfg.get_value("feedback", "count", 0))
	count += 1
	cfg.set_value("feedback", "count", count)
	cfg.set_value("feedback", "last_name", _name_edit.text)
	cfg.set_value("feedback", "last_email", _email_edit.text)
	cfg.set_value("feedback", "last_message", msg)
	cfg.set_value("feedback", "last_time", Time.get_datetime_string_from_system())
	cfg.save("user://feedback.cfg")
	_message_edit.text = ""
	_status.text = "Thanks! Submission #%d saved." % count
	_status.add_theme_color_override("font_color", UiTheme.ACCENT)
	Sfx.play("click")


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