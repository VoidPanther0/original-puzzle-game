class_name BoardEvaluator
extends RefCounted
## Board heuristics used by generation algorithms and the solver.

static func fill_ratio(board: Board) -> float:
	return float(board.occupied_count()) / float(Board.CELLS)

## A "hole" is an empty cell whose four neighbours are all occupied or outside the board.
static func count_holes(board: Board) -> int:
	var holes := 0
	for r in Board.SIZE:
		for c in Board.SIZE:
			if board.is_occupied(r, c): continue
			var enclosed := true
			for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				var rr: int = r + d.y
				var cc: int = c + d.x
				if Board.in_bounds(rr, cc) and not board.is_occupied(rr, cc):
					enclosed = false
					break
			if enclosed: holes += 1
	return holes

## Number of occupied/empty transitions along rows and columns (lower = smoother).
static func roughness(board: Board) -> int:
	var t := 0
	for r in Board.SIZE:
		for c in Board.SIZE - 1:
			if board.is_occupied(r, c) != board.is_occupied(r, c + 1): t += 1
	for c in Board.SIZE:
		for r in Board.SIZE - 1:
			if board.is_occupied(r, c) != board.is_occupied(r + 1, c): t += 1
	return t

## Lines that are one or two cells short of complete.
static func near_complete_lines(board: Board, missing_max: int = 2) -> int:
	var n := 0
	for r in Board.SIZE:
		var filled := 0
		for c in Board.SIZE:
			if board.is_occupied(r, c): filled += 1
		if filled < Board.SIZE and Board.SIZE - filled <= missing_max: n += 1
	for c in Board.SIZE:
		var filled := 0
		for r in Board.SIZE:
			if board.is_occupied(r, c): filled += 1
		if filled < Board.SIZE and Board.SIZE - filled <= missing_max: n += 1
	return n

## Number of occupied/wall neighbours around the cells of a placed piece (how snugly it fits).
static func fit_score(board: Board, piece: Dictionary, row: int, col: int) -> int:
	var own := {}
	for p in piece.cells:
		own[Vector2i(col + p.x, row + p.y)] = true
	var s := 0
	for p in piece.cells:
		var x: int = col + p.x
		var y: int = row + p.y
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var nx: int = x + d.x
			var ny: int = y + d.y
			if own.has(Vector2i(nx, ny)): continue
			if not Board.in_bounds(ny, nx) or board.is_occupied(ny, nx): s += 1
	return s

## Single danger number: higher = worse board.
static func danger(board: Board) -> float:
	return fill_ratio(board) * 100.0 + count_holes(board) * 6.0 + roughness(board) * 0.5
