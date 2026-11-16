extends TestCase

func _ids(t: Array) -> Array:
	var o: Array = []
	for p in t: o.append(p.id)
	return o

func test_deterministic_seed() -> void:
	var a := PieceGenerator.new(12345)
	var b := PieceGenerator.new(12345)
	var board := Board.new()
	for _i in 5:
		eq(_ids(a.generate_tray(board)), _ids(b.generate_tray(board)), "same seed same tray")
	var c := PieceGenerator.new(999)
	var differs := false
	var d := PieceGenerator.new(12345)
	for _i in 5:
		if _ids(c.generate_tray(board)) != _ids(d.generate_tray(board)): differs = true
	check(differs, "different seed differs")

func test_tray_never_dead_when_move_exists() -> void:
	var g := PieceGenerator.new(7)
	var board := Board.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for _round in 60:
		board.clear_all()
		for i in 64:
			if rng.randf() < 0.55: board.cells[i] = 1
		var any_fits := false
		for p in PieceDB.all():
			if PlacementValidator.can_place_anywhere(board, p): any_fits = true
		var tray := g.generate_tray(board)
		eq(tray.size(), 3, "three pieces")
		if any_fits:
			check(not DeathDetector.is_dead(board, tray), "tray has a playable piece")

func test_pool_restriction() -> void:
	var g := PieceGenerator.new(1, ["dot_0", "domino_0"])
	for _i in 20:
		for p in g.generate_tray(Board.new()):
			check(p.id in ["dot_0", "domino_0"], "only pool pieces")

func test_all_algorithms_return_valid() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var board := Board.new()
	fill_row(board, 6, 2)
	fill_row(board, 7, 2)
	for name in Algorithms.NAMES:
		var p := Algorithms.select(name, board, PieceDB.all(), rng)
		check(p.is_empty() or p.has("cells"), name + " returns piece or empty")
		if name in ["can_put", "random_no_die", "fill_sort", "fill_weight", "clear", "score", "hole_max_diff", "avoid_clear_board", "deal_death_state"]:
			check(not p.is_empty(), name + " found a piece")

func test_algo_can_put_and_clear() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var board := Board.new()
	for i in 64: board.cells[i] = 1
	board.cells[0] = 0
	for _i in 10:
		eq(Algorithms.can_put(board, PieceDB.all(), rng).id, "dot_0", "only dot fits a single hole")
	var b2 := Board.new()
	fill_row(b2, 0, 0)
	for _i in 10:
		var p := Algorithms.clear(b2, PieceDB.all(), rng)
		check(p.size >= 1 and PlacementValidator.can_place_anywhere(b2, p), "clear piece valid")
		check(Algorithms.stats(b2, p).max_lines >= 1, "clear piece clears")

func test_algo_score_prefers_clearing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var b := Board.new()
	fill_row(b, 0, 0)
	var cands := [piece("dot_0"), piece("o_0")]
	eq(Algorithms.score(b, cands, rng).id, "dot_0", "dot gives 1+10, o gives 4")

func test_algo_hole_and_avoid_clear() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var full1 := Board.new()
	fill_row(full1, 0, 0)
	full1.set_cell(5, 5, 1)
	check(Algorithms.avoid_clear_board(full1, [piece("dot_0")], rng).get("id", "") == "dot_0", "non-wiping piece allowed")
	var wipe := Board.new()
	fill_row(wipe, 0, 0)   # dot at (0,0) would wipe the board entirely
	check(Algorithms.avoid_clear_board(wipe, [piece("dot_0")], rng).is_empty(), "wiping piece avoided")
	var hb := Board.new()
	hb.set_cell(0, 1, 1)
	hb.set_cell(1, 0, 1)
	hb.set_cell(1, 2, 1)
	hb.set_cell(2, 1, 1)
	eq(Algorithms.hole_max_diff(hb, [piece("dot_0"), piece("o_0")], rng).get("id", ""), "dot_0", "dot fills the hole")

func test_new_clear_board() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var b := Board.new()
	fill_row(b, 0, 7)
	var p := Algorithms.new_clear_board(b, [piece("o_0"), piece("dot_0")], rng)
	eq(p.id, "dot_0", "dot wipes the board")

func test_entropy_and_deal_death() -> void:
	var same := [piece("o_0"), piece("o_0"), piece("o_0")]
	var mixed := [piece("o_0"), piece("dot_0"), piece("i3_0")]
	eq(Algorithms.family_entropy(same), 0.0, "zero entropy")
	check(absf(Algorithms.family_entropy(mixed) - 1.585) < 0.01, "max entropy for 3")
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	var tri := Algorithms.entropy3_medium(Board.new(), PieceDB.all(), rng)
	eq(tri.size(), 3, "entropy tray size")
	var b := Board.new()
	for i in 64:
		if i % 3 != 0: b.cells[i] = 1
	var p := Algorithms.deal_death_state(b, PieceDB.all(), rng)
	check(p.is_empty() or PlacementValidator.can_place_anywhere(b, p), "rescue piece fits")
	check(Algorithms.simple_death(b, [piece("o_0")]), "simple death on scattered holes")

func test_difficulty_manager() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 50:
		check(DifficultyManager.pick(rng, rng.randf(), rng.randf()) in Algorithms.NAMES, "picked known algo")
	eq(DifficultyManager.algorithm_weights(0.8, 0.5)["avoid_clear_board"], 0.0, "no avoid-clear under pressure")
	check(DifficultyManager.difficulty_for_score(0) < DifficultyManager.difficulty_for_score(5000), "difficulty ramps")

func test_evaluator() -> void:
	var b := Board.new()
	eq(BoardEvaluator.count_holes(b), 0, "no holes empty")
	b.set_cell(0, 1, 1)
	b.set_cell(1, 0, 1)
	b.set_cell(1, 2, 1)
	b.set_cell(2, 1, 1)
	eq(BoardEvaluator.count_holes(b), 2, "enclosed (1,1) plus walled corner (0,0)")
	var c := Board.new()
	c.set_cell(0, 0, 1)
	eq(BoardEvaluator.count_holes(c), 0, "single block makes no hole")
	eq(BoardEvaluator.near_complete_lines(c), 0, "no near lines")
	fill_row(c, 4, 0)
	check(BoardEvaluator.near_complete_lines(c) >= 1, "near-complete row")
