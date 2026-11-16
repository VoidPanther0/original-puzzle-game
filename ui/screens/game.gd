extends Screen
## Main gameplay screen: HUD, boosters, board view, pause / game-over overlays.

var session: GameSession
var view: BoardView
var score_label: Label
var best_label: Label
var goal_label: Label
var goal_bar: ProgressBar
var combo_label: Label
var shots_chip: ShotsChip
var _shown_score := 0.0
var _booster_btns := {}
var _overlay: Control
var _finished := false
var _paused := false

func build() -> void:
	session = GameState.session
	if session == null:
		GameState.start_endless()
		session = GameState.session
	make_column(640, 10)
	column.add_child(UIKit.spacer(10))
	# HUD
	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 12)
	column.add_child(hud)
	var pause := UIKit.square_button("II")
	pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pause.pressed.connect(_pause)
	hud.add_child(pause)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(mid)
	mid.add_child(UIKit.label("SCORE", 20, "text_dim", HORIZONTAL_ALIGNMENT_CENTER))
	score_label = UIKit.label("0", 56, "text", HORIZONTAL_ALIGNMENT_CENTER, false)
	mid.add_child(score_label)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(150, 0)
	hud.add_child(right)
	right.add_child(UIKit.label("BEST", 20, "text_dim", HORIZONTAL_ALIGNMENT_CENTER))
	best_label = UIKit.label(str(GameState.d().best_score), 34, "accent", HORIZONTAL_ALIGNMENT_CENTER, false)
	right.add_child(best_label)
	# goal / combo row
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 12)
	column.add_child(info)
	goal_label = UIKit.label("", 24, "text", HORIZONTAL_ALIGNMENT_LEFT, false)
	goal_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.add_child(goal_label)
	goal_bar = add_progress(0, 1)
	goal_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(goal_bar)
	combo_label = UIKit.label("", 26, "accent", HORIZONTAL_ALIGNMENT_RIGHT, false)
	combo_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.add_child(combo_label)
	# remaining shots (stone blocks can be shot away)
	shots_chip = ShotsChip.new()
	shots_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(shots_chip)
	# board
	view = BoardView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(view)
	view.bind(session)
	view.moved.connect(_on_moved)
	view.cell_tapped.connect(_on_cell_tapped)
	# boosters
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	column.add_child(bar)
	for n in ["hammer", "refresh", "shuffle"]:
		var b := UIKit.button(n.capitalize(), "secondary", Vector2(0, 76))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ic := UIKit.tex({"hammer": "hammer", "refresh": "recycle", "shuffle": "shuffle"}[n])
		if ic != null:
			b.icon = ic
			b.expand_icon = false
			b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 22)
			b.add_theme_constant_override("icon_max_width", 40)
			b.add_theme_constant_override("h_separation", 4)
		b.pressed.connect(_use_booster.bind(n))
		bar.add_child(b)
		_booster_btns[n] = b
	column.add_child(UIKit.spacer(8))
	_update_hud(true)
	if session.game_over: _show_game_over()

func _process(delta: float) -> void:
	if int(_shown_score) != session.scoring.score:
		_shown_score = move_toward(_shown_score, session.scoring.score, maxf(1.0, absf(session.scoring.score - _shown_score) * delta * 8.0))
		score_label.text = str(int(_shown_score))

func _update_hud(instant: bool = false) -> void:
	if instant:
		_shown_score = session.scoring.score
		score_label.text = str(session.scoring.score)
	best_label.text = str(maxi(int(GameState.d().best_score), session.scoring.score))
	var goal: Dictionary = session.level.get("goal", {})
	if session.mode != "endless" and not goal.is_empty():
		var cur: int = session.scoring.score if goal.type == "score" else session.scoring.lines_cleared
		goal_label.text = I18n.t("Goal %d") % int(goal.target)
		goal_bar.max_value = int(goal.target)
		goal_bar.value = minf(cur, int(goal.target))
		goal_bar.visible = true
	else:
		goal_label.text = I18n.t("Moves %d") % session.moves
		goal_bar.visible = false
	combo_label.text = ("COMBO x%d" % session.scoring.combo) if session.scoring.combo >= 2 else ""
	shots_chip.visible = session.has_stone()
	shots_chip.set_shots(session.shots)
	for n in _booster_btns:
		var cnt := GameState.booster_count(n)
		var left := session.booster_remaining(n)
		var b: Button = _booster_btns[n]
		b.text = "%s  x%d" % [I18n.t(n.capitalize()), cnt] if cnt > 0 else "%s  +" % I18n.t(n.capitalize())
		b.disabled = session.game_over or left <= 0

