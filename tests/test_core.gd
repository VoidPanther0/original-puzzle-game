extends TestCase

func test_grid_init() -> void:
	var b := Board.new()
	eq(b.cells.size(), 64, "64 cells")
	eq(b.occupied_count(), 0, "empty at start")
	check(b.is_empty(), "is_empty")
	b.set_cell(7, 7, 3)
	eq(b.get_cell(7, 7), 3, "addressable corner")
	eq(b.cells[63], 3, "index 63")

func test_piece_db() -> void:
	eq(PieceDB.count(), 42, "42 pieces")
	eq(PieceDB.validate_all(), "", "all pieces valid")
	var sizes := {}
	for p in PieceDB.all(): sizes[p.size] = true
	check(sizes.has(1) and sizes.has(5), "sizes 1..5 present")

func test_placement_and_invalid() -> void:
	var b := Board.new()
	var o := piece("o_0")
	check(b.can_place(o, 0, 0), "o fits top-left")
	check(b.can_place(o, 6, 6), "o fits bottom-right")
	check(not b.can_place(o, 7, 7), "o overflows corner")
	check(not b.can_place(o, -1, 0), "negative row")
	check(not b.can_place(o, 0, 7), "right overflow")
	b.place(o, 3, 3)
	check(not b.can_place(piece("dot_0"), 3, 3), "overlap rejected")
	check(not b.place(piece("domino_0"), 3, 2), "place() overlap false")
	eq(b.occupied_count(), 4, "unchanged by failed place")

func test_row_clear() -> void:
	var b := Board.new()
	fill_row(b, 2, 4)
	b.place(piece("dot_0"), 2, 4)
	var res := LineClearManager.clear(b)
	eq(res.rows, [2], "row 2 cleared")
	eq(b.occupied_count(), 0, "board empty after")

func test_col_clear() -> void:
	var b := Board.new()
	fill_col(b, 5, 0)
	b.place(piece("dot_0"), 0, 5)
	var res := LineClearManager.clear(b)
	eq(res.cols, [5], "col 5 cleared")
	eq(res.lines, 1, "one line")

func test_simultaneous_clear_and_intersection() -> void:
	var b := Board.new()
	fill_row(b, 3)
	fill_col(b, 4)
	var res := LineClearManager.detect(b)
	eq(res.lines, 2, "row+col = 2 lines")
	eq(res.cells.size(), 15, "intersection counted once (8+8-1)")
	LineClearManager.clear(b)
	eq(b.occupied_count(), 0, "all cleared")
	# multiple rows + keep unrelated cell
	var b2 := Board.new()
	fill_row(b2, 0)
	fill_row(b2, 1)
	b2.set_cell(5, 5, 2)
	var r2 := LineClearManager.clear(b2)
	eq(r2.lines, 2, "two rows")
	eq(b2.occupied_count(), 1, "unrelated cell kept")

func test_preview_does_not_mutate() -> void:
	var b := Board.new()
	fill_row(b, 0, 0)
	var pv := LineClearManager.preview(b, piece("dot_0"), 0, 0)
	eq(pv.lines, 1, "preview sees clear")
	eq(b.occupied_count(), 7, "board untouched")

func test_scoring_and_combo() -> void:
	var s := ScoringManager.new()
	var r := s.apply_move(4, 0)
	eq(r.gained, 4, "placement only")
	eq(s.combo, 0, "no combo")
	r = s.apply_move(4, 1)
	eq(s.combo, 1, "combo 1")
	eq(r.clear, 10, "one line = 10 at x1")
	r = s.apply_move(4, 1)
	eq(s.combo, 2, "combo 2")
	eq(r.clear, 15, "x1.5 multiplier")
	r = s.apply_move(1, 0)
	eq(s.combo, 0, "combo reset")
	var m := ScoringManager.new()
	var rr := m.apply_move(1, 2)
	eq(rr.clear, 30, "two lines = 20 + 10 bonus")
	var big := ScoringManager.new()
	var rb := big.apply_move(1, 1, true)
	eq(rb.clear, 110, "board clear bonus")
	var cm := ScoringManager.new()
	eq(cm.combo_multiplier(100), 1.0 + 0.5 * 7, "combo capped")

func test_death_detection() -> void:
	var b := Board.new()
	check(not DeathDetector.is_dead(b, [piece("i5_0")]), "empty board alive")
	# checkerboard: only dot fits? no - checkerboard has no free dots either side; fill all but 1
	for i in 64: b.cells[i] = 1
	check(DeathDetector.is_dead(b, [piece("dot_0"), piece("o_0")]), "full board dead")
	b.cells[10] = 0
	check(not DeathDetector.is_dead(b, [piece("dot_0"), piece("o_0")]), "dot fits hole")
	check(DeathDetector.is_dead(b, [piece("o_0"), piece("domino_0")]), "no big piece fits single hole")
	check(DeathDetector.is_dead(b, [null, null, null]), "empty tray with nothing = dead")

func test_game_over_not_triggered_with_valid_move() -> void:
	var s := GameSession.new(1)
	check(not s.game_over, "fresh game alive")
	s.board.clear_all()
	for i in 64: s.board.cells[i] = 1
	s.board.cells[0] = 0
	s.tray = [piece("o_0"), piece("dot_0"), null]
	s._check_game_over()
	check(not s.game_over, "valid move exists")
	var res := s.place(1, 0, 0)
	check(res.ok, "placed dot")
	check(res.clear.lines >= 1, "cleared lines")

