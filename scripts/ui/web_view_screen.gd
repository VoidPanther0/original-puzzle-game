class_name WebViewScreen
extends Control
## In-app "H5" content host. Opens web content in the system browser (Godot
## has no cross-platform in-app WebView without a plugin). Link list is
## editable here.

signal back_pressed()

var _links: Array = [
	{"title": "Official site", "url": "https://godotengine.org"},
	{"title": "Support", "url": "https://godotengine.org/community"},
	{"title": "Privacy policy", "url": "https://godotengine.org/privacy-policy"},
]


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
	title.text = "Web Content"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(title)

	var note := Label.new()
	note.text = "Links open in your browser."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 20)
	column.add_child(note)

	for link in _links:
		var btn := Button.new()
		btn.text = str(link["title"])
		btn.custom_minimum_size = Vector2(0, 72)
		btn.pressed.connect(_open_link.bind(str(link["url"])))
		column.add_child(btn)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 92)
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		back_pressed.emit())
	column.add_child(back)

	UiTheme.fade_in(self)


func _open_link(url: String) -> void:
	Sfx.play("click")
	OS.shell_open(url)


func handle_back() -> void:
	back_pressed.emit()


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