extends Screen

func build() -> void:
	begin_page("Inventory")
	add_heading("Currency")
	add_card("Coins", "Spend on boosters and continues", "", Callable(), true, "primary", false).add_child(UIKit.label(str(GameState.currency("coins")), 36, "accent", HORIZONTAL_ALIGNMENT_LEFT, false))
	add_card("Gems", "Premium currency", "", Callable(), true, "primary", false).add_child(UIKit.label(str(GameState.currency("gems")), 36, "accent", HORIZONTAL_ALIGNMENT_LEFT, false))
	add_heading("Boosters")
	var desc := {"hammer": "Removes one block from the board", "refresh": "Replaces the whole tray with new pieces", "shuffle": "Re-rolls the unused pieces"}
	for n in ["hammer", "refresh", "shuffle"]:
		var price: int = int(GameSession.BOOSTER_CFG[n].cost_coins)
		var v := add_card("%s  x%d" % [n.capitalize(), GameState.booster_count(n)], desc[n] + "\nMax %d per game." % int(GameSession.BOOSTER_CFG[n].game_limit),
			"Buy %d" % price, func(): _buy(n), GameState.currency("coins") >= price, "accent", false)
		if AdsService.rewarded_available():
			var b := UIKit.button("Watch ad: +1", "good", Vector2(0, 56))
			b.pressed.connect(func(): await _ad(n))
			v.add_child(b)

func _buy(n: String) -> void:
	if GameState.buy_booster_with_coins(n): toast("Purchased")
	refresh()

func _ad(n: String) -> void:
	var ok: bool = await AdsService.show_rewarded("booster_" + n)
	if ok:
		GameState.add_booster(n, int(GameSession.BOOSTER_CFG[n].ad_reward))
		toast("Booster added!")
	else:
		toast("Ad not available right now")
	refresh()
