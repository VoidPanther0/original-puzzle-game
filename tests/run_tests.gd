extends SceneTree
## Headless test runner. Run with:
##   godot --headless --path . -s tests/run_tests.gd
## Exits with code 0 when everything passes, 1 otherwise.

var _passed: int = 0
var _failed: int = 0
var _current: String = ""


func _initialize() -> void:
	for method: Dictionary in get_script().get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_"):
			_current = method_name
			call(method_name)
	print("")
	print("Tests passed: %d   failed: %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("FAIL [%s] %s" % [_current, message])


func eq(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [message, str(expected), str(actual)])


# ---------------------------------------------------------------- helpers

func fill_row(board: BoardModel, row: int, skip_x: int = -1) -> void:
	for x: int in board.size:
		if x != skip_x:
			board.cells[row * board.size + x] = 1


func fill_column(board: BoardModel, column: int, skip_y: int = -1) -> void:
	for y: int in board.size:
		if y != skip_y:
			board.cells[y * board.size + column] = 1


func shape(text: String) -> Array[Vector2i]:
	return PieceDefs.parse(text)


# ------------------------------------------------------------- placement

func test_valid_placement() -> void:
	var board := BoardModel.new(8)
	check(board.can_place(shape("XX/XX"), Vector2i(3, 3)), "2x2 fits on empty board")
	check(board.place(shape("XX/XX"), 2, Vector2i(3, 3)), "place returns true")
	eq(board.get_cell(3, 3), 2, "cell filled with colour id")
	eq(board.get_cell(4, 4), 2, "far corner of piece filled")
	eq(board.get_cell(5, 5), 0, "outside the piece stays empty")


func test_invalid_placement() -> void:
	var board := BoardModel.new(8)
	board.place(shape("X"), 1, Vector2i(2, 2))
	check(not board.can_place(shape("XX"), Vector2i(1, 2)), "overlap rejected")
	check(not board.can_place(shape("XXX"), Vector2i(6, 0)), "right edge rejected")
	check(not board.can_place(shape("XX/XX"), Vector2i(0, 7)), "bottom edge rejected")
	check(not board.can_place(shape("X"), Vector2i(-1, 0)), "negative origin rejected")
	var before: PackedInt32Array = board.cells.duplicate()
	check(not board.place(shape("XX"), 3, Vector2i(1, 2)), "failed place returns false")
	eq(board.cells, before, "failed place leaves board untouched")


func test_piece_pool() -> void:
	var pool: Array = PieceDefs.pool()
	check(pool.size() > 14, "rotations expand the pool (%d shapes)" % pool.size())
	for s: Array[Vector2i] in pool:
		var min_x: int = 99
		var min_y: int = 99
		for c: Vector2i in s:
			min_x = mini(min_x, c.x)
			min_y = mini(min_y, c.y)
		check(min_x == 0 and min_y == 0, "shape normalised")
		check(s.size() >= 1 and s.size() <= 9, "shape size sane")


# ------------------------------------------------------------ row clearing

func test_single_row_clear() -> void:
	var state := GameState.new(1)
	state.tray = [PieceData.new(shape("X"), 3), PieceData.new(shape("X"), 3), PieceData.new(shape("X"), 3)]
	fill_row(state.board, 7, 7)
	var result: Dictionary = state.place_piece(0, Vector2i(7, 7))
	check(result["ok"], "placement ok")
	eq(result["cleared_rows"], [7] as Array[int], "bottom row cleared")
	for x: int in 8:
		eq(state.board.get_cell(x, 7), 0, "row 7 empty after clear (x=%d)" % x)


func test_multiple_simultaneous_clears() -> void:
	var state := GameState.new(1)
	state.tray = [PieceData.new(shape("X/X"), 4), PieceData.new(shape("X"), 4), PieceData.new(shape("X"), 4)]
	fill_row(state.board, 6, 3)
	fill_row(state.board, 7, 3)
	var result: Dictionary = state.place_piece(0, Vector2i(3, 6))
	eq(result["cleared_rows"], [6, 7] as Array[int], "two rows clear together")
	eq(result["points"], 2 + GameState.clear_points(2, 1), "points = cells + clear bonus")
	check(state.board.is_empty(), "board empty afterwards")


func test_no_clear_when_row_incomplete() -> void:
	var state := GameState.new(1)
	state.tray = [PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1)]
	fill_row(state.board, 7, 6)
	var result: Dictionary = state.place_piece(0, Vector2i(0, 0))
	eq(result["cleared_rows"].size(), 0, "nothing cleared")
	eq(state.combo, 0, "combo stays zero")


