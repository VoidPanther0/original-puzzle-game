extends Screen

func build() -> void:
	begin_page("Events")
	var evs := GameState.active_events()
	if evs.is_empty():
		add_text("No events are running right now. Check back soon!", 28, "text_dim", HORIZONTAL_ALIGNMENT_CENTER)
	for ev in evs:
		var prog := GameState.event_progress(ev.id)
		var target: int = int(ev.target)
		var claimed := GameState.event_claimed(ev.id)
		var v := add_card(str(ev.name), "%s  (%d / %d)\nReward: %s\nEnds %s" % [ev.desc, mini(prog, target), target, GameState.reward_text(ev.reward), ev["end"]],
			"Claimed" if claimed else "Claim", func(): _claim(ev), prog >= target and not claimed, "good", false)
		v.add_child(add_progress(prog, target))

func _claim(ev: Dictionary) -> void:
	if GameState.claim_event(ev): toast("Reward claimed!")
	refresh()
