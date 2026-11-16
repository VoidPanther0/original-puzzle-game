class_name Algorithms
extends RefCounted
## Independently written piece-selection strategies. The names mirror the algorithm FAMILIES that
## were documented for the original game, but the behaviour below is our own interpretation: the
## original implementations are not known and are NOT reproduced.
##
## Per-piece selectors: select(name, board, candidates, rng) -> piece Dictionary ({} if none).

const NAMES := [
	"can_put", "clear", "score", "deal_death_state", "hole_max_diff", "avoid_clear_board",
	"new_clear_board", "random_no_die", "fill_sort", "fill_weight",
]

## --- statistics over all placements of one piece --------------------------------------------
static func stats(board: Board, piece: Dictionary) -> Dictionary:
	var count := 0
	var max_lines := 0
	var best_fit := 0
	var best_hole_delta := -999
	var min_hole_delta := 999
	var best_score := 0
	var clears_board := false
	var holes_before := BoardEvaluator.count_holes(board)
	for a in PlacementValidator.all_positions(board, piece):
		count += 1
		var b := board.copy()
		b.place(piece, a.y, a.x)
		var res := LineClearManager.resolve(b)
		max_lines = maxi(max_lines, res.lines)
		best_fit = maxi(best_fit, BoardEvaluator.fit_score(board, piece, a.y, a.x))
		var delta := holes_before - BoardEvaluator.count_holes(b)   # positive = fewer holes
		best_hole_delta = maxi(best_hole_delta, delta)
		min_hole_delta = mini(min_hole_delta, delta)
		best_score = maxi(best_score, piece.size + res.lines * 10)
		if b.is_empty(): clears_board = true
	return {"count": count, "max_lines": max_lines, "best_fit": best_fit,
		"hole_best": best_hole_delta, "hole_spread": best_hole_delta - min_hole_delta if count > 0 else 0,
		"best_score": best_score, "clears_board": clears_board}

static func _weighted(cands: Array, rng: RandomNumberGenerator, weights: Array = []) -> Dictionary:
	if cands.is_empty(): return {}
	var total := 0.0
	for i in cands.size():
		total += weights[i] if not weights.is_empty() else float(cands[i].weight)
	var roll := rng.randf() * total
	for i in cands.size():
		roll -= weights[i] if not weights.is_empty() else float(cands[i].weight)
		if roll <= 0.0: return cands[i]
	return cands[cands.size() - 1]

static func _fitting(board: Board, cands: Array) -> Array:
	var out: Array = []
	for p in cands:
		if PlacementValidator.can_place_anywhere(board, p): out.append(p)
	return out