# ---------------------------------------------------------- column clearing

func test_full_columns() -> void:
	var board := BoardModel.new(8)
	fill_column(board, 3, 0)
	eq(board.full_columns(), [] as Array[int], "a column with a hole is not full")
	board.cells[0 * 8 + 3] = 1
	eq(board.full_columns(), [3] as Array[int], "the filled column is reported")


func test_single_column_clear() -> void:
	var state := GameState.new(1)
	state.tray = [PieceData.new(shape("X"), 3), PieceData.new(shape("X"), 3), PieceData.new(shape("X"), 3)]
	fill_column(state.board, 2, 0)
	var result: Dictionary = state.place_piece(0, Vector2i(2, 0))
	check(result["ok"], "placement ok")
	eq(result["cleared_cols"], [2] as Array[int], "the full column clears")
	eq(result["cleared_rows"].size(), 0, "no row was full")
	for y: int in 8:
		eq(state.board.get_cell(2, y), 0, "column 2 is empty after the clear (y=%d)" % y)
	eq(state.combo, 1, "a column clear counts as a clear")


func test_row_and_column_clear_together() -> void:
	var state := GameState.new(1)
	state.tray = [PieceData.new(shape("X"), 3), PieceData.new(shape("X"), 3), PieceData.new(shape("X"), 3)]
	fill_row(state.board, 7, 0)  # row 7 misses x = 0
	fill_column(state.board, 0, 7)  # column 0 misses y = 7
	var result: Dictionary = state.place_piece(0, Vector2i(0, 7))
	eq(result["cleared_rows"], [7] as Array[int], "the row clears")
	eq(result["cleared_cols"], [0] as Array[int], "the column clears as well")
	eq(result["points"], 1 + GameState.clear_points(2, 1), "two lines score like two lines")
	eq(state.combo, 1, "one clear, combo 1")


func test_column_clear_removes_column() -> void:
	var board := BoardModel.new(8)
	fill_column(board, 1)
	board.cells[3 * 8 + 3] = 2
	board.clear_columns([1] as Array[int])
	eq(board.get_cell(1, 3), 0, "the cleared column is empty")
	# Classic gravity: the surviving block falls to the bottom of its column.
	eq(board.get_cell(3, 7), 2, "the surviving block falls to the bottom (no sideways slide)")


func test_column_clear_keeps_other_blocks() -> void:
	var board := BoardModel.new(8)
	fill_column(board, 0)
	board.cells[2 * 8 + 4] = 5
	board.cells[6 * 8 + 7] = 6
	var no_rows: Array[int] = []
	board.clear_columns([0] as Array[int])
	var total: int = 0
	for v: int in board.cells:
		if v != 0:
			total += 1
	eq(total, 2, "only the cleared column is removed")
	eq(board.get_cell(4, 7), 5, "the first block falls to the bottom")
	eq(board.get_cell(7, 7), 6, "the second block falls to the bottom")


func test_no_cascade_after_clear() -> void:
	var board := BoardModel.new(8)
	for y: int in 8:
		for x: int in 8:
			board.cells[y * 8 + x] = 1
	for x: int in 8:
		board.cells[0 * 8 + x] = 0
	for y: int in 8:
		board.cells[y * 8 + 0] = 0
	fill_column(board, 4)
	eq(board.full_columns(), [4] as Array[int], "column 4 is full")
	var rows: Array[int] = board.full_rows()
	eq(rows.size(), 0, "no row is full")
	board.clear_columns([4] as Array[int])
	board.clear_rows(rows)
	eq(board.full_rows().size(), 0, "the clear creates no new full row")
	eq(board.full_columns().size(), 0, "the clear creates no new full column")


