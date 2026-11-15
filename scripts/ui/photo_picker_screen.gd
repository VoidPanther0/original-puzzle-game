class_name PhotoPickerScreen
extends Control
## Avatar / photo picker: choose an image file, preview it cropped to a square,
## and save the path. Uses Godot's built-in FileDialog.

signal back_pressed()
signal photo_selected(path: String)

var _preview: TextureRect
var _path_label: Label
var _file_dialog: FileDialog
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
	column.add_theme_constant_override("separation", 20)
	scroll.add_child(column)

	var title := Label.new()
	title.text = "Profile Photo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(title)

	var preview_card := PanelContainer.new()
	preview_card.custom_minimum_size = Vector2(0, 320)
	column.add_child(preview_card)
	var preview_margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		preview_margin.add_theme_constant_override("margin_" + side, 24)
	preview_card.add_child(preview_margin)
	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.custom_minimum_size = Vector2(260, 260)
	preview_margin.add_child(_preview)

	_path_label = Label.new()
	_path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_path_label.add_theme_font_size_override("font_size", 18)
	_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_path_label)

	var pick := Button.new()
	pick.text = "Choose photo"
	pick.theme_type_variation = "PrimaryButton"
	pick.custom_minimum_size = Vector2(0, 84)
	pick.pressed.connect(_open_picker)
	column.add_child(pick)

	var clear := Button.new()
	clear.text = "Remove photo"
	clear.custom_minimum_size = Vector2(0, 72)
	clear.pressed.connect(_clear_photo)
	column.add_child(clear)

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

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Images"])
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)

	_load_saved()
	UiTheme.fade_in(self)


func handle_back() -> void:
	back_pressed.emit()


func _open_picker() -> void:
	Sfx.play("click")
	_file_dialog.popup_centered_ratio(0.85)


func _on_file_selected(path: String) -> void:
	var img := Image.new()
	var err: Error = img.load(path)
	if err != OK:
		_status.text = "Could not load image."
		_status.add_theme_color_override("font_color", UiTheme.DANGER)
		Sfx.play("invalid")
		return
	# Crop to square from center.
	var side: int = mini(img.get_width(), img.get_height())
	var x: int = (img.get_width() - side) / 2
	var y: int = (img.get_height() - side) / 2
	var cropped := img.get_region(Rect2i(x, y, side, side))
	var tex := ImageTexture.create_from_image(cropped)
	_preview.texture = tex
	_path_label.text = path
	_status.text = "Photo selected."
	_status.add_theme_color_override("font_color", UiTheme.ACCENT)
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "photo_path", path)
	cfg.save("user://profile.cfg")
	photo_selected.emit(path)
	Sfx.play("click")


func _clear_photo() -> void:
	_preview.texture = null
	_path_label.text = ""
	_status.text = "Photo removed."
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "photo_path", "")
	cfg.save("user://profile.cfg")
	Sfx.play("click")


func _load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://profile.cfg") == OK:
		var path: String = str(cfg.get_value("profile", "photo_path", ""))
		if not path.is_empty():
			var img := Image.new()
			if img.load(path) == OK:
				var side: int = mini(img.get_width(), img.get_height())
				var x: int = (img.get_width() - side) / 2
				var y: int = (img.get_height() - side) / 2
				var cropped := img.get_region(Rect2i(x, y, side, side))
				_preview.texture = ImageTexture.create_from_image(cropped)
				_path_label.text = path


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