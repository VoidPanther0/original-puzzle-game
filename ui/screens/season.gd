extends Screen

func build() -> void:
	begin_page("Season Pass")
	var se := GameState.season()
	var per: int = int(se.get("xp_per_tier", 400))
	var xp: int = int(GameState.d().season.xp)
	add_text(str(se.get("name", "Season")), 34, "accent", HORIZONTAL_ALIGNMENT_CENTER, false)
	add_text("XP %d  -  earn XP by playing games" % xp, 24, "text_dim", HORIZONTAL_ALIGNMENT_CENTER, false)
	var tiers: Array = se.get("tiers", [])
	list.add_child(add_progress(xp, per * tiers.size()))
	for i in tiers.size():
		var unlocked := GameState.season_tier_unlocked(i)
		var claimed := GameState.season_tier_claimed(i)
		var txt := "Claimed" if claimed else ("Claim" if unlocked else "Locked")
		add_card("Tier %d" % (i + 1), GameState.reward_text(tiers[i]) + ("" if unlocked else "   (needs %d XP)" % ((i + 1) * per)),
			txt, func(): _claim(i), unlocked and not claimed, "good", false)

func _claim(i: int) -> void:
	if GameState.claim_season_tier(i): toast("Reward claimed!")
	refresh()
