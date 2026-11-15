extends Control
## Root of the app. Owns the current screen and swaps between menu, game and
## settings. Also routes the Android back button.

var _current: Control = null


func _ready() -> void:
	theme = UiTheme.make_theme()
	get_tree().set_auto_accept_quit(false)
	get_tree().root.set_meta("main", self)
	_show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			Settings.save_settings()
			get_tree().quit()
		elif _current != null and _current.has_method("handle_back"):
			_current.call("handle_back")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _current != null and _current.has_method("handle_back"):
		_current.call("handle_back")
		get_viewport().set_input_as_handled()


func _swap(screen: Control) -> void:
	if _current != null:
		_current.queue_free()
	_current = screen
	add_child(screen)


func _show_menu() -> void:
	var menu: MenuScreen = load("res://scenes/menu.tscn").instantiate()
	menu.play_pressed.connect(_show_game)
	menu.settings_pressed.connect(_show_settings)
	menu.season_pressed.connect(_show_season)
	menu.feedback_pressed.connect(_show_feedback)
	menu.photo_pressed.connect(_show_photo)
	menu.web_pressed.connect(_show_web)
	menu.ad_pressed.connect(_show_ad)
	_swap(menu)


func _show_game() -> void:
	var game: GameScreen = load("res://scenes/game.tscn").instantiate()
	game.menu_requested.connect(_show_menu)
	_swap(game)


func _show_settings() -> void:
	var settings: SettingsScreen = load("res://scenes/settings.tscn").instantiate()
	settings.back_pressed.connect(_show_menu)
	_swap(settings)

func _show_season() -> void:
	var season: SeasonScreen = load("res://scenes/season.tscn").instantiate()
	season.back_pressed.connect(_show_menu)
	season.play_pressed.connect(_show_game)
	_swap(season)

func _show_feedback() -> void:
	var fb: FeedbackScreen = load("res://scenes/feedback.tscn").instantiate()
	fb.back_pressed.connect(_show_menu)
	_swap(fb)

func _show_photo() -> void:
	var pp: PhotoPickerScreen = load("res://scenes/photo_picker.tscn").instantiate()
	pp.back_pressed.connect(_show_menu)
	_swap(pp)

func _show_web() -> void:
	var wv: WebViewScreen = load("res://scenes/web_view.tscn").instantiate()
	wv.back_pressed.connect(_show_menu)
	_swap(wv)

func _show_ad() -> void:
	var ad: InterstitialAdScreen = load("res://scenes/interstitial_ad.tscn").instantiate()
	ad.closed.connect(_show_menu)
	_swap(ad)
