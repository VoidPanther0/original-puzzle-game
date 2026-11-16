extends Screen

func build() -> void:
	begin_page("Shop")
	add_heading("Free")
	add_card("Free coins", "Watch a short ad to earn 50 coins", "Watch", _free_coins, AdsService.rewarded_available(), "good")
	add_heading("Spend coins / gems")
	for it in LevelDB.meta().get("shop", []):
		if it.kind == "coins" or it.kind == "gems":
			var cur: String = "coins" if it.kind == "coins" else "gems"
			add_card(str(it.name), "Gives " + GameState.reward_text(it.give), "%d %s" % [int(it.cost), cur],
				func(): _buy(it), GameState.currency(cur) >= int(it.cost), "accent", false)
	add_heading("Real-money packs")
	if not BillingService.is_available():
		add_text(BillingService.unavailable_reason(), 22, "text_dim")
	for it in LevelDB.meta().get("shop", []):
		if it.kind == "iap":
			var owned: bool = it.give.has("ads_removed") and GameState.ads_removed()
			add_card(str(it.name), "Gives " + GameState.reward_text(it.give), "Owned" if owned else str(it.price_label),
				func(): await _iap(it), BillingService.is_available() and not owned, "primary", false)
	if BillingService.test_mode_active():
		add_text("Debug build: purchases are granted without payment (test mode).", 20, "danger")

func _buy(it: Dictionary) -> void:
	if GameState.buy_item(it): toast("Purchased!")
	else: toast("Not enough currency")
	refresh()

func _iap(it: Dictionary) -> void:
	var ok: bool = await BillingService.purchase(it)
	toast("Purchase complete" if ok else "Purchase failed")
	refresh()

func _free_coins() -> void:
	var ok: bool = await AdsService.show_rewarded("shop_coins")
	if ok:
		GameState.add_currency("coins", 50)
		toast("+50 coins")
	else:
		toast("Ad not available right now")
	refresh()
