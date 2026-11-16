class_name Screen
extends Control
## Base class for all screens: standard page layout helpers (header, scrolling list, cards).
## Screens are built in code so they stay responsive and need no hand-placed nodes.

const MAX_WIDTH := 760.0

var main: Node            # Main (screen manager)
var args: Dictionary = {}
var column: VBoxContainer
var list: VBoxContainer   # scrolling content container
var _wrap: MarginContainer
var _max_w := MAX_WIDTH

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	build()
	resized.connect(_relayout)
	_relayout()

func build() -> void:
	pass

## Android back button / Escape.
func on_back() -> void:
	main.go("home")

func _relayout() -> void:
	if _wrap:
		var m := int(maxf(12.0, (size.x - _max_w) / 2.0))
		_wrap.add_theme_constant_override("margin_left", m)
		_wrap.add_theme_constant_override("margin_right", m)

## Centered, width-limited content column (responsive: fills phones, caps on desktop/web).
func make_column(max_w: float = MAX_WIDTH, sep: int = 14) -> VBoxContainer:
	_max_w = max_w
	_wrap = MarginContainer.new()
	_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_wrap)
	column = VBoxContainer.new()
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", sep)
	_wrap.add_child(column)
	_relayout()
	return column

## Creates the standard page: header (back arrow + title + currency) and a scrolling list.
func begin_page(title: String, show_currency: bool = true, back_to: String = "home") -> VBoxContainer:
	make_column()
	var top := Control.new()
	top.custom_minimum_size = Vector2(0, 18)
	column.add_child(top)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	var back := UIKit.back_button()
	back.pressed.connect(func(): main.go(back_to) if back_to != "" else on_back())
	header.add_child(back)
	var t := UIKit.label(title, 38, "text", HORIZONTAL_ALIGNMENT_CENTER)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(t)
	if show_currency:
		var cb := CurrencyBar.new()
		header.add_child(cb)
	else:
		var sp := Control.new()
		sp.custom_minimum_size = Vector2(74, 0)
		header.add_child(sp)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	return list

func add_text(text: String, size: int = 26, color_name: String = "text", align: int = HORIZONTAL_ALIGNMENT_LEFT, translate: bool = true) -> Label:
	var l := UIKit.label(text, size, color_name, align, translate)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(l)
	return l

func add_heading(text: String) -> Label:
	var l := UIKit.label(text, 32, "accent")
	list.add_child(l)
	return l

func add_button(text: String, cb: Callable, kind: String = "primary") -> Button:
	var b := UIKit.button(text, kind)
	b.pressed.connect(cb)
	list.add_child(b)
	return b

## A rounded card with a title, optional description and optional action button. Returns the card VBox.
func add_card(title: String, desc: String = "", btn_text: String = "", cb: Callable = Callable(), enabled: bool = true, kind: String = "primary", translate: bool = true) -> VBoxContainer:
	var p := UIKit.panel()
	list.add_child(p)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	p.add_child(row)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UIKit.label(title, 30, "text", HORIZONTAL_ALIGNMENT_LEFT, translate))
	if desc != "":
		v.add_child(UIKit.label(desc, 22, "text_dim", HORIZONTAL_ALIGNMENT_LEFT, translate))
	if btn_text != "":
		var b := UIKit.button(btn_text, kind, Vector2(190, 64))
		b.disabled = not enabled
		if cb.is_valid(): b.pressed.connect(cb)
		row.add_child(b)
	return v

## A styled progress bar (not added to any container yet).
func make_progress(value: float, max_value: float) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = maxf(1.0, max_value)
	pb.value = minf(value, max_value)
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 18)
	pb.add_theme_stylebox_override("background", UIKit.style(Color(0, 0, 0, 0.3), 9))
	pb.add_theme_stylebox_override("fill", UIKit.style(UIKit.c("accent"), 9))
	return pb

## Progress bar (not attached yet - the caller decides where it goes).
func add_progress(value: float, max_value: float) -> ProgressBar:
	return make_progress(value, max_value)

## Modal dialog. buttons = [[text, Callable, kind], ...]. Returns the overlay (free it to close).
## Buttons close the dialog automatically unless the callable returns false.
func dialog(title: String, body: String, buttons: Array, translate: bool = true) -> Control:
	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.style(UIKit.c("panel_solid"), 32, UIKit.c("primary"), 3))
	p.custom_minimum_size = Vector2(minf(size.x - 48.0, 620.0), 0)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(UIKit.label(title, 40, "accent", HORIZONTAL_ALIGNMENT_CENTER, translate))
	if body != "":
		v.add_child(UIKit.label(body, 26, "text", HORIZONTAL_ALIGNMENT_CENTER, translate))
	for b in buttons:
		var btn := UIKit.button(b[0], b[2] if b.size() > 2 else "primary")
		btn.pressed.connect(func():
			var keep = b[1].call() if b[1].is_valid() else null
			if keep != false and is_instance_valid(ov): ov.queue_free())
		v.add_child(btn)
	ov.modulate.a = 0.0
	create_tween().tween_property(ov, "modulate:a", 1.0, 0.12)
	return ov

func toast(msg: String) -> void:
	main.toast(msg)

func refresh() -> void:
	main.go(main.current_name, args, false)
