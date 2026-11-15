class_name OverlayDialog
extends Control
## A dimmed full-screen overlay with a centred card: title, text lines and
## buttons. Used for the pause and game-over screens.

var _card: PanelContainer
var _title: Label
var _body: VBoxContainer
var _buttons: VBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.09, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(540, 0)
	center.add_child(_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 52)
	column.add_child(_title)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	column.add_child(_body)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	column.add_child(_buttons)


func reset(title_text: String, title_color: Color = UiTheme.TEXT) -> void:
	_title.text = title_text
	_title.add_theme_color_override("font_color", title_color)
	for child: Node in _body.get_children():
		child.queue_free()
	for child: Node in _buttons.get_children():
		child.queue_free()


func add_line(text: String, font_size: int = 30, color: Color = UiTheme.TEXT_DIM) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_body.add_child(label)
	return label


func add_button(text: String, callback: Callable, variation: String = "") -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 84)
	if variation != "":
		button.theme_type_variation = variation
	button.pressed.connect(callback)
	_buttons.add_child(button)
	return button


func open() -> void:
	visible = true
	_card.pivot_offset = _card.size / 2.0
	modulate.a = 0.0
	_card.scale = Vector2(0.9, 0.9)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	tween.tween_property(_card, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	visible = false