# ---------------------------------------------------------------- game flow
func _on_moved(res: Dictionary) -> void:
	GameState.on_move(res)
	_update_hud()
	if res.level_complete:
		view.input_enabled = false
		await get_tree().create_timer(1.3 if res.clear.lines > 0 else 0.8).timeout
		AudioManager.play("win")
		var summary := GameState.finish_session()
		_finished = true
		main.go("level_complete", {"summary": summary})
	elif res.game_over:
		view.input_enabled = false
		await get_tree().create_timer(1.3 if res.clear.lines > 0 else 0.8).timeout
		_show_game_over()

func _use_booster(name: String) -> void:
	if session.game_over or _paused: return
	if GameState.booster_count(name) <= 0:
		_offer_booster(name)
		return
	if not session.can_use_booster(name):
		toast(I18n.t("Booster limit reached for this game"))
		return
	match name:
		"hammer":
			view.hammer_mode = not view.hammer_mode
			view.queue_redraw()
			if view.hammer_mode: toast(I18n.t("Tap a block to remove it"))
		"refresh":
			if session.use_refresh():
				GameState.consume_booster("refresh")
				AudioManager.play("booster")
				view.fx_tray_refreshed()
				_after_booster()
		"shuffle":
			if session.use_shuffle():
				GameState.consume_booster("shuffle")
				AudioManager.play("booster")
				view.fx_tray_refreshed()
				_after_booster()
			else:
				toast(I18n.t("Nothing to shuffle"))

func _after_booster() -> void:
	_update_hud()
	GameState.save_run()
	view.queue_redraw()
	if session.game_over: _show_game_over()

func _on_cell_tapped(row: int, col: int) -> void:
	if session.game_over or _paused: return
	if view.hammer_mode:
		_hammer_at(row, col)
		return
	_shot_at(row, col)

## Hammer booster: removes any occupied cell.
func _hammer_at(row: int, col: int) -> void:
	var color := session.board.get_cell(row, col)
	if color == 0: return
	if session.use_hammer(row, col):
		GameState.consume_booster("hammer")
		view.hammer_mode = false
		view.fx_cell_removed(row, col, color)
		view.fx_falls(session.last_falls)
		AudioManager.play("booster")
		Platform.vibrate(30)
		_after_booster()

## Shooting: the 1st hit cracks a stone block, the 2nd hit destroys it (costs one shot).
func _shot_at(row: int, col: int) -> void:
	var res := session.shoot(row, col)
	if not res.get("ok", false):
		if str(res.get("reason", "")) == "no_shots":
			toast(I18n.t("No shots left"))
			AudioManager.play("invalid")
		return
	if res.get("cracked", false):
		view.fx_cell_cracked(row, col)
		AudioManager.play("crack")
		Platform.vibrate(18)
		view.queue_redraw()
		return
	view.fx_cell_destroyed(row, col)
	view.fx_cell_removed(row, col, GameSession.STONE)
	view.fx_falls(session.last_falls)
	AudioManager.play("shot")
	Platform.vibrate(45)
	_after_booster()

func _offer_booster(name: String) -> void:
	var price: int = int(GameSession.BOOSTER_CFG[name].cost_coins)
	var btns: Array = []
	if AdsService.rewarded_available():
		btns.append([I18n.t("Watch ad: +1 %s") % name.capitalize(), func(): await _watch_for_booster(name), "good"])
	btns.append([I18n.t("Buy for %d coins") % price, func(): _buy_booster(name), "primary"])
	btns.append(["Cancel", Callable(), "secondary"])
	dialog("Get %s" % name.capitalize(), "You have no %s boosters left." % name, btns)