## --- selectors -------------------------------------------------------------------------------
static func select(algo: String, board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	match algo:
		"can_put": return can_put(board, cands, rng)
		"clear": return clear(board, cands, rng)
		"score": return score(board, cands, rng)
		"deal_death_state": return deal_death_state(board, cands, rng)
		"hole_max_diff": return hole_max_diff(board, cands, rng)
		"avoid_clear_board": return avoid_clear_board(board, cands, rng)
		"new_clear_board": return new_clear_board(board, cands, rng)
		"random_no_die": return random_no_die(board, cands, rng)
		"fill_sort": return fill_sort(board, cands, rng)
		"fill_weight": return fill_weight(board, cands, rng)
	return _weighted(cands, rng)

## AlgoSelectCanPut: any piece that has at least one legal position.
static func can_put(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	return _weighted(_fitting(board, cands), rng)

## AlgoSelectClear: a piece able to complete lines (the most lines wins; ties random).
static func clear(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	var best: Array = []
	var best_l := 0
	for p in cands:
		var l: int = stats(board, p).max_lines
		if l > best_l:
			best_l = l
			best = [p]
		elif l == best_l and l > 0:
			best.append(p)
	return _weighted(best, rng)

## AlgoSelectScore: the piece with the highest achievable immediate score.
static func score(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	var best: Array = []
	var best_s := 0
	for p in cands:
		var s: int = stats(board, p).best_score
		if s > best_s:
			best_s = s
			best = [p]
		elif s == best_s and s > 0:
			best.append(p)
	return _weighted(best, rng)

## AlgoSelectBlockDealDeathState: when the board is nearly dead, deal the piece that has the most
## room; otherwise behave like can_put. Prevents unavoidable instant deaths.
static func deal_death_state(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	if BoardEvaluator.fill_ratio(board) < 0.55:
		return can_put(board, cands, rng)
	var best := {}
	var best_n := 0
	for p in cands:
		var n: int = stats(board, p).count
		if n > best_n:
			best_n = n
			best = p
	return best if not best.is_empty() else {}

## AlgoSelectHoleMaxDiff: the piece whose best placement reduces holes the most.
static func hole_max_diff(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	var best: Array = []
	var best_d := -999
	for p in cands:
		var st := stats(board, p)
		if st.count == 0: continue
		if st.hole_best > best_d:
			best_d = st.hole_best
			best = [p]
		elif st.hole_best == best_d:
			best.append(p)
	return _weighted(best, rng)

## AlgoSelectBlockAvoidClearBoard: avoid pieces that would wipe the board (keeps tension).
static func avoid_clear_board(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	var ok: Array = []
	for p in cands:
		var st := stats(board, p)
		if st.count > 0 and not st.clears_board: ok.append(p)
	return _weighted(ok, rng)

## AlgoSelectBlockNewClearBoard: prefer a piece that could wipe the board, else the one that
## clears the most lines (used to reward a nearly clean board).
static func new_clear_board(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	for p in cands:
		if stats(board, p).clears_board: return p
	return clear(board, cands, rng)

## AlgoSelectRandomNoDie: weighted random, guaranteed to be placeable when anything is.
static func random_no_die(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	var fit := _fitting(board, cands)
	return _weighted(fit if not fit.is_empty() else cands, rng)

## AlgoSelectFillSort: sort by snugness of best placement, pick from the top few.
static func fill_sort(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	var scored: Array = []
	for p in cands:
		var st := stats(board, p)
		if st.count > 0: scored.append([st.best_fit, p])
	if scored.is_empty(): return {}
	scored.sort_custom(func(a, b): return a[0] > b[0])
	return scored[rng.randi_range(0, mini(2, scored.size() - 1))][1]

## AlgoSelectFillWeight: random with probability proportional to snugness x base weight.
static func fill_weight(board: Board, cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	var list: Array = []
	var ws: Array = []
	for p in cands:
		var st := stats(board, p)
		if st.count > 0:
			list.append(p)
			ws.append((1.0 + st.best_fit) * float(p.weight))
	return _weighted(list, rng, ws)

## --- tray-level --------------------------------------------------------------------------------
## Shannon entropy (bits) of piece-family distribution in a set of pieces.
static func family_entropy(pieces: Array) -> float:
	var counts := {}
	for p in pieces: counts[p.family] = counts.get(p.family, 0) + 1
	var h := 0.0
	for k in counts:
		var pr := float(counts[k]) / pieces.size()
		h -= pr * log(pr) / log(2.0)
	return h

## AlgoSelectBlockEntropy3Medium: among sampled triples choose the one whose family entropy is
## closest to "medium" (two shapes alike, one different = 0.918 bits for 3 pieces).
static func entropy3_medium(board: Board, cands: Array, rng: RandomNumberGenerator, target: float = 0.918, samples: int = 12) -> Array:
	var best: Array = []
	var best_d := INF
	for _i in samples:
		var tri: Array = []
		for _j in 3: tri.append(random_no_die(board, cands, rng))
		var d := absf(family_entropy(tri) - target)
		if d < best_d:
			best_d = d
			best = tri
	return best

## AlgoSelectSimpleDeath: the simple death test (true when no piece can be placed).
static func simple_death(board: Board, pieces: Array) -> bool:
	return DeathDetector.is_dead(board, pieces)
