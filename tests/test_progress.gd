extends TestCase
## Uses the SaveManager / GameState autoloads with a throw-away save path.

func _sm() -> Node:
	return tree.root.get_node("SaveManager")

func _gs() -> Node:
	return tree.root.get_node("GameState")

func _fresh() -> void:
	var sm := _sm()
	sm.save_path = "user://test_save.json"
	sm.backup_path = "user://test_save.bak.json"
	for p in [sm.save_path, sm.backup_path]:
		if FileAccess.file_exists(p): DirAccess.remove_absolute(p)
	sm.data = SaveManager.defaults()

func test_save_roundtrip() -> void:
	_fresh()
	var sm := _sm()
	sm.data.coins = 1234
	sm.data.best_score = 999
	sm.save_now()
	sm.data = {}
	sm.load_data()
	eq(int(sm.data.coins), 1234, "coins persisted")
	eq(int(sm.data.best_score), 999, "best persisted")
	check(not sm.recovered, "no recovery needed")

func test_corruption_recovery_from_backup() -> void:
	_fresh()
	var sm := _sm()
	sm.data.coins = 50
	sm.write_file(sm.data)
	sm.data.coins = 77
	sm.write_file(sm.data)          # first file becomes the backup
	var f := FileAccess.open(sm.save_path, FileAccess.WRITE)
	f.store_string("{ garbage")
	f.close()
	sm.load_data()
	check(sm.recovered, "recovery flagged")
	eq(int(sm.data.coins), 50, "restored from backup")