func _buy_booster(name: String) -> void:
	if GameState.buy_booster_with_coins(name):
		toast(I18n.t("Purchased"))
		_update_hud()
	else:
		toast(I18n.t("Not enough coins"))

func _watch_for_booster(name: String) -> void:
	var ok: bool = await AdsService.show_rewarded("booster_" + name)
	if ok:
		GameState.add_booster(name, int(GameSession.BOOSTER_CFG[name].ad_reward))
		toast(I18n.t("Booster added!"))
		_update_hud()
	else:
		toast(I18n.t("Ad not available right now"))

# ---------------------------------------------------------------- overlays
func _pause() -> void:
	if is_instance_valid(_overlay) or session.game_over: return
	_paused = true
	view.input_enabled = false
	_overlay = dialog("Paused", "", [
		["Resume", _resume, "primary"],
		["Restart", func(): await _leave("restart"), "secondary"],
		["Sound: %s" % ("ON" if bool(SaveManager.get_setting("sfx", true)) else "OFF"), _toggle_sound, "secondary"],
		["Home", func(): await _leave("home"), "danger"],
	])

func _toggle_sound() -> bool:  # false = keep the dialog open
	var on := not bool(SaveManager.get_setting("sfx", true))
	SaveManager.set_setting("sfx", on)
	SaveManager.set_setting("music", on)
	AudioManager.apply_settings()
	toast("Sound on" if on else "Sound off")
	return false

func _resume() -> void:
	_paused = false
	view.input_enabled = true
	_overlay = null

func on_back() -> void:
	if _paused and is_instance_valid(_overlay):
		_overlay.queue_free()
		_resume()
	elif not is_instance_valid(_overlay):
		_pause()

func _show_game_over() -> void:
	if is_instance_valid(_overlay): _overlay.queue_free()
	AudioManager.play("gameover")
	view.input_enabled = false
	if session.mode == "endless": GameState.clear_run()
	var failed_level := session.mode == "level"
	var best := maxi(int(GameState.d().best_score), session.scoring.score)
	var body := "Score  %d\nBest  %d" % [session.scoring.score, best]
	if session.scoring.score > int(GameState.d().best_score): body += "\n" + I18n.t("NEW BEST!")
	var btns: Array = []
	if session.continues_used < 2:
		if AdsService.rewarded_available():
			btns.append([I18n.t("Continue (watch ad)"), func(): await _continue_ad(), "good"])
		btns.append([I18n.t("Continue (200 coins)"), func(): _continue_coins(), "accent"])
	btns.append(["Try Again" if failed_level else "Play Again", func(): await _leave("restart"), "primary"])
	btns.append(["Home", func(): await _leave("home"), "secondary"])
	_overlay = dialog("Level Failed" if failed_level else "Game Over", body, btns, false)
	_paused = false

func _continue_ad() -> void:
	var ok: bool = await AdsService.show_rewarded("continue")
	if ok: _do_continue()
	else:
		toast("Ad not available right now")
		_show_game_over()

func _continue_coins() -> void:
	if GameState.spend("coins", 200):
		if _overlay: _overlay.queue_free()
		_do_continue()
	else:
		toast("Not enough coins")
		_show_game_over()

func _do_continue() -> void:
	if session.continue_game():
		_overlay = null
		view.input_enabled = true
		view.fx_tray_refreshed()
		_update_hud()
		GameState.save_run()
		toast("Continue!")
	else:
		_show_game_over()

func _ensure_finished() -> void:
	if not _finished:
		_finished = true
		GameState.finish_session()
		if BackendService.is_signed_in():
			BackendService.call_deferred("submit_score", session)   # fire-and-forget

func _leave(where: String) -> void:
	var dead := session.game_over
	if dead or (where == "restart" and session.mode == "endless" and session.moves > 0):
		_ensure_finished()
	if dead:
		await AdsService.maybe_show_interstitial()
	if where == "restart":
		match session.mode:
			"level":
				var lv: Dictionary = session.level
				GameState.start_level(int(lv.chapter), int(lv.index))
			"daily": GameState.start_daily()
			_: GameState.start_endless(false)
		main.go("game")
	else:
		main.go("home")