func test_move_solver() -> void:
	var b := Board.new()
	fill_row(b, 7, 3)
	var tray := [piece("o_0"), piece("dot_0"), null]
	var best := MoveSolver.best_move(b, tray)
	eq(best.index, 1, "dot completing row chosen")
	eq(best.anchor, Vector2i(3, 7), "at gap")
	check(MoveSolver.tray_playable_in_full(Board.new(), [piece("o_0"), piece("i5_0"), piece("u5_0")]), "empty board playable")
	var tight := Board.new()
	for i in 64: tight.cells[i] = 1
	tight.cells[0] = 0
	check(MoveSolver.tray_playable_in_full(tight, [piece("dot_0"), piece("o_0")]), "dot wipes the whole board (8 rows+8 cols), so the 2x2 then fits")
	check(not MoveSolver.tray_playable_in_full(tight, [piece("o_0")]), "2x2 alone cannot fit a single hole")
	check(MoveSolver.tray_playable_in_full(tight, [piece("dot_0"), piece("dot_0")]), "clear from first dot makes room for second")

# ---------------------------------------------------------------- gravity (rules v2)
func test_gravity_compacts_columns() -> void:
	var b := Board.new()
	b.set_cell(0, 2, 1)
	b.set_cell(3, 2, 2)
	b.set_cell(5, 4, 3)
	check(LineClearManager.gravity(b), "something moved")
	eq(b.get_cell(7, 2), 2, "lower block rests on floor first")
	eq(b.get_cell(6, 2), 1, "upper block stacks on it")
	eq(b.get_cell(7, 4), 3, "lone block drops to floor")
	eq(b.occupied_count(), 3, "no blocks lost")
	check(not LineClearManager.gravity(b), "settled board does not move")

func test_row_clear_drops_blocks_above() -> void:
	var b := Board.new()
	fill_row(b, 7)
	b.set_cell(6, 3, 5)
	b.set_cell(4, 3, 6)
	var res := LineClearManager.resolve(b)
	eq(res.lines, 1, "one line")
	eq(b.get_cell(7, 3), 5, "block above the cleared row falls into it")
	eq(b.get_cell(6, 3), 6, "and the next one follows")
	eq(b.occupied_count(), 2, "only the two blocks remain")
	check(res.falls.size() == 2, "falls reported for animation")

func test_vertical_clear_drops_neighbours() -> void:
	var b := Board.new()
	fill_col(b, 0)
	b.set_cell(2, 1, 4)           # floating next to the column
	var res := LineClearManager.resolve(b)
	eq(res.lines, 1, "column cleared")
	eq(b.get_cell(7, 1), 4, "neighbour falls to the floor")
	eq(b.get_cell(2, 1), 0, "old position empty")

func test_cascade_chain_clear() -> void:
	# Part 1: a clear whose fall does NOT complete anything stops after one round.
	# Part 2: row 6 drops into row 7 and a loose block fills its gap -> second (chain) clear.
	var b := Board.new()
	for c in range(1, 8):
		b.set_cell(7, c, 1)       # row 7 needs col 0
		b.set_cell(5, c, 1)       # row 5 needs col 0 (row 6 empty)
	b.set_cell(7, 0, 1)           # completes row 7
	var res := LineClearManager.resolve(b)
	eq(res.lines, 1, "first clear: row 7 only")
	eq(res.rounds, 1, "no second round yet")
	var b2 := Board.new()
	for c in range(1, 8):
		b2.set_cell(7, c, 1)
		b2.set_cell(6, c, 1)
	b2.set_cell(7, 0, 1)          # completes row 7
	b2.set_cell(3, 0, 2)          # will fall into row 7... col 0 of the row that drops down
	var r2 := LineClearManager.resolve(b2)
	eq(r2.rounds, 2, "gravity completed a second line (chain)")
	eq(r2.lines, 2, "two lines in total")
	eq(b2.occupied_count(), 0, "row 6 fell into row 7, the loose block completed it: board empty")

func test_session_gravity_and_score() -> void:
	var s := GameSession.new(3)
	s.board.clear_all()
	fill_row(s.board, 7, 0)
	s.board.set_cell(5, 5, 4)     # floating block (e.g. from earlier clears)
	s.tray = [piece("dot_0"), null, null]
	var res := s.place(0, 7, 0)
	check(res.ok, "placed")
	eq(res.clear.lines, 1, "row cleared")
	eq(s.board.get_cell(7, 5), 4, "floating block fell down after the clear")
	eq(s.board.get_cell(5, 5), 0, "left its old cell")

func test_level_layouts_are_settled() -> void:
	for ch in LevelDB.chapters():
		for i in range(1, int(ch.levels) + 1):
			var lv := LevelDB.get_level(int(ch.id), i)
			var b := Board.new()
			for rc in lv.start_cells: b.set_cell(rc[0], rc[1], 9)
			var copy := b.copy()
			check(not LineClearManager.gravity(copy), "layout rests on the floor %s" % lv.id)
			eq(LineClearManager.detect(b).lines, 0, "no completed line at start %s" % lv.id)