func test_column_clear_is_deterministic() -> void:
	var a := BoardModel.new(8)
	for i: int in 64:
		a.cells[i] = (i * 5 + 2) % 3
	fill_column(a, 6)
	var b: BoardModel = a.duplicate_model()
	a.clear_columns([6] as Array[int])
	b.clear_columns([6] as Array[int])
	eq(a.cells, b.cells, "same input gives same output")


# ----------------------------------------------------------------- gravity

func test_gravity_classic_falls_to_bottom() -> void:
	var board := BoardModel.new(8)
	fill_row(board, 7)  # will be cleared
	board.cells[6 * 8 + 2] = 5  # lone block directly above
	board.cells[4 * 8 + 0] = 6  # floating block higher up
	board.cells[4 * 8 + 1] = 6
	var cleared: Array[int] = board.full_rows()
	eq(cleared, [7] as Array[int], "row 7 is full")
	var result: Dictionary = board.clear_rows(cleared)
	var moved: Array[Vector2i] = result["from"]
	eq(board.get_cell(2, 7), 5, "lone block falls to the bottom")
	eq(board.get_cell(0, 7), 6, "floating pair falls to the bottom")
	eq(board.get_cell(1, 7), 6, "floating pair keeps shape at the bottom")
	eq(board.get_cell(2, 6), 0, "old position emptied")
	eq(board.get_cell(0, 4), 0, "old position emptied (pair)")
	check(moved.size() >= 3, "the three blocks that moved are reported")
	var total: int = 0
	for v: int in board.cells:
		if v != 0:
			total += 1
	eq(total, 3, "exactly the three remaining blocks survive")


func test_gravity_gap_between_rows() -> void:
	# Cleared row in the middle; blocks above fall to the bottom.
	var board := BoardModel.new(8)
	board.cells[7 * 8 + 0] = 2   # below the cleared row, stays (already at bottom)
	fill_row(board, 6)           # cleared
	board.cells[5 * 8 + 3] = 3   # above, falls to the bottom
	var result: Dictionary = board.clear_rows([6] as Array[int])
	eq(board.get_cell(0, 7), 2, "block below clear stays at the bottom")
	eq(board.get_cell(3, 7), 3, "block above clear falls to the bottom")
	check(result["from"].size() >= 1, "at least one block moved")


func test_gravity_two_separate_clears() -> void:
	var board := BoardModel.new(8)
	fill_row(board, 7)
	board.cells[6 * 8 + 1] = 2
	fill_row(board, 5)
	board.cells[4 * 8 + 4] = 3
	var cleared: Array[int] = [5, 7] as Array[int]
	board.clear_rows(cleared)
	eq(board.get_cell(1, 7), 2, "block between clears falls to the bottom")
	eq(board.get_cell(4, 7), 3, "block above both clears falls to the bottom")


func test_gravity_deterministic() -> void:
	var a := BoardModel.new(8)
	for i: int in 64:
		a.cells[i] = (i * 7 + 3) % 4
	fill_row(a, 3)
	fill_row(a, 6)
	var b: BoardModel = a.duplicate_model()
	var rows: Array[int] = [3, 6] as Array[int]
	a.clear_rows(rows)
	b.clear_rows(rows)
	eq(a.cells, b.cells, "same input gives same output")


func test_gravity_no_clear_is_noop() -> void:
	var board := BoardModel.new(8)
	board.cells[3 * 8 + 3] = 4
	var before: PackedInt32Array = board.cells.duplicate()
	var result: Dictionary = board.clear_rows([] as Array[int])
	eq(board.cells, before, "board unchanged with no cleared rows")
	eq(result["from"].size(), 0, "no moves reported")


