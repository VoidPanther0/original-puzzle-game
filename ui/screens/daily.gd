extends Screen

func build() -> void:
	begin_page("Daily Challenge")
	var lv := LevelDB.daily_level(GameState.today())
	var done := GameState.daily_done_today()
	var dd: Dictionary = LevelDB.meta().get("daily", {})
	add_text(GameState.today(), 26, "text_dim", HORIZONTAL_ALIGNMENT_CENTER, false)
	add_card("Today's challenge", "Reach %d points. Same puzzle for everyone today." % int(lv.goal.target),
		"Done" if done else "Play", func(): GameState.start_daily(); main.go("game"), not done, "primary")
	add_text("Reward: %d coins + %d gems" % [int(dd.get("reward_coins", 100)), int(dd.get("reward_gems", 5))], 26, "accent", HORIZONTAL_ALIGNMENT_CENTER, false)
	if int(GameState.d().daily.best) > 0:
		add_text("Your best daily score: %d" % int(GameState.d().daily.best), 24, "text", HORIZONTAL_ALIGNMENT_CENTER, false)
	add_heading("Streak")
	add_card("%d day streak" % GameState.current_streak(), "Best: %d days. Play every day to keep it going." % int(GameState.d().streak.best), "", Callable(), true, "primary", false)
	if BackendService.is_configured() and BackendService.is_signed_in():
		add_button("Check server challenge", _server_daily, "secondary")

func _server_daily() -> void:
	var r: Dictionary = await BackendService.get_daily_challenge()
	toast("Server challenge loaded" if r.ok else "Could not reach server")
