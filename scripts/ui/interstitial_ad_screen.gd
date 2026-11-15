class_name InterstitialAdScreen
extends Control
## Full-screen interstitial ad host: shows a placeholder ad with a countdown
## timer and a close button. Real SDK integration replaces _show_ad_content().

signal closed()
signal ad_clicked()

var _countdown: int = 5
var _timer: Timer
var _close_btn: Button
var _countdown_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)

	var ad_title := Label.new()
	ad_title.text = "Sponsored"
	ad_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_title.add_theme_font_size_override("font_size", 36)
	ad_title.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	column.add_child(ad_title)

	var ad_box := PanelContainer.new()
	ad_box.custom_minimum_size = Vector2(600, 400)
	column.add_child(ad_box)
	var ad_margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		ad_margin.add_theme_constant_override("margin_" + side, 24)
	ad_box.add_child(ad_margin)
	var ad_label := Label.new()
	ad_label.text = "Ad content placeholder\n\nReplace with your SDK's view."
	ad_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ad_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ad_margin.add_child(ad_label)

	var click_btn := Button.new()
	click_btn.text = "Learn more"
	click_btn.custom_minimum_size = Vector2(0, 64)
	click_btn.pressed.connect(func() -> void:
		Sfx.play("click")
		ad_clicked.emit())
	column.add_child(click_btn)

	_countdown_label = Label.new()
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 28)
	column.add_child(_countdown_label)

	_close_btn = Button.new()
	_close_btn.text = "Close"
	_close_btn.custom_minimum_size = Vector2(0, 64)
	_close_btn.disabled = true
	_close_btn.pressed.connect(_on_close)
	column.add_child(_close_btn)

	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_tick)
	add_child(_timer)
	_refresh_countdown()
	_timer.start()


func _tick() -> void:
	_countdown -= 1
	if _countdown <= 0:
		_timer.stop()
		_countdown = 0
		_close_btn.disabled = false
		_countdown_label.text = "You can close now"
	else:
		_refresh_countdown()


func _refresh_countdown() -> void:
	_countdown_label.text = "Close in %d..." % _countdown


func _on_close() -> void:
	Sfx.play("click")
	closed.emit()
	queue_free()


func show_ad() -> void:
	# Entry point for triggering the interstitial. SDK wiring goes here.
	pass