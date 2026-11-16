extends Screen

func on_back() -> void:
	main.go("profile")

func build() -> void:
	begin_page("Achievements", true, "profile")
	for a in GameState.achievements():
		var prog := GameState.achievement_progress(a)
		var target: int = int(a.target)
		var claimed := GameState.achievement_claimed(a)
		var v := add_card(str(a.name), "%s (%d / %d)   %s" % [a.desc, mini(prog, target), target, GameState.reward_text(a.reward)],
			"Claimed" if claimed else "Claim", func(): _claim(a), GameState.achievement_done(a) and not claimed, "good", false)
		v.add_child(add_progress(prog, target))

func _claim(a: Dictionary) -> void:
	if GameState.claim_achievement(a): toast("Reward claimed!")
	refresh()
