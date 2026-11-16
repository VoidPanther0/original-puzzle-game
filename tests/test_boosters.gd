extends TestCase

func _session() -> GameSession:
	var s := GameSession.new(42)
	return s

func test_hammer() -> void:
	var s := _session()
	s.board.set_cell(3, 3, 2)
	check(not s.use_hammer(0, 0), "cannot hammer empty cell")
	check(s.use_hammer(3, 3), "hammer removes block")
	eq(s.board.get_cell(3, 3), 0, "cell empty")
	eq(s.booster_remaining("hammer"), 2, "limit tracked")
	for i in 2:
		s.board.set_cell(1, 1, 2)
		check(s.use_hammer(1, 1), "hammer %d" % i)
	s.board.set_cell(1, 1, 2)
	check(not s.use_hammer(1, 1), "game limit reached")
	check(not s.use_hammer(-1, 0), "out of bounds")

func test_refresh_and_shuffle() -> void:
	var s := _session()
	var before := s.tray.duplicate()
	check(s.use_refresh(), "refresh")
	eq(s.tray.size(), 3, "3 pieces")
	for p in s.tray: check(p != null, "filled")
	s.tray[1] = null
	check(s.use_shuffle(), "shuffle")
	check(s.tray[1] == null, "empty slot stays empty")
	check(s.tray[0] != null and s.tray[2] != null, "others rerolled")
	s.tray = [null, null, null]
	check(not s.use_shuffle(), "nothing to shuffle")
	eq(before.size(), 3, "sanity")

func test_booster_config_override() -> void:
	var s := _session()
	s.booster_cfg["hammer"].game_limit = 1
	s.board.set_cell(7, 0, 1)
	s.board.set_cell(7, 1, 1)
	check(s.use_hammer(7, 0), "first")
	check(not s.use_hammer(7, 1), "limit 1")
	s.booster_cfg["hammer"].game_limit = 0
	check(s.use_hammer(7, 1), "unlimited when 0")

func test_hammer_revives_dead_board() -> void:
	var s := _session()
	for i in 64: s.board.cells[i] = 1
	s.tray = [PieceDB.get_piece("o_0"), null, null]
	s._check_game_over()
	check(s.game_over, "dead")
	check(not s.use_hammer(0, 0), "no boosters after game over")

func test_continue() -> void:
	var s := _session()
	for i in 64: s.board.cells[i] = 1
	s.board.cells[0] = 0
	s.tray = [PieceDB.get_piece("o_0"), null, null]
	s._check_game_over()
	check(s.game_over, "dead")
	check(s.continue_game(), "revived")
	check(not s.game_over, "alive")
	eq(s.continues_used, 1, "counted")
	check(s.board.occupied_count() <= 48, "two rows cleared")

func test_level_goal_and_stars() -> void:
	var lv := LevelDB.get_level(1, 1)
	var s := GameSession.new(5, "level", lv)
	s.scoring.score = int(lv.goal.target) - 1
	s._check_level_goal()
	check(not s.level_complete, "not yet")
	s.scoring.score = int(lv.goal.target)
	s._check_level_goal()
	check(s.level_complete, "complete")
	eq(s.stars(), 1, "one star")
	s.scoring.score = int(lv.stars[2])
	eq(s.stars(), 3, "three stars")

func test_event_log_records() -> void:
	var s := _session()
	var moves := MoveSolver.all_moves(s.board, s.tray)
	var m: Dictionary = moves[0]
	s.place(m.index, m.anchor.y, m.anchor.x)
	var kinds: Array = []
	for e in s.event_log: kinds.append(e.t)
	check("tray" in kinds and "p" in kinds, "log has tray and place events")