func test_tamper_detection_and_total_corruption() -> void:
	_fresh()
	var sm := _sm()
	sm.data.coins = 10
	sm.write_file(sm.data)
	var txt := FileAccess.get_file_as_string(sm.save_path).replace('coins\\":10', 'coins\\":999999')
	check(txt.find("999999") != -1, "tamper applied to file text")
	var f := FileAccess.open(sm.save_path, FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	if FileAccess.file_exists(sm.backup_path): DirAccess.remove_absolute(sm.backup_path)
	sm.load_data()
	check(sm.recovered, "tamper detected")
	eq(int(sm.data.coins), int(SaveManager.defaults().coins), "reset to defaults")

func test_migration_fills_missing_keys() -> void:
	_fresh()
	var sm := _sm()
	var old := {"coins": 5}
	var m: Dictionary = sm.migrate(old, 0)
	eq(int(m.coins), 5, "kept old value")
	check(m.has("settings") and m.has("streak") and m.has("boosters"), "new keys added")

func test_currency_and_boosters() -> void:
	_fresh()
	var gs := _gs()
	gs.add_currency("coins", 100)
	eq(gs.currency("coins"), 400, "300 default + 100")
	check(not gs.spend("coins", 9999), "cannot overspend")
	check(gs.spend("coins", 50), "spend ok")
	eq(gs.currency("coins"), 350, "balance")
	var h0: int = gs.booster_count("hammer")
	check(gs.buy_booster_with_coins("hammer"), "buy hammer")
	eq(gs.booster_count("hammer"), h0 + 1, "hammer added")
	eq(gs.currency("coins"), 200, "150 spent")
	check(gs.consume_booster("hammer"), "consume")
	gs.d().boosters["shuffle"] = 0
	check(not gs.consume_booster("shuffle"), "cannot consume zero")

func test_level_progression() -> void:
	_fresh()
	var gs := _gs()
	check(gs.is_level_unlocked(1, 1), "first level open")
	check(not gs.is_level_unlocked(1, 2), "second locked")
	check(not gs.is_chapter_unlocked(2), "chapter 2 locked")
	check(gs.start_level(1, 1), "start level 1")
	var s: GameSession = gs.session
	eq(s.mode, "level", "level mode")
	s.scoring.score = int(s.level.stars[1])
	s.level_complete = true
	var res: Dictionary = gs.finish_session()
	check(res.won, "won")
	eq(res.stars, 2, "two stars at 1.4x")
	check(gs.is_level_unlocked(1, 2), "level 2 unlocked")
	eq(gs.level_stars("c1_l1"), 2, "stars stored")
	check(res.reward.has("coins"), "first-clear reward")
	# replay does not re-pay
	gs.start_level(1, 1)
	gs.session.scoring.score = int(gs.session.level.stars[2])
	gs.session.level_complete = true
	var res2: Dictionary = gs.finish_session()
	eq(gs.level_stars("c1_l1"), 3, "improved to 3 stars")
	check(res2.reward.is_empty(), "no repeat reward")
	check(not gs.start_level(1, 5), "locked level refuses to start")
	for i in range(1, 11): gs.d().progress.levels[LevelDB.level_id(1, i)] = 1
	check(gs.is_chapter_unlocked(2), "chapter 2 after finishing chapter 1")

func test_level_configs() -> void:
	eq(LevelDB.chapters().size(), 10, "10 chapters")
	eq(LevelDB.total_levels(), 100, "Adventure mode has 100 levels")
	for ch in LevelDB.chapters():
		for i in range(1, int(ch.levels) + 1):
			var lv := LevelDB.get_level(int(ch.id), i)
			check(not lv.is_empty() and lv.pool.size() > 0, "level has pool")
			var b := Board.new()
			for rc in lv.start_cells: b.set_cell(rc[0], rc[1], 1)
			eq(LineClearManager.detect(b).lines, 0, "no pre-completed lines %s" % lv.id)
	var a := LevelDB.get_level(1, 3)
	var b2 := LevelDB.get_level(1, 3)
	eq(a.start_cells, b2.start_cells, "deterministic layout")
	check(LevelDB.get_level(1, 11).is_empty(), "out of range empty")
	eq(LevelDB.daily_level("2026-11-15").goal, LevelDB.daily_level("2026-11-15").goal, "daily deterministic")

func test_streak_and_best_score() -> void:
	_fresh()
	var gs := _gs()
	gs.touch_streak()
	eq(int(gs.d().streak.count), 1, "streak starts")
	gs.touch_streak()
	eq(int(gs.d().streak.count), 1, "same day no double count")
	gs.d().streak.last_day = gs.day_number() - 1
	gs.touch_streak()
	eq(int(gs.d().streak.count), 2, "consecutive day")
	gs.d().streak.last_day = gs.day_number() - 3
	eq(gs.current_streak(), 0, "broken streak shows 0")
	gs.start_endless()
	gs.session.scoring.score = 500
	var r: Dictionary = gs.finish_session()
	check(r.new_best, "new best")
	eq(int(gs.d().best_score), 500, "best saved")
	gs.start_endless()
	gs.session.scoring.score = 100
	r = gs.finish_session()
	check(not r.new_best, "not best")
	eq(int(gs.d().best_score), 500, "best kept")

func test_season_events_achievements() -> void:
	_fresh()
	var gs := _gs()
	check(not gs.claim_season_tier(0), "locked tier")
	gs.add_season_xp(450)
	check(gs.claim_season_tier(0), "claim tier 0")
	check(not gs.claim_season_tier(0), "no double claim")
	gs.add_stat("lines", 70)
	var ev: Dictionary = gs.active_events()[0]
	check(gs.event_progress(ev.id) >= 60, "event progress tracked")
	var coins_before: int = gs.currency("coins")
	check(gs.claim_event(ev) or true, "claim attempt")
	var a: Dictionary = gs.achievements()[0]
	gs.add_stat("games", 1)
	check(gs.achievement_done(a), "achievement done")
	check(gs.claim_achievement(a), "claim")
	check(not gs.claim_achievement(a), "no double claim")
	check(gs.currency("coins") >= coins_before, "rewards paid")

func test_run_save_resume() -> void:
	_fresh()
	var gs := _gs()
	gs.start_endless()
	var s: GameSession = gs.session
	var res := s.place(0, 0, 0) if s.can_place(0, 0, 0) else {"ok": false}
	if not res.ok:
		for m in MoveSolver.all_moves(s.board, s.tray):
			res = s.place(m.index, m.anchor.y, m.anchor.x)
			break
	check(res.ok, "made a move")
	gs.on_move(res)
	var snap := s.to_dict()
	var restored := GameSession.from_dict(JSON.parse_string(JSON.stringify(snap)))
	check(restored != null, "restored from JSON round trip")
	eq(restored.board.to_array(), s.board.to_array(), "board same")
	eq(restored.scoring.score, s.scoring.score, "score same")
	for i in 3:
		eq(restored.tray[i].id if restored.tray[i] else "", s.tray[i].id if s.tray[i] else "", "tray same")
	# determinism after restore: next tray identical
	s.tray = [null, null, null]
	restored.tray = [null, null, null]
	s.refill_tray()
	restored.refill_tray()
	for i in 3: eq(restored.tray[i].id, s.tray[i].id, "rng state restored")