# ----------------------------------------------------------------- scoring

func test_score_and_combo() -> void:
	var state := GameState.new(1)
	state.tray = [PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1)]
	var r1: Dictionary = state.place_piece(0, Vector2i(0, 0))
	eq(r1["points"], 1, "plain placement scores its cell count")
	eq(state.score, 1, "score accumulates")

	# First clear: combo 1.
	fill_row(state.board, 7, 7)
	var r2: Dictionary = state.place_piece(1, Vector2i(7, 7))
	eq(state.combo, 1, "combo starts at 1")
	eq(r2["points"], 1 + GameState.clear_points(1, 1), "first clear points")

	# Second consecutive clear: combo 2, doubled bonus.
	state.tray[2] = PieceData.new(shape("X"), 1)
	state.tray[0] = null
	state.tray[1] = null
	fill_row(state.board, 7, 7)
	var r3: Dictionary = state.place_piece(2, Vector2i(7, 7))
	eq(state.combo, 2, "combo increments on consecutive clear")
	eq(r3["points"], 1 + GameState.clear_points(1, 2), "combo multiplies bonus")
	check(GameState.clear_points(1, 2) == 2 * GameState.clear_points(1, 1), "combo 2 doubles bonus")
	check(GameState.clear_points(2, 1) > 2 * GameState.clear_points(1, 1), "two rows beat two single clears")


func test_combo_resets() -> void:
	var state := GameState.new(1)
	state.tray = [PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1)]
	fill_row(state.board, 7, 7)
	state.place_piece(0, Vector2i(7, 7))
	eq(state.combo, 1, "combo 1 after clear")
	state.place_piece(1, Vector2i(0, 0))
	eq(state.combo, 0, "combo resets after a placement without clear")


# ------------------------------------------------------------ regeneration

func test_tray_regeneration() -> void:
	var state := GameState.new(7)
	eq(state.tray.size(), 3, "three pieces at start")
	for p: PieceData in state.tray:
		check(p != null, "piece present")
	var spots: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 7), Vector2i(7, 0)]
	state.tray = [PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1)]
	var r0: Dictionary = state.place_piece(0, spots[0])
	check(not r0["refilled"], "no refill after first piece")
	eq(state.tray[0], null, "used slot is empty")
	var r1: Dictionary = state.place_piece(1, spots[1])
	check(not r1["refilled"], "no refill after second piece")
	var r2: Dictionary = state.place_piece(2, spots[2])
	check(r2["refilled"], "refill after the third piece")
	eq(state.tray.size(), 3, "new set has three pieces")
	for p: PieceData in state.tray:
		check(p != null, "new piece present")


func test_generator_deterministic() -> void:
	var a := PieceGenerator.new(42)
	var b := PieceGenerator.new(42)
	for _i: int in 5:
		var sa: Array[PieceData] = a.make_set()
		var sb: Array[PieceData] = b.make_set()
		for k: int in 3:
			eq(sa[k].shape, sb[k].shape, "same seed, same shape")
			eq(sa[k].color_id, sb[k].color_id, "same seed, same colour")


func test_generator_fairness() -> void:
	# On a board where only one single cell is free, a fair set contains "X".
	var board := BoardModel.new(8)
	board.cells.fill(1)
	board.cells[0] = 0
	var gen := PieceGenerator.new(3)
	var fits: int = 0
	for _i: int in 20:
		for p: PieceData in gen.make_set(board):
			if board.can_fit_anywhere(p.shape):
				fits += 1
				break
	check(fits >= 10, "generator usually offers a fitting piece when one exists (%d/20)" % fits)


# --------------------------------------------------------------- game over

