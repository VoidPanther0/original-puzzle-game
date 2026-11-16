extends Screen

func on_back() -> void:
	main.go("home")

func build() -> void:
	var s: Dictionary = args.get("summary", GameState.last_result)
	begin_page("Level Complete!", true, "home")
	var is_daily: bool = s.get("mode", "") == "daily"
	add_text(I18n.t("Daily Challenge complete!") if is_daily else I18n.t("Great job!"), 34, "good", HORIZONTAL_ALIGNMENT_CENTER)
	var sd := StarsDisplay.new(int(s.get("stars", 0)), 70.0)
	sd.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list.add_child(sd)
	add_text(I18n.t("Score: %d") % int(s.get("score", 0)), 40, "text", HORIZONTAL_ALIGNMENT_CENTER, false)
	add_text("Lines cleared: %d    Best combo: x%d" % [int(s.get("lines", 0)), int(s.get("best_combo", 0))], 24, "text_dim", HORIZONTAL_ALIGNMENT_CENTER, false)
	var reward: Dictionary = s.get("reward", {})
	if not reward.is_empty():
		add_text("Reward: " + GameState.reward_text(reward), 30, "accent", HORIZONTAL_ALIGNMENT_CENTER, false)
	list.add_child(UIKit.spacer(20))
	if not is_daily:
		var id := str(s.get("level_id", ""))
		var parts := id.replace("c", "").split("_l")
		if parts.size() == 2:
			var ch := int(parts[0])
			var idx := int(parts[1])
			var nxt := GameState.next_level(ch, idx)
			if nxt.x > 0:
				add_button("Next Level", func(): if GameState.start_level(nxt.x, nxt.y): main.go("game"), "primary")
			add_button("Replay", func(): if GameState.start_level(ch, idx): main.go("game"), "secondary")
			add_button("Levels", func(): main.go("levels", {"chapter": ch}), "secondary")
	add_button("Home", func(): main.go("home"), "secondary")
	AdsService.call_deferred("maybe_show_interstitial")   # fire-and-forget (frequency-capped)
