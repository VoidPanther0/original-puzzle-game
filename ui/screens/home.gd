extends Screen
## Home: logo, day streak, Play Adventure, Play Classic and Settings / Quit.
## Everything else (daily, shop, events, season, profile, ...) lives in the "..." menu at the top.

const MORE_ITEMS := [
	["Daily Challenge", "daily", "ic_calendar"],
	["Shop", "shop", ""],
	["Events", "events", "ic_events"],
	["Season Pass", "season", "ic_season"],
	["Leaderboard", "leaderboard", "ic_trophy"],
	["Profile", "profile", "ic_profile"],
	["Inventory", "inventory", "ic_chest"],
	["Achievements", "achievements", ""],
	["Support and Feedback", "support", "ic_handshake"],
]

func build() -> void:
	make_column(MAX_WIDTH, 12)
	column.add_child(UIKit.spacer(4))
	# --- top bar: "..." menu + currencies
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	column.add_child(top)
	var more := UIKit.button("•••", "secondary", Vector2(88, 58))
	more.add_theme_font_size_override("font_size", 26)
	more.tooltip_text = "More"
	more.pressed.connect(_open_more)
	top.add_child(more)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	top.add_child(CurrencyBar.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	# --- logo (kept centred) + day streak
	var logo := Logo.new(true)
	logo.custom_minimum_size.y = Logo.content_height(minf(size.x, MAX_WIDTH) - 24.0, true)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(logo)
	var streak := StreakChip.new()
	streak.set_days(GameState.current_streak(), int(GameState.d().streak.best))
	streak.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list.add_child(streak)

	# --- Adventure
	var ab := UIKit.button("Play Adventure", "accent", Vector2(0, 96))
	ab.add_theme_font_size_override("font_size", 34)
	ab.pressed.connect(func(): main.go("adventure"))
	list.add_child(ab)

	# --- Classic / Endless
	var cb := UIKit.button("Play Classic", "primary", Vector2(0, 92))
	cb.add_theme_font_size_override("font_size", 32)
	cb.pressed.connect(func():
		GameState.start_endless(false)
		main.go("game"))
	list.add_child(cb)

	# --- Settings + Quit (one row, one button each)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	list.add_child(row)
	var sb := UIKit.button("Settings", "secondary", Vector2(0, 78))
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sb.pressed.connect(func(): main.go("settings"))
	row.add_child(sb)
	if not Platform.is_web:   # browsers cannot close their own tab, so no Quit there
		var qb := UIKit.button("Quit", "danger", Vector2(0, 78))
		qb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		qb.pressed.connect(on_back)
		row.add_child(qb)

	if not GameState.daily_done_today():
		add_text(I18n.t("Today's daily challenge is waiting!"), 22, "accent", HORIZONTAL_ALIGNMENT_CENTER)
	if not AdsService.consent_known():
		call_deferred("_ask_consent")
	NotificationService.refresh_schedule()

## The "..." menu: every screen that is not on the home page itself.
func _open_more() -> void:
	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.style(UIKit.c("panel_solid"), 32, UIKit.c("primary"), 3))
	p.custom_minimum_size = Vector2(minf(size.x - 40.0, 640.0), 0)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UIKit.label("More", 36, "accent", HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for e in MORE_ITEMS:
		var b := UIKit.button(e[0], "secondary", Vector2(0, 74))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 21)
		b.pressed.connect(func():
			ov.queue_free()
			main.go(e[1]))
		grid.add_child(b)
	var close := UIKit.button("Close", "danger", Vector2(0, 70))
	close.pressed.connect(func(): ov.queue_free())
	v.add_child(close)

func on_back() -> void:
	if Platform.is_web: return
	dialog(I18n.t("Quit game?"), I18n.t("Your progress is saved automatically."), [
		["Quit", func(): SaveManager.save_now(); Platform.quit_game(), "danger"],
		["Stay", Callable(), "secondary"]])

func _ask_consent() -> void:
	dialog("Privacy & Ads", "We may show ads. Allow personalised ads? You can change this any time in Settings.", [
		["Accept", func(): AdsService.set_consent(true), "primary"],
		["Decline", func(): AdsService.set_consent(false), "secondary"],
		["Privacy Policy", func(): main.go("privacy"), "secondary"],
	])