func test_game_over_detection() -> void:
	var state := GameState.new(1)
	state.tray = [PieceData.new(shape("XX"), 1), PieceData.new(shape("XX"), 1), PieceData.new(shape("X"), 1)]
	# Checkerboard: no two adjacent free cells, but plenty of single holes.
	for y: int in 8:
		for x: int in 8:
			state.board.cells[y * 8 + x] = 1 if (x + y) % 2 == 0 else 0
	check(state.has_any_move(), "single piece still fits in a hole")
	state.tray = [PieceData.new(shape("XX"), 1), null, PieceData.new(shape("XX/XX"), 1)]
	check(not state.has_any_move(), "no domino or square fits a checkerboard")


func test_game_over_signal() -> void:
	var state := GameState.new(1)
	var fired: Array[bool] = [false]
	state.game_over.connect(func() -> void: fired[0] = true)
	# Checkerboard: every free cell is isolated and no row is complete. After the
	# single is placed, the two dominoes cannot fit anywhere.
	for y: int in 8:
		for x: int in 8:
			state.board.cells[y * 8 + x] = 1 if (x + y) % 2 == 1 else 0
	state.tray = [PieceData.new(shape("X"), 2), PieceData.new(shape("XX"), 2), PieceData.new(shape("XX"), 2)]
	var result: Dictionary = state.place_piece(0, Vector2i(0, 0))
	check(result["ok"], "placement ok")
	check(result["game_over"], "result flags game over")
	check(fired[0], "game_over signal emitted")
	check(state.is_over, "state is over")
	var blocked: Dictionary = state.place_piece(1, Vector2i(7, 7))
	check(not blocked["ok"], "no placement after game over")


func test_not_game_over_when_move_exists() -> void:
	var state := GameState.new(1)
	state.tray = [PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1)]
	var result: Dictionary = state.place_piece(0, Vector2i(0, 0))
	check(not result["game_over"], "empty-ish board is not game over")


# ----------------------------------------------------------------- restart

func test_restart() -> void:
	var state := GameState.new(5)
	state.tray = [PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1), PieceData.new(shape("X"), 1)]
	fill_row(state.board, 7, 7)
	state.place_piece(0, Vector2i(7, 7))
	check(state.score > 0, "score earned before restart")
	state.is_over = true
	state.new_game()
	eq(state.score, 0, "score reset")
	eq(state.combo, 0, "combo reset")
	check(state.board.is_empty(), "board reset")
	check(not state.is_over, "game-over flag reset")
	eq(state.tray.size(), 3, "fresh tray")


# ------------------------------------------------------------ save and load

func test_settings_save_load() -> void:
	var path: String = "user://test_settings.cfg"
	var script: GDScript = load("res://scripts/systems/settings.gd")
	var a: Node = script.new()
	a.save_path = path
	a.best_score = 1234
	a.sound_enabled = false
	a.vibration_enabled = false
	a.ghost_preview = false
	a.volume = 0.35
	eq(a.save_settings(), OK, "save succeeds")
	var b: Node = script.new()
	b.save_path = path
	check(b.load_settings(), "load finds the file")
	eq(b.best_score, 1234, "best score persisted")
	eq(b.sound_enabled, false, "sound flag persisted")
	eq(b.vibration_enabled, false, "vibration flag persisted")
	eq(b.ghost_preview, false, "ghost flag persisted")
	check(is_equal_approx(b.volume, 0.35), "volume persisted")
	a.free()
	b.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_settings_missing_file_defaults() -> void:
	var script: GDScript = load("res://scripts/systems/settings.gd")
	var s: Node = script.new()
	s.save_path = "user://does_not_exist.cfg"
	check(not s.load_settings(), "missing file reports false")
	eq(s.best_score, 0, "default best score")
	eq(s.sound_enabled, true, "default sound on")
	s.free()


func test_best_score_only_increases() -> void:
	var script: GDScript = load("res://scripts/systems/settings.gd")
	var s: Node = script.new()
	s.save_path = "user://test_best.cfg"
	check(s.submit_score(50), "first score is a new best")
	check(not s.submit_score(30), "lower score is not a new best")
	eq(s.best_score, 50, "best score kept")
	check(s.submit_score(80), "higher score is a new best")
	s.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_best.cfg"))
